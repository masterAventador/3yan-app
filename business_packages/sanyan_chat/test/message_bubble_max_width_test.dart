import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanyan_chat/src/api/models/message.dart';
import 'package:sanyan_chat/src/chat/widget/message_bubble.dart';
import 'package:sanyan_network/sanyan_network.dart';

// Screen width = 400, page padding = 16 (×2), avatar = 40 (×2), gap = 10 (×2)
// Expected max bubble width = 400 - 16*2 - 40*2 - 10*2 = 268
const double _kScreenWidth = 400;
const double _kExpectedMaxBubbleWidth = 268;

Widget _wrap(Widget child, {double width = _kScreenWidth}) {
  return MediaQuery(
    data: MediaQueryData(size: Size(width, 800)),
    child: MaterialApp(
      home: Scaffold(
        body: SizedBox(width: width, child: child),
      ),
    ),
  );
}

Message _msg(String text, {required String sender}) => Message(
  id: 1,
  senderType: sender,
  content: text,
  createdAt: '2026-05-17T10:00:00Z',
);

void main() {
  testWidgets('user bubble maxWidth leaves room for opposite avatar', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        MessageBubble(
          message: _msg(
            '一段很长的消息内容用来撑满气泡的最大宽度看看到底有多宽',
            sender: SenderType.user,
          ),
        ),
      ),
    );

    final constrained = tester.widgetList<ConstrainedBox>(
      find.byType(ConstrainedBox),
    );
    final hit = constrained.firstWhere(
      (c) => c.constraints.maxWidth == _kExpectedMaxBubbleWidth,
      orElse: () => throw TestFailure(
        'No ConstrainedBox with maxWidth=$_kExpectedMaxBubbleWidth found. '
        'Actual maxWidths: ${constrained.map((c) => c.constraints.maxWidth).toList()}',
      ),
    );
    expect(hit.constraints.maxWidth, _kExpectedMaxBubbleWidth);
  });

  testWidgets('ai bubble maxWidth leaves room for opposite avatar', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        MessageBubble(
          message: _msg(
            '一段很长的 AI 回复用来撑满气泡的最大宽度看看到底有多宽',
            sender: SenderType.ai,
          ),
        ),
      ),
    );

    final constrained = tester.widgetList<ConstrainedBox>(
      find.byType(ConstrainedBox),
    );
    final hit = constrained.firstWhere(
      (c) => c.constraints.maxWidth == _kExpectedMaxBubbleWidth,
      orElse: () => throw TestFailure(
        'No ConstrainedBox with maxWidth=$_kExpectedMaxBubbleWidth found. '
        'Actual maxWidths: ${constrained.map((c) => c.constraints.maxWidth).toList()}',
      ),
    );
    expect(hit.constraints.maxWidth, _kExpectedMaxBubbleWidth);
  });
}
