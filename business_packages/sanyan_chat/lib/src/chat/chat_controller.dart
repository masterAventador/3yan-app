import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sanyan_network/sanyan_network.dart';
import '../api/chat_api.dart';
import '../home/home_controller.dart';
import '../models/conversation.dart';
import '../models/message.dart';

class ChatController extends GetxController {
  final Conversation conversation;
  ChatController(this.conversation);

  final messages = <Message>[].obs;
  final isLoading = true.obs;
  final isAiTyping = false.obs;
  final inputController = TextEditingController();
  final scrollController = ScrollController();
  StreamSubscription? _wsSubscription;

  @override
  void onInit() {
    super.onInit();
    _loadHistory();
    _listenWs();
    ConversationApi.markRead(conversation.id);
    // 通知首页：正在查看这个会话（延迟到 build 完成后执行，避免在 build 阶段触发 Obx 重建）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.isRegistered<HomeController>()) {
        Get.find<HomeController>().enterChat(conversation.id);
      }
    });

  }

  Future<void> _loadHistory() async {
    try {
      final resp = await ConversationApi.messages(conversation.id);
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
        case 'typing':
          isAiTyping.value = true;
          _scrollToBottom();
          break;
        case 'new_message':
          isAiTyping.value = false;
          if (event.message != null) {
            final msg = Message.fromJson(event.message!);
            messages.add(msg);
            _scrollToBottom();
            ConversationApi.markRead(conversation.id);
          }
          break;
        case 'ack':
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
    if (Get.isRegistered<HomeController>()) {
      Get.find<HomeController>().leaveChat();
    }
    super.onClose();
  }
}
