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

  Widget _buildIndicatorSlot() {
    Widget content;
    switch (status) {
      case MessageStatus.sending:
        content = const SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(strokeWidth: 2, color: AuraColors.primary),
        );
        break;
      case MessageStatus.failed:
        content = IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: _indicatorSlotSize, minHeight: _indicatorSlotSize),
          icon: const Icon(Icons.error, color: Colors.red, size: 18),
          onPressed: onRetry,
        );
        break;
      case MessageStatus.sent:
      case null:
        content = const SizedBox.shrink();
        break;
    }
    return SizedBox(width: _indicatorSlotSize, height: _indicatorSlotSize, child: Center(child: content));
  }

  Widget _buildBubble(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: _maxBubbleWidth(context),
        minHeight: kAvatarSize,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isUser ? AuraColors.primary : Colors.white.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(5),
        ),
        child: child,
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

    final Row row;
    if (isUser) {
      row = Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildIndicatorSlot(),
          const SizedBox(width: _indicatorGap),
          Flexible(child: bubble),
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
