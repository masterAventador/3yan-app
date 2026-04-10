import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sanyan_network/sanyan_network.dart';
import 'package:uuid/uuid.dart';
import '../api/chat_api.dart';
import '../home/conversation_list_controller.dart';
import '../models/conversation.dart';
import '../models/message.dart';
import '../models/message_status.dart';
import 'voice_cache_manager.dart';

class ChatController extends GetxController {
  final Conversation conversation;
  ChatController(this.conversation);

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

  void sendMessage() {
    final text = inputController.text.trim();
    if (text.isEmpty) return;

    final wsClient = Get.find<WsClient>();
    final clientMsgId = wsClient.sendMessage(conversation.id, text);

    messages.add(Message(
      id: 0,
      conversationId: conversation.id,
      senderType: 'user',
      contentType: 'text',
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
      senderType: 'user',
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

      final wsClient = Get.find<WsClient>();
      wsClient.sendVoiceMessage(
        conversationId: conversation.id,
        mediaUrl: uploadResp.data!.url,
        duration: uploadResp.data!.duration,
        clientMsgId: msg.clientMsgId,
      );
      // ACK will be handled in _listenWs → _onAck
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

    // Delete local file for voice messages
    if (msg.localFilePath != null) {
      VoiceCacheManager.deleteFile(msg.localFilePath!);
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void onClose() {
    _wsSubscription?.cancel();
    inputController.dispose();
    scrollController.dispose();
    // 通知首页：离开聊天页，刷新列表
    if (Get.isRegistered<ConversationListController>()) {
      Get.find<ConversationListController>().leaveChat();
    }
    super.onClose();
  }
}
