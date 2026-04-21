import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanyan_chat/sanyan_chat.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('sending status shows loading indicator, no error icon', (tester) async {
    await tester.pumpWidget(_wrap(
      MessageBubbleBase(
        isFromAi: false,
        status: MessageStatus.sending,
        onRetry: null,
        child: const Text('hi'),
      ),
    ));
    expect(find.byKey(const Key('bubble-sending-indicator')), findsOneWidget);
    expect(find.byKey(const Key('bubble-failed-indicator')), findsNothing);
    expect(find.text('hi'), findsOneWidget);
  });

  testWidgets('failed status shows error icon, tap invokes onRetry', (tester) async {
    var tapped = 0;
    await tester.pumpWidget(_wrap(
      MessageBubbleBase(
        isFromAi: false,
        status: MessageStatus.failed,
        onRetry: () => tapped++,
        child: const Text('hi'),
      ),
    ));
    expect(find.byKey(const Key('bubble-failed-indicator')), findsOneWidget);
    expect(find.byKey(const Key('bubble-sending-indicator')), findsNothing);
    await tester.tap(find.byKey(const Key('bubble-failed-indicator')));
    expect(tapped, 1);
  });

  testWidgets('sent status shows no indicator', (tester) async {
    await tester.pumpWidget(_wrap(
      MessageBubbleBase(
        isFromAi: false,
        status: MessageStatus.sent,
        onRetry: null,
        child: const Text('hi'),
      ),
    ));
    expect(find.byKey(const Key('bubble-sending-indicator')), findsNothing);
    expect(find.byKey(const Key('bubble-failed-indicator')), findsNothing);
    expect(find.text('hi'), findsOneWidget);
  });

  testWidgets('null status shows no indicator', (tester) async {
    await tester.pumpWidget(_wrap(
      MessageBubbleBase(
        isFromAi: true,
        status: null,
        onRetry: null,
        child: const Text('hi'),
      ),
    ));
    expect(find.byKey(const Key('bubble-sending-indicator')), findsNothing);
    expect(find.byKey(const Key('bubble-failed-indicator')), findsNothing);
  });

  testWidgets('AI message: content left, no indicator for sent', (tester) async {
    await tester.pumpWidget(_wrap(
      MessageBubbleBase(
        isFromAi: true,
        status: MessageStatus.sent,
        onRetry: null,
        child: const Text('hi'),
      ),
    ));
    // AI 消息没有发送状态，不应展示指示
    expect(find.byKey(const Key('bubble-sending-indicator')), findsNothing);
    expect(find.byKey(const Key('bubble-failed-indicator')), findsNothing);
  });

  testWidgets('failed with null onRetry: still shows icon but tap is no-op', (tester) async {
    await tester.pumpWidget(_wrap(
      MessageBubbleBase(
        isFromAi: false,
        status: MessageStatus.failed,
        onRetry: null,
        child: const Text('hi'),
      ),
    ));
    expect(find.byKey(const Key('bubble-failed-indicator')), findsOneWidget);
    // 点击不应抛异常（IconButton 的 onPressed 是 null 时按钮本身 disabled）
    await tester.tap(find.byKey(const Key('bubble-failed-indicator')));
    // 没异常即 pass
  });
}
