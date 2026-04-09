import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sanyan_common_ui/sanyan_common_ui.dart';
import '../models/conversation.dart';
import 'chat_controller.dart';
import 'widget/chat_input_bar.dart';
import 'widget/message_bubble.dart';

class ChatPage extends StatelessWidget {
  ChatPage({super.key});

  final Conversation conversation = Get.arguments as Conversation;
  late final ChatController c = Get.put(ChatController(conversation));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(conversation.characterName ?? ''),
            Obx(() => c.isAiTyping.value
                ? const Text(
                    '正在输入...',
                    style: TextStyle(fontSize: 12, color: AuraColors.textSecondary),
                  )
                : const SizedBox.shrink()),
          ],
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Icon(Icons.more_horiz, size: 24, color: AuraColors.textSecondary),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Messages
            Expanded(
              child: Obx(() {
                if (c.isLoading.value && c.messages.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(color: AuraColors.brandButton),
                  );
                }
                return ListView.builder(
                  controller: c.scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  itemCount: c.messages.length,
                  itemBuilder: (context, index) => MessageBubble(message: c.messages[index]),
                );
              }),
            ),

            // Input
            ChatInputBar(
              controller: c.inputController,
              onSend: c.sendMessage,
            ),
          ],
        ),
      ),
    );
  }
}
