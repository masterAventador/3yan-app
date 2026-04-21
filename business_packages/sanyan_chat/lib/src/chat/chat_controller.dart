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
      isLoading.value = false;
      _scrollToBottom();
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
        case WsEventType.ack:
          _onAck(event.clientMsgId);
          break;
      }
    });
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

    final wsClient = Get.find<WsClient>();
    final clientMsgId = const Uuid().v4();
    wsClient.sendMessage(
      conversationId: conversation.id,
      content: text,
      clientMsgId: clientMsgId,
    );

    messages.add(Message(
      id: 0,
      conversationId: conversation.id,
      senderType: SenderType.user,
      contentType: ContentType.text,
      content: text,
      source: 'reply',
      createdAt: DateTime.now().toString(),
      clientMsgId: clientMsgId,
    ));

    inputController.clear();
    _scrollToBottom();
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

  /// 重试一条失败的消息（当前为空实现，T19 填充为调 MessageSender.retry）。
  void retryMessage(Message msg) {
    // TODO(T19): 接入 MessageSender.retry
  }

  /// Retry failed voice message
  Future<void> retryVoiceMessage(Message msg) async {
    if (msg.localFilePath == null) return;
    msg.status = MessageStatus.sending;
    messages.refresh();
    await _uploadAndSendVoice(msg);
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

      // 上传成功后立刻回写 mediaUrl + 标记为 sent，移除发送中 loading：
      // COS 已有文件说明上传链路完成，WebSocket 的 ACK 只是双重确认，
      // 等 ACK 会让 loading 一直不消失（ACK 偶发丢失时）。
      msg.mediaUrl = uploadResp.data!.url;
      msg.status = MessageStatus.sent;
      messages.refresh();

      final wsClient = Get.find<WsClient>();
      wsClient.sendVoiceMessage(
        conversationId: conversation.id,
        mediaUrl: uploadResp.data!.url,
        duration: uploadResp.data!.duration,
        clientMsgId: msg.clientMsgId!,
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

  void _onAck(String? clientMsgId) {
    if (clientMsgId == null) return;
    final idx = messages.indexWhere((m) => m.clientMsgId == clientMsgId);
    if (idx == -1) return;
    final msg = messages[idx];
    if (msg.status != MessageStatus.sending) return;

    msg.status = MessageStatus.sent;
    messages.refresh();

    // 不立刻删除 localFilePath，ACK 之后仍保留本地文件作为播放兜底
    // （即使 mediaUrl 暂时网络不通也能播自己的录音）。
    // 7 天过期由 VoiceCacheManager.cleanupOldFiles 定期清理。
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
