import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sanyan_common_ui/sanyan_common_ui.dart';
import 'chat_controller.dart';
import 'widget/chat_input_bar.dart';
import 'widget/message_bubble.dart';
import 'widget/typing_indicator.dart';

class ChatPage extends StatelessWidget {
  ChatPage({super.key});

  final c = Get.put(ChatController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuraColors.surface,
      appBar: AppBar(
        title: const Text(
          '小婉',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AuraColors.primary,
          ),
        ),
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: AuraColors.glassBlur, sigmaY: AuraColors.glassBlur),
            child: Container(color: AuraColors.surface.withValues(alpha: 0.6)),
          ),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: Color(0xFFD4FBFB)),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: Obx(() {
                if (c.isLoading.value && c.messages.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(color: AuraColors.primary),
                  );
                }
                final showTyping = c.isAiTyping.value;
                final itemCount = c.messages.length + (showTyping ? 1 : 0);
                return ListView.builder(
                  controller: c.scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  itemCount: itemCount,
                  itemBuilder: (context, index) {
                    if (showTyping && index == c.messages.length) {
                      return const TypingIndicator();
                    }
                    return MessageBubble(
                      message: c.messages[index],
                      onRetry: () => c.retryMessage(c.messages[index]),
                    );
                  },
                );
              }),
            ),
            ChatInputBar(controller: c.inputController, onSend: c.sendMessage),
          ],
        ),
      ),
    );
  }
}
