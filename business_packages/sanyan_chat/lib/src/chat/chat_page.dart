import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
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
      backgroundColor: AuraColors.surface,
      body: Column(
        children: [
          _TopBar(conversation: conversation),
          const Divider(
            height: 1,
            thickness: 1,
            color: Color(0xFFD4FBFB),
          ),
          Expanded(
            child: Obx(() {
              if (c.isLoading.value && c.messages.isEmpty) {
                return const Center(
                  child: CircularProgressIndicator(color: AuraColors.primary),
                );
              }
              return ListView.builder(
                controller: c.scrollController,
                padding: const EdgeInsets.symmetric(vertical: 16),
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

// ─── Frosted glass top bar ────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final Conversation conversation;
  const _TopBar({required this.conversation});

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: AuraColors.glassBlur,
          sigmaY: AuraColors.glassBlur,
        ),
        child: Container(
          color: AuraColors.surface.withValues(alpha: 0.6),
          padding: EdgeInsets.only(
            top: topPadding + 8,
            bottom: 12,
            left: 4,
            right: 8,
          ),
          child: Row(
            children: [
              // Back arrow
              IconButton(
                onPressed: () => Get.back(),
                icon: const Icon(Icons.arrow_back, color: AuraColors.primary),
                iconSize: 24,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),

              // Avatar
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AuraColors.mintAzureGradient,
                  border: Border.all(
                    color: AuraColors.primaryFixed,
                    width: 2,
                  ),
                ),
                child: const Icon(Icons.favorite, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),

              // Name + online status
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      conversation.characterName ?? '',
                      style: GoogleFonts.manrope(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AuraColors.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF4CAF50),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'ONLINE',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            letterSpacing: 0.8,
                            color: AuraColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Search icon
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.search, color: AuraColors.primary),
                iconSize: 22,
                padding: const EdgeInsets.symmetric(horizontal: 6),
              ),

              // More icon
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.more_vert, color: AuraColors.primary),
                iconSize: 22,
                padding: const EdgeInsets.symmetric(horizontal: 6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
