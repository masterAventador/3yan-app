import 'package:flutter/material.dart';
import '../../api/models/relationship.dart';

/// 聊天页顶部亲密度进度条。
///
/// 左：阶段名（"陌生人" / "朋友" / "暧昧" / "恋人" / "老夫老妻"）
/// 右：score / next_threshold
/// 中：粉紫渐变进度填充（按 percentToNextStage 0-1）
/// 点击：[onTap] 回调（一般展开详情弹窗）
class IntimacyProgressBar extends StatelessWidget {
  final Relationship relationship;
  final VoidCallback? onTap;

  const IntimacyProgressBar({
    super.key,
    required this.relationship,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final percent = relationship.percentToNextStage.clamp(0.0, 1.0);
    final thresholdLabel = relationship.nextStageThreshold == 2147483647
        ? '∞' // Integer.MAX_VALUE 表示老夫老妻（封顶）
        : '${relationship.nextStageThreshold}';
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  relationship.currentStageName,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                ),
                Text(
                  '${relationship.intimacyScore} / $thresholdLabel',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Container(
                height: 6,
                color: Colors.black12,
                child: FractionallySizedBox(
                  widthFactor: percent,
                  alignment: Alignment.centerLeft,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFFF8FB7), Color(0xFFA374FF)],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
