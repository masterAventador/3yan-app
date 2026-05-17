import 'package:flutter/material.dart';

/// 显示阶段切换剧情演出弹窗。
///
/// [storyMessage] 后端拼好的文案（如 "她半夜悄悄想你……"）
/// [fromStage] / [toStage]：阶段序号，用于埋点或后续扩展（如目前不显式展示）
/// 点击遮罩 / 卡片关闭。
Future<void> showStageTransitionDialog(
  BuildContext context, {
  required int fromStage,
  required int toStage,
  required String storyMessage,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withOpacity(0.6),
    builder: (dialogContext) => GestureDetector(
      onTap: () => Navigator.of(dialogContext).pop(),
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: AnimatedScale(
          scale: 1.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutBack,
          child: Container(
            padding: const EdgeInsets.all(24),
            margin: const EdgeInsets.symmetric(horizontal: 32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.favorite, color: Color(0xFFFF8FB7), size: 48),
                const SizedBox(height: 16),
                Text(
                  storyMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, height: 1.5),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
