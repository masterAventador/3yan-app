import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sanyan_network/sanyan_network.dart';
import 'package:sanyan_user/sanyan_user.dart';
import 'package:uuid/uuid.dart';
import '../api/chat_api.dart';
import '../home/conversation_list_controller.dart';
import '../api/models/conversation.dart';
import '../api/models/message.dart';
import '../api/models/message_status.dart';
import '../voice/voice_recorder.dart';
import 'widget/chat_input_mode.dart';

class ChatController extends GetxController {
  final Conversation conversation;
  final IVoiceRecorder recorder;
  late final Rx<ChatInputMode> inputMode;

  ChatController(this.conversation, {IVoiceRecorder? recorder})
      : recorder = recorder ?? VoiceRecorder() {
    inputMode = ChatInputMode.fromStorage(LocalStorage.lastInputMode).obs;
  }

  final messages = <Message>[].obs;
  final isLoading = true.obs;
  final isAiTyping = false.obs;
  final inputController = TextEditingController();
  final scrollController = ScrollController();
  StreamSubscription? _wsSubscription;
  StreamSubscription<PendingEntry>? _senderSub;

  final isRecording = false.obs;
  final isCancelling = false.obs;
  Offset? _recordStartPosition;

  /// 滑动取消阈值：手指上滑超过此像素数视为取消录音。
  static const double _cancelSwipeThreshold = 80.0;

  /// 回调：需要弹提示给用户（UI 层通过 registerToastHandler 注入）。
  void Function(String message)? _toastHandler;

  static const _uuid = Uuid();

  @override
  void onInit() {
    super.onInit();
    _loadHistory();
    _listenWs();
    _listenSender();
    ChatApi.markRead(conversation.id);
    // 通知首页：正在查看这个会话（延迟到 build 完成后执行，避免在 build 阶段触发 Obx 重建）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.isRegistered<ConversationListController>()) {
        Get.find<ConversationListController>().enterChat(conversation.id);
      }
    });

  }

  Future<void> _loadHistory() async {
    try {
      final resp = await ChatApi.listMessages(conversation.id);
      if (resp.success && resp.data != null) {
        messages.value = resp.data!;
      }
    } finally {
      _mergePendingFromSender();
      isLoading.value = false;
      _scrollToBottom();
    }
  }

  /// 把 MessageSender 里当前会话的 pending 条目（sending / failed）
  /// merge 到 messages 列表末尾——跨聊天页生命周期保持消息可见。
  void _mergePendingFromSender() {
    final pending = Get.find<MessageSender>().getPending(conversation.id);
    for (final entry in pending) {
      final msg = Message.fromJson(entry.messageJson);
      // 历史接口返回的消息如果已经包含同 clientMsgId（不该发生，但防御），跳过
      if (msg.clientMsgId != null &&
          messages.any((m) => m.clientMsgId == msg.clientMsgId)) {
        continue;
      }
      messages.add(msg);
    }
  }

  void _listenWs() {
    final wsClient = Get.find<WsClient>();
    _wsSubscription = wsClient.eventStream.listen((event) {
      if (event.conversationId != conversation.id) return;

      switch (event.type) {
        case WsEventType.typing:
          isAiTyping.value = true;
          _scrollToBottom();
          break;
        case WsEventType.newMessage:
          isAiTyping.value = false;
          if (event.message != null) {
            final msg = Message.fromJson(event.message!);
            messages.add(msg);
            _scrollToBottom();
            ChatApi.markRead(conversation.id);
          }
          break;
        // ACK 由 MessageSender 处理，ChatController 通过 statusChanges 订阅
        // 获得状态更新，不再自己处理 ack 事件。
      }
    });
  }

  void _listenSender() {
    _senderSub =
        Get.find<MessageSender>().statusChanges.listen(_onSenderStatusChange);
  }

  void _onSenderStatusChange(PendingEntry entry) {
    if (entry.conversationId != conversation.id) return;
    final idx = messages.indexWhere((m) => m.clientMsgId == entry.clientMsgId);
    if (idx == -1) return; // 不在当前列表里（冷启后未 merge 等极端情况），忽略
    final newStatus = _parseWireStatus(entry.messageJson['status'] as String?);
    messages[idx].status = newStatus;
    messages.refresh();
  }

  MessageStatus? _parseWireStatus(String? raw) {
    if (raw == null) return null;
    for (final s in MessageStatus.values) {
      if (s.name == raw) return s;
    }
    return null;
  }

  void toggleInputMode() {
    inputMode.value = inputMode.value == ChatInputMode.keyboard
        ? ChatInputMode.voice
        : ChatInputMode.keyboard;
    LocalStorage.lastInputMode = inputMode.value.storageValue;
  }

  void registerToastHandler(void Function(String) handler) {
    _toastHandler = handler;
  }

  void _showToast(String msg) => _toastHandler?.call(msg);

  /// 进聊天页后台跑一次 start+cancel，触发 iOS AAC codec 首次初始化。
  /// 之后 codec 被缓存，真正按住说话的启动时间能从 ~1s 降到百毫秒。
  /// 只在已有权限时预热，避免静默触发系统权限弹窗。
  Future<void> warmupRecorder() async {
    if (!await recorder.isPermissionGranted()) return;
    final started = await recorder.start();
    if (started) {
      await recorder.cancel();
    }
  }

  Future<void> onRecordStart(Offset globalPosition) async {
    // 权限已授予 → 直接开始录音。
    // 权限未授予 → 弹系统弹窗询问，弹窗会打断长按手势，此时不应该继续开始录音
    //             （否则用户手指早已离开按钮，录音会卡死），而是提示用户再次按住。
    if (!await recorder.isPermissionGranted()) {
      final granted = await recorder.requestPermission();
      _showToast(granted ? '麦克风权限已获取，请再次按住说话' : '需要麦克风权限才能发送语音');
      return;
    }
    final started = await recorder.start(onMaxDurationReached: () {
      if (isRecording.value) onRecordEnd();
    });
    if (!started) {
      _showToast('录音启动失败');
      return;
    }
    isRecording.value = true;
    isCancelling.value = false;
    _recordStartPosition = globalPosition;
  }

  void onRecordMove(Offset globalPosition) {
    if (!isRecording.value || _recordStartPosition == null) return;
    final dy = _recordStartPosition!.dy - globalPosition.dy;
    final cancelling = dy > _cancelSwipeThreshold;
    if (cancelling != isCancelling.value) {
      isCancelling.value = cancelling;
    }
  }

  Future<void> onRecordEnd() async {
    if (!isRecording.value) return;
    final cancelling = isCancelling.value;
    isRecording.value = false;
    isCancelling.value = false;
    _recordStartPosition = null;

    if (cancelling) {
      await recorder.cancel();
      return;
    }
    final result = await recorder.stop();
    if (result == null) {
      _showToast('说话时间太短');
      return;
    }
    sendVoiceMessage(result.filePath, result.durationSeconds);
  }

  Future<void> onRecordCancel() async {
    if (!isRecording.value) return;
    isRecording.value = false;
    isCancelling.value = false;
    _recordStartPosition = null;
    await recorder.cancel();
  }

  void sendMessage() {
    final text = inputController.text.trim();
    if (text.isEmpty) return;

    final clientMsgId = _uuid.v4();
    final msg = Message(
      id: 0,
      conversationId: conversation.id,
      senderType: SenderType.user,
      contentType: ContentType.text,
      content: text,
      source: 'reply',
      createdAt: DateTime.now().toString(),
      clientMsgId: clientMsgId,
      // 关键：标 sending（之前一直 null，导致 UI 从不展示发送中/失败态）。
      status: MessageStatus.sending,
    );
    messages.add(msg);
    _scrollToBottom();

    // 发送交给 MessageSender —— pending 追踪 / 超时 / 断线 / 持久化 由它兜底。
    Get.find<MessageSender>().sendText(
      conversationId: conversation.id,
      clientMsgId: clientMsgId,
      messageJson: msg.toJson(),
    );

    inputController.clear();
  }

  /// Send voice message with optimistic UI + concurrent upload
  Future<void> sendVoiceMessage(String localPath, int duration) async {
    final clientMsgId = _uuid.v4();

    final msg = Message(
      id: 0,
      conversationId: conversation.id,
      senderType: SenderType.user,
      contentType: ContentType.voice,
      content: '',
      mediaUrl: null,
      duration: duration,
      source: 'reply',
      createdAt: DateTime.now().toString(),
      clientMsgId: clientMsgId,
      status: MessageStatus.sending,
      localFilePath: localPath,
    );
    messages.add(msg);
    _scrollToBottom();

    // Independent Future, no await — concurrent upload
    _uploadAndSendVoice(msg);
  }

  /// 重试一条失败的消息。把 Message 转回 PendingEntry 交给 MessageSender.retry，
  /// Sender 会按 contentType 分派到 WsClient 对应 send 方法，重置 sendTimeMs，
  /// 广播 statusChanges → ChatController 收到事件把 msg.status 切回 sending。
  ///
  /// 当前实现里这里先把 msg.status 置 sending 并 refresh UI——为了即时反馈，
  /// 不等 statusChanges 事件回来。
  void retryMessage(Message msg) {
    if (msg.status != MessageStatus.failed) return;
    final clientMsgId = msg.clientMsgId;
    if (clientMsgId == null) return;

    msg.status = MessageStatus.sending;
    messages.refresh();

    final entry = PendingEntry(
      clientMsgId: clientMsgId,
      conversationId: msg.conversationId,
      sendTimeMs: DateTime.now().millisecondsSinceEpoch,
      messageJson: msg.toJson(),
    );
    Get.find<MessageSender>().retry(entry);
  }

  Future<void> _uploadAndSendVoice(Message msg) async {
    try {
      final uploadResp = await ChatApi.uploadVoice(
        msg.localFilePath!,
        duration: msg.duration ?? 0,
      );
      if (!uploadResp.success || uploadResp.data == null) {
        _markFailed(msg);
        return;
      }
      // HTTP 上传成功但还没发给对端——status 保持 sending，
      // 交给 MessageSender 跟踪 ACK，偶发 ACK 丢失由 30s 超时兜住。
      msg.mediaUrl = uploadResp.data!.url;
      messages.refresh();
      Get.find<MessageSender>().sendVoice(
        conversationId: conversation.id,
        clientMsgId: msg.clientMsgId!,
        mediaUrl: uploadResp.data!.url,
        duration: uploadResp.data!.duration,
        messageJson: msg.toJson(),
      );
    } catch (e, stack) {
      debugPrint('[ChatController] _uploadAndSendVoice failed: $e\n$stack');
      _markFailed(msg);
    }
  }

  void _markFailed(Message msg) {
    msg.status = MessageStatus.failed;
    messages.refresh();
  }

  void _scrollToBottom() {
    // 用 addPostFrameCallback 等到新消息完成 layout 后再滚，
    // 否则 maxScrollExtent 还是旧值，新气泡会被输入框挡住。
    // 用 jumpTo 瞬间滚到底，避免 animateTo 过程中新 item 渐进入场引起视觉跳变。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.jumpTo(scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  void onClose() {
    _wsSubscription?.cancel();
    _senderSub?.cancel();
    inputController.dispose();
    scrollController.dispose();
    recorder.dispose();
    // 通知首页：离开聊天页，刷新列表
    if (Get.isRegistered<ConversationListController>()) {
      Get.find<ConversationListController>().leaveChat();
    }
    super.onClose();
  }
}
