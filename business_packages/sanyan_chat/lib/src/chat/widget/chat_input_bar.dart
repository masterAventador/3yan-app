import 'package:flutter/material.dart';
import 'package:sanyan_common_ui/sanyan_common_ui.dart';

class ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  const ChatInputBar({super.key, required this.controller, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF0F0F0))),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Container(
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.inputFill,
                  borderRadius: BorderRadius.circular(21),
                ),
                child: TextField(
                  controller: controller,
                  style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    hintText: '说点什么...',
                    hintStyle: TextStyle(color: AppColors.textPlaceholder, fontSize: 15),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    isDense: true,
                  ),
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => onSend(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: onSend,
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.buttonGradient,
                ),
                child: const Icon(Icons.arrow_upward, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
