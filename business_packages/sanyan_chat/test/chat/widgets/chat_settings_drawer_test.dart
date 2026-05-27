import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanyan_chat/src/chat/widgets/chat_settings_drawer.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  group('ChatSettingsDrawer', () {
    testWidgets('渲染订阅入口和全部设置项', (tester) async {
      await tester.pumpWidget(wrap(const ChatSettingsDrawer()));
      expect(find.text('订阅会员'), findsOneWidget);
      expect(find.text('账号与资料'), findsOneWidget);
      expect(find.text('主动消息设置'), findsOneWidget);
      expect(find.text('通知设置'), findsOneWidget);
      expect(find.text('关于'), findsOneWidget);
      expect(find.text('退出登录'), findsOneWidget);
    });

    testWidgets('点击订阅入口触发 onSubscribe', (tester) async {
      var tapped = false;
      await tester.pumpWidget(wrap(ChatSettingsDrawer(onSubscribe: () => tapped = true)));
      await tester.tap(find.text('订阅会员'));
      expect(tapped, isTrue);
    });

    testWidgets('点击账号与资料触发 onProfile', (tester) async {
      var tapped = false;
      await tester.pumpWidget(wrap(ChatSettingsDrawer(onProfile: () => tapped = true)));
      await tester.tap(find.text('账号与资料'));
      expect(tapped, isTrue);
    });

    testWidgets('点击退出登录触发 onLogout', (tester) async {
      var tapped = false;
      await tester.pumpWidget(wrap(ChatSettingsDrawer(onLogout: () => tapped = true)));
      await tester.tap(find.text('退出登录'));
      expect(tapped, isTrue);
    });
  });
}
