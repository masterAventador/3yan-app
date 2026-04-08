import 'dart:async';
import 'package:get/get.dart';
import 'package:sanyan_network/sanyan_network.dart';
import '../api/chat_api.dart';
import '../models/conversation.dart';

class HomeController extends GetxController {
  final conversations = <Conversation>[].obs;
  final isLoading = true.obs;
  StreamSubscription? _wsSubscription;

  /// 当前正在查看的会话 ID，在聊天页时设置，返回时清空
  int? activeConversationId;

  @override
  void onInit() {
    super.onInit();
    loadConversations();
    _listenWsEvents();
  }

  Future<void> loadConversations() async {
    try {
      final resp = await ConversationApi.list();
      if (resp.success && resp.data != null) {
        conversations.value = resp.data!;
      }
    } finally {
      isLoading.value = false;
    }
  }

  /// 进入聊天页时调用
  void enterChat(int conversationId) {
    activeConversationId = conversationId;
    // 立即将本地未读数清零
    final idx = conversations.indexWhere((c) => c.id == conversationId);
    if (idx != -1) {
      final c = conversations[idx];
      conversations[idx] = Conversation(
        id: c.id,
        characterId: c.characterId,
        characterName: c.characterName,
        characterAvatar: c.characterAvatar,
        lastMessage: c.lastMessage,
        lastMessageAt: c.lastMessageAt,
        unreadCount: 0,
      );
    }
  }

  /// 退出聊天页时调用
  void leaveChat() {
    activeConversationId = null;
    loadConversations();
  }

  void _listenWsEvents() {
    final wsClient = Get.find<WsClient>();
    _wsSubscription = wsClient.eventStream.listen((event) {
      if (event.type == 'new_message') {
        final msgConvId = event.conversationId;
        // 如果用户正在看这个会话，只更新最后一条消息，不增加未读
        if (msgConvId != null && msgConvId == activeConversationId) {
          final content = event.message?['content'] as String?;
          if (content != null) {
            final idx = conversations.indexWhere((c) => c.id == msgConvId);
            if (idx != -1) {
              final c = conversations[idx];
              conversations[idx] = Conversation(
                id: c.id,
                characterId: c.characterId,
                characterName: c.characterName,
                characterAvatar: c.characterAvatar,
                lastMessage: content,
                lastMessageAt: DateTime.now().toIso8601String(),
                unreadCount: 0,
              );
            }
          }
        } else {
          loadConversations();
        }
      }
    });
  }

  @override
  void onClose() {
    _wsSubscription?.cancel();
    super.onClose();
  }
}
