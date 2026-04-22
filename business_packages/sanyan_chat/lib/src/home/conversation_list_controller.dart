import 'dart:async';
import 'package:get/get.dart';
import 'package:sanyan_network/sanyan_network.dart';
import '../api/chat_api.dart';
import '../api/models/conversation.dart';


class ConversationListController extends GetxController {
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
      final resp = await ChatApi.listConversations();
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
      if (event.type == WsEventType.newMessage) {
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
      } else if (event.type == WsEventType.syncResult) {
        // WS 连上 / 重连后服务端会推 sync_result（一次带回所有会话的新消息）。
        // sync_result 的 payload 里只有 messages 没有 conversation meta，
        // 这里把它当"WS 已就绪，可以重试 REST 了"的信号，触发一次会话列表重拉。
        // 典型场景：冷启无网时首次 loadConversations 失败，WS 连上后自动补齐。
        loadConversations();
      }
    });
  }

  @override
  void onClose() {
    _wsSubscription?.cancel();
    super.onClose();
  }
}
