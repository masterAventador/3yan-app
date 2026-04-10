import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:sanyan_common_ui/sanyan_common_ui.dart';
import 'chat_input_mode.dart';
import 'hold_to_speak_button.dart';

class ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final ChatInputMode mode;
  final VoidCallback onToggleMode;
  final VoidCallback onSendText;
  final bool isRecording;
  final void Function(Offset) onRecordStart;
  final void Function(Offset) onRecordMove;
  final VoidCallback onRecordEnd;
  final VoidCallback onRecordCancel;

  const ChatInputBar({
    super.key,
    required this.controller,
    required this.mode,
    required this.onToggleMode,
    required this.onSendText,
    required this.isRecording,
    required this.onRecordStart,
    required this.onRecordMove,
    required this.onRecordEnd,
    required this.onRecordCancel,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: AuraColors.glassBlur,
          sigmaY: AuraColors.glassBlur,
        ),
        child: Container(
          color: AuraColors.surface.withValues(alpha: 0.8),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Row(
                children: [
                  // Left: mode toggle button
                  IconButton(
                    onPressed: onToggleMode,
                    icon: Icon(
                      mode == ChatInputMode.keyboard
                          ? Icons.mic
                          : Icons.keyboard,
                    ),
                    color: AuraColors.primary,
                    iconSize: 26,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  ),
                  const SizedBox(width: 8),

                  // Middle: text field or hold-to-speak button
                  Expanded(
                    child: mode == ChatInputMode.keyboard
                        ? _buildTextField()
                        : HoldToSpeakButton(
                            isPressed: isRecording,
                            onPressStart: onRecordStart,
                            onPressMove: onRecordMove,
                            onPressEnd: onRecordEnd,
                            onPressCancel: onRecordCancel,
                          ),
                  ),
                  const SizedBox(width: 8),

                  // Emoji icon
                  Icon(
                    Icons.sentiment_satisfied_outlined,
                    size: 22,
                    color: AuraColors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),

                  // Plus button
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.add_circle_outline),
                    color: AuraColors.primary,
                    iconSize: 26,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AuraColors.outlineVariant.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AuraColors.onSurface.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        style: TextStyle(
          fontFamily: AuraFonts.manrope,
          fontSize: 14,
          color: AuraColors.onSurface,
        ),
        decoration: InputDecoration(
          hintText: '输入消息...',
          hintStyle: TextStyle(
            fontFamily: AuraFonts.manrope,
            fontSize: 14,
            color: AuraColors.outlineVariant,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          isDense: true,
        ),
        textInputAction: TextInputAction.send,
        onSubmitted: (_) => onSendText(),
      ),
    );
  }
}
