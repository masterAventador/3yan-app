import 'package:flutter/material.dart';
import 'package:sanyan_common_ui/sanyan_common_ui.dart';
import '../../api/models/message_status.dart';
import 'package:sanyan_util/sanyan_util.dart';

/// 头像直径（同时是气泡最小高度，让短消息气泡跟头像齐平不缩水）。
const double kAvatarSize = 40;

/// 头像与气泡之间的横向 gap。
const double _avatarGap = 10;

/// User 消息左侧的 status indicator slot 宽度（sending=loading / failed=红叹号 / sent=透明占位）。
/// 固定占位保证 status 切换时气泡 layout 不抖动。
const double _indicatorSlotSize = 24;
const double _indicatorGap = 6;

/// 各类型消息气泡的公共骨架：负责头像、气泡边框、status indicator slot、时间戳占位。
/// 各消息类型（文本 / 图片 / typing 三个点）只需要提供 [child] 作为气泡内部内容。
///
/// 布局规则：
///
/// ```
/// AI 消息（isUser=false，不渲染 indicator slot）：
///   [avatar][gap][bubble(min height kAvatarSize)]
///                                                  ↑ bubble maxWidth 留对面 avatar 位置
///
/// User 消息（isUser=true，左侧固定 24px indicator slot）：
///   [indicator_slot(24)][gap][bubble][gap][avatar]
///        |                ↑ slot 占用本来给"对面 avatar"留的空白，bubble 宽度不变
///        ├─ status=sending: CircularProgressIndicator
///        ├─ status=failed:  红叹号（IconButton onPressed=onRetry）
///        └─ status=sent/null: SizedBox(透明占位)
/// ```
///
/// [createdAt] 为 null 时（typing 占位场景），时间戳渲染为透明 placeholder 保持高度一致，
/// typing → 真实消息切换时整体高度不跳。
class MessageBubbleShell extends StatelessWidget {
  final Widget child;
  final bool isUser;
  final MessageStatus? status;
  final String? createdAt;
  final VoidCallback? onRetry;

  const MessageBubbleShell({
    super.key,
    required this.child,
    required this.isUser,
    this.status,
    this.createdAt,
    this.onRetry,
  });

  /// 气泡最大宽度：屏宽减页面 padding（两侧）+ 头像（两侧）+ 头像 gap（两侧）。
  /// 两侧都减是为了让长消息不顶到对面 avatar 区——user 消息左侧的空白本来就有，
  /// 现在用 indicator slot 把它利用上但不改变 bubble 自身宽度。
  double _maxBubbleWidth(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return w - AuraSpacing.pagePadding * 2 - (kAvatarSize + _avatarGap) * 2;
  }

  Widget _buildAvatar() {
    return Container(
      width: kAvatarSize,
      height: kAvatarSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: isUser
              ? const [Color(0xFF9F7AEA), Color(0xFFCD7BE5)]
              : const [Color(0xFFA8E6CF), Color(0xFF7CCFC6)],
        ),
      ),
      child: Icon(isUser ? Icons.person : Icons.favorite, color: Colors.white, size: 20),
    );
  }

  /// 只返回 indicator icon 本身，不带尺寸/对齐 wrapper——外层用 Stack+Positioned
  /// 把 slot 撑到跟 bubble 同高，再 Center 落到 bubble 中线，从而既不依赖
  /// IntrinsicHeight（避免跟 ConstrainedBox.maxWidth intrinsic 行为冲突导致裁切
  /// 长消息），又让 indicator 跟 bubble 中线对齐而非跟 avatar 顶部绑死。
  Widget _buildIndicatorContent() {
    switch (status) {
      case MessageStatus.sending:
        return const SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(strokeWidth: 2, color: AuraColors.primary),
        );
      case MessageStatus.failed:
        // IconButton 缩到 icon 实际大小（18x18），让外层 Align(centerRight) 能真把它
        // 贴到 slot 右边——之前 constraints 用 _indicatorSlotSize=24 让 IconButton 占满
        // slot 宽，Align 怎么对都没视觉差。点击区域也 18x18，status indicator 低频点击可接受。
        return IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
          icon: const Icon(Icons.error, color: Colors.red, size: 18),
          onPressed: onRetry,
        );
      case MessageStatus.sent:
      case null:
        return const SizedBox.shrink();
    }
  }

  Widget _buildBubble(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: _maxBubbleWidth(context),
        minHeight: kAvatarSize,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: isUser ? AuraColors.primary : Colors.white.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(5),
        ),
        // 宽度收缩到 child（widthFactor=1.0），高度填满 minHeight 让短消息垂直居中。
        // 不能在 Container 上设 alignment——那会让 Container 撑到 maxWidth。
        child: Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          widthFactor: 1.0,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _buildTimestamp() {
    // createdAt 为 null（typing 场景）时透明占位，保持整体高度与有时间戳的真实消息一致。
    final text = createdAt == null ? '00:00' : DateUtil.formatHHmm(createdAt!);
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        color: createdAt == null ? Colors.transparent : Colors.grey,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final avatar = _buildAvatar();
    final bubble = _buildBubble(context);

    final Widget row;
    if (isUser) {
      // 嵌套布局：
      //   外层 Row（end 对齐，撑到屏宽，让整组靠右）：[ indicatorBubbleGroup, gap, avatar ]
      //   indicatorBubbleGroup = Stack：
      //     - 内层 Row(mainAxisSize.min)：[ SizedBox(24 占位), gap 6, bubble ]
      //       紧凑排列——Stack 大小 = 内层 Row 大小，bubble 紧贴 indicator slot 右边
      //     - Positioned indicator slot 在 Stack 左侧 0-24 区，撑满高度，Align centerRight
      //       让 icon 贴右紧靠 bubble，间距只剩 indicatorGap=6
      //   bubble 高度自然由文本决定（无 IntrinsicHeight 干扰，长消息不会被裁），
      //   indicator slot 在 Stack 内 Positioned 撑满 = bubble 同高，icon Center 落到 bubble 中线
      row = Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child: Stack(
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(width: _indicatorSlotSize),
                    const SizedBox(width: _indicatorGap),
                    Flexible(child: bubble),
                  ],
                ),
                PositionedDirectional(
                  start: 0,
                  top: 0,
                  bottom: 0,
                  child: SizedBox(
                    width: _indicatorSlotSize,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: _buildIndicatorContent(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: _avatarGap),
          avatar,
        ],
      );
    } else {
      row = Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          avatar,
          const SizedBox(width: _avatarGap),
          Flexible(child: bubble),
        ],
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AuraSpacing.pagePadding, vertical: 3),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          row,
          const SizedBox(height: 4),
          // 时间戳缩进对齐气泡（避开 avatar 列）
          Padding(
            padding: EdgeInsets.symmetric(horizontal: kAvatarSize + _avatarGap),
            child: _buildTimestamp(),
          ),
        ],
      ),
    );
  }
}
