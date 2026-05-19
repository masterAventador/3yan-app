import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanyan_chat/src/chat/widget/typing_indicator.dart';

void main() {
  testWidgets('typing indicator avatar 应为圆形（与 MessageBubble 的真 AI 头像一致）', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: const TypingIndicator()),
      ),
    );

    // 找 typing indicator 内 size=40 的 Container（头像），验证 decoration.shape
    final avatarContainer = tester.widgetList<Container>(find.byType(Container)).firstWhere(
      (c) {
        final d = c.decoration;
        if (d is! BoxDecoration) return false;
        // 头像由 gradient + size 40x40 标识
        return d.gradient != null;
      },
      orElse: () => throw TestFailure('没找到带 gradient 的 Container（typing avatar）'),
    );

    final deco = avatarContainer.decoration as BoxDecoration;
    expect(
      deco.shape,
      BoxShape.circle,
      reason: 'typing avatar 应该是 BoxShape.circle，跟 MessageBubble 的 AI 头像一致',
    );
  });
}
