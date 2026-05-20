import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanyan_chat/src/api/models/message.dart';
import 'package:sanyan_chat/src/api/models/message_status.dart';
import 'package:sanyan_chat/src/chat/widget/message_bubble.dart';
import 'package:sanyan_chat/src/chat/widget/message_bubble_shell.dart';
import 'package:sanyan_network/sanyan_network.dart';

// 单字短消息也要保证气泡高度 >= kAvatarSize（与头像齐平，避免缩水难看）。

Widget _wrap(Widget child) => MediaQuery(
  data: const MediaQueryData(size: Size(400, 800)),
  child: MaterialApp(home: Scaffold(body: SizedBox(width: 400, child: child))),
);

Message _msg(String text, {MessageStatus? status}) => Message(
  id: 1,
  senderType: SenderType.user,
  content: text,
  createdAt: '2026-05-17T10:00:00Z',
  status: status,
);

Size _bubbleSize(WidgetTester tester, String text) {
  final RenderBox box = tester.renderObject(
    find.ancestor(
      of: find.text(text),
      matching: find.byType(Container),
    ).first,
  );
  return box.size;
}

double _bubbleHeight(WidgetTester tester, String text) => _bubbleSize(tester, text).height;

void main() {
  testWidgets('单字气泡高度应 >= kAvatarSize（跟头像齐平）', (tester) async {
    await tester.pumpWidget(_wrap(MessageBubble(message: _msg('好'))));
    await tester.pumpAndSettle();

    final h = _bubbleHeight(tester, '好');
    expect(
      h,
      greaterThanOrEqualTo(kAvatarSize),
      reason: '单字消息气泡高度应该至少 = kAvatarSize($kAvatarSize)，实际 $h',
    );
  });

  testWidgets('单字气泡宽度应贴合文字，不应被撑成最大宽度', (tester) async {
    await tester.pumpWidget(_wrap(MessageBubble(message: _msg('好'))));
    await tester.pumpAndSettle();

    final w = _bubbleSize(tester, '好').width;
    // 屏宽 400、pagePadding 16、avatar+gap 50 → maxBubbleWidth ≈ 268
    // 单字 16px 字号 + 左右各 10 padding，气泡宽度应远小于 100
    expect(
      w,
      lessThan(100),
      reason: '单字消息气泡不应被撑到最大宽度，期望 < 100，实际 $w',
    );
  });

  testWidgets('failed 状态下 indicator 感叹号应与 bubble 垂直居中对齐', (tester) async {
    await tester.pumpWidget(_wrap(
      MessageBubble(message: _msg('好', status: MessageStatus.failed)),
    ));
    await tester.pumpAndSettle();

    final iconFinder = find.byIcon(Icons.error);
    final bubbleFinder = find.ancestor(
      of: find.text('好'),
      matching: find.byType(Container),
    ).first;

    final iconBox = tester.renderObject<RenderBox>(iconFinder);
    final bubbleBox = tester.renderObject<RenderBox>(bubbleFinder);

    final iconCenterY = iconBox.localToGlobal(Offset(iconBox.size.width / 2, iconBox.size.height / 2)).dy;
    final bubbleTop = bubbleBox.localToGlobal(Offset.zero).dy;
    final bubbleMidY = bubbleTop + bubbleBox.size.height / 2;

    // 容差 3px（亚像素 / IconButton padding 等导致微小偏差可接受）
    expect(
      (iconCenterY - bubbleMidY).abs(),
      lessThanOrEqualTo(3),
      reason: '感叹号中心应与 bubble 中线对齐，期望 ≈ $bubbleMidY，实际 $iconCenterY',
    );
  });
}
