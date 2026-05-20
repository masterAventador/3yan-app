import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanyan_chat/src/api/models/message.dart';
import 'package:sanyan_chat/src/chat/widget/message_bubble.dart';
import 'package:sanyan_chat/src/chat/widget/message_bubble_shell.dart';
import 'package:sanyan_network/sanyan_network.dart';

// 单字短消息也要保证气泡高度 >= kAvatarSize（与头像齐平，避免缩水难看）。

Widget _wrap(Widget child) => MediaQuery(
  data: const MediaQueryData(size: Size(400, 800)),
  child: MaterialApp(home: Scaffold(body: SizedBox(width: 400, child: child))),
);

Message _msg(String text) => Message(
  id: 1,
  senderType: SenderType.user,
  content: text,
  createdAt: '2026-05-17T10:00:00Z',
);

double _bubbleHeight(WidgetTester tester, String text) {
  final RenderBox box = tester.renderObject(
    find.ancestor(
      of: find.text(text),
      matching: find.byType(Container),
    ).first,
  );
  return box.size.height;
}

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
}
