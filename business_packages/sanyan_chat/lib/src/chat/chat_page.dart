import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sanyan_common_ui/sanyan_common_ui.dart';
import '../api/models/conversation.dart';
import 'chat_controller.dart';
import 'widget/chat_input_bar.dart';
import 'widget/message_bubble.dart';
import 'widget/typing_indicator.dart';
import 'widget/voice_record_overlay.dart';

class ChatPage extends StatelessWidget {
  final Conversation conversation;
  const ChatPage({super.key, required this.conversation});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(ChatController(conversation));
    c.registerToastHandler((msg) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
      );
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => c.warmupRecorder());

    return Scaffold(
      backgroundColor: AuraColors.surface,
      appBar: AppBar(
        title: Text(
          conversation.characterName ?? '',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AuraColors.primary,
          ),
        ),
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: AuraColors.glassBlur,
              sigmaY: AuraColors.glassBlur,
            ),
            child: Container(color: AuraColors.surface.withValues(alpha: 0.6)),
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.search, color: AuraColors.primary),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.more_vert, color: AuraColors.primary),
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: Color(0xFFD4FBFB)),
        ),
      ),
      body: Stack(
        children: [
          SafeArea(
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
                        return MessageBubble(message: c.messages[index]);
                      },
                    );
                  }),
                ),
                Obx(() => ChatInputBar(
                      controller: c.inputController,
                      mode: c.inputMode.value,
                      onToggleMode: c.toggleInputMode,
                      onSendText: c.sendMessage,
                      isRecording: c.isRecording.value,
                      onRecordStart: c.onRecordStart,
                      onRecordMove: c.onRecordMove,
                      onRecordEnd: c.onRecordEnd,
                      onRecordCancel: c.onRecordCancel,
                    )),
              ],
            ),
          ),
          Obx(() => c.isRecording.value
              ? VoiceRecordOverlay(isCancelling: c.isCancelling.value)
              : const SizedBox.shrink()),
        ],
      ),
    );
  }
}
