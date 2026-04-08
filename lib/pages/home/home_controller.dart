import 'dart:async';
import 'package:get/get.dart';
import '../../api/conversation_api.dart';
import '../../core/network/ws_client.dart';
import '../../models/conversation.dart';

class HomeController extends GetxController {
  final conversations = <Conversation>[].obs;
  final isLoading = true.obs;
  StreamSubscription? _wsSubscription;

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

  void _listenWsEvents() {
    final wsClient = Get.find<WsClient>();
    _wsSubscription = wsClient.eventStream.listen((event) {
      if (event.type == 'new_message') {
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
