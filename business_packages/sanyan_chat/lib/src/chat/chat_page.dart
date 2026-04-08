import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sanyan_common_ui/sanyan_common_ui.dart';
import '../models/conversation.dart';
import 'chat_controller.dart';
import 'widget/chat_input_bar.dart';
import 'widget/message_bubble.dart';

class ChatPage extends StatelessWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    final conversation = Get.arguments as Conversation;
    final c = Get.put(ChatController(conversation));

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Nav bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                height: 52,
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Get.back(),
                      child: const Icon(Icons.chevron_left, size: 28, color: AppColors.textPrimary),
                    ),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            conversation.characterName ?? '',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Obx(() => c.isAiTyping.value
                              ? const Text(
                                  '正在输入...',
                                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                )
                              : const SizedBox.shrink()),
                        ],
                      ),
                    ),
                    const Icon(Icons.more_horiz, size: 24, color: AppColors.textSecondary),
                  ],
                ),
              ),
            ),

            // Messages
            Expanded(
              child: Obx(() {
                if (c.isLoading.value && c.messages.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.brandButton),
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
