import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanyan_common_ui/sanyan_common_ui.dart';

void main() {
  testWidgets('shows "获取验证码" and fires onTap when countdown == 0', (tester) async {
    var tapped = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: AuraSmsCodeButton(countdown: 0, onTap: () => tapped++),
      ),
    ));
    expect(find.text('获取验证码'), findsOneWidget);
    await tester.tap(find.byType(AuraSmsCodeButton));
    expect(tapped, 1);
  });

  testWidgets('shows "Ns" and is disabled when countdown > 0', (tester) async {
    var tapped = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: AuraSmsCodeButton(countdown: 42, onTap: () => tapped++),
      ),
    ));
    expect(find.text('42s'), findsOneWidget);
    expect(find.text('获取验证码'), findsNothing);
    await tester.tap(find.byType(AuraSmsCodeButton));
    expect(tapped, 0);
  });
}
