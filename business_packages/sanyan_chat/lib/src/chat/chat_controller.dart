import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sanyan_network/sanyan_network.dart';
import 'package:sanyan_user/sanyan_user.dart';
import 'package:uuid/uuid.dart';
import '../api/chat_api.dart';
import '../home/conversation_list_controller.dart';
import '../models/conversation.dart';
import '../models/message.dart';
import '../models/message_status.dart';
import 'voice_recorder.dart';
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

  void sendMessage() {
    final text = inputController.text.trim();
    if (text.isEmpty) return;

    final wsClient = Get.find<WsClient>();
    final clientMsgId = wsClient.sendMessage(conversation.id, text);

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
        clientMsgId: msg.clientMsgId,
      );
    } catch (_) {
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
