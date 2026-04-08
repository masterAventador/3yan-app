import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/conversation.dart';
import 'chat_controller.dart';
import 'widgets/chat_input_bar.dart';
import 'widgets/message_bubble.dart';

class ChatPage extends StatelessWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    final conversation = Get.arguments as Conversation;
    final c = Get.put(ChatController(conversation));

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(conversation.characterName ?? ''),
            Obx(() => c.isAiTyping.value
                ? Text('正在输入...',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]))
                : const SizedBox.shrink()),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Obx(() {
              if (c.isLoading.value && c.messages.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              return ListView.builder(
                controller: c.scrollController,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: c.messages.length,
                itemBuilder: (context, index) =>
                    MessageBubble(message: c.messages[index]),
              );
            }),
          ),
          ChatInputBar(
            controller: c.inputController,
            onSend: c.sendMessage,
          ),
        ],
      ),
    );
  }
}
