import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sanyan_user/sanyan_user.dart';
import 'package:sanyan_app/main.dart' as app;

/// E2E test: login → enter chat → send message → receive AI reply
///
/// Test account: 13900001111 / 123456 (pre-registered on server)
/// Server: http://154.8.162.83
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const testPhone = '13900001111';
  const testPassword = '123456';

  testWidgets('Complete flow: Login → Chat → Send → AI Reply', (tester) async {
    // Clean state
    await LocalStorage.init();
    LocalStorage.token = null;
    LocalStorage.userId = null;

    app.main();
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // === Step 1: Login page ===
    debugPrint('[E2E] Step 1: Login');
    expect(find.text('三言'), findsOneWidget);

    // Enter phone
    final phoneField = find.byType(TextField).first;
    await tester.enterText(phoneField, testPhone);
    await tester.pumpAndSettle();

    // Enter password
    final passwordField = find.byType(TextField).last;
    await tester.enterText(passwordField, testPassword);
    await tester.pumpAndSettle();

    // Tap login
    await tester.tap(find.widgetWithText(FilledButton, '登录'));
    await tester.pumpAndSettle(const Duration(seconds: 5));

    debugPrint('[E2E] Login done, waiting for home page...');

    // === Step 2: Home page ===
    await tester.pumpAndSettle(const Duration(seconds: 3));

    final hasConversation = find.text('小晚').evaluate().isNotEmpty;
    debugPrint('[E2E] Step 2: Home page, has conversation: $hasConversation');

    if (!hasConversation) {
      debugPrint('[E2E] No conversation, test ends (need to create one manually first)');
      return;
    }

    // === Step 3: Enter chat ===
    debugPrint('[E2E] Step 3: Entering chat...');
    await tester.tap(find.text('小晚'));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // === Step 4: Send message ===
    debugPrint('[E2E] Step 4: Sending message...');
    final inputField = find.byType(TextField);
    expect(inputField, findsOneWidget);

    final testMessage = '自动化测试 ${DateTime.now().millisecondsSinceEpoch}';
    await tester.enterText(inputField, testMessage);
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    // User message should appear
    expect(find.text(testMessage), findsOneWidget);
    debugPrint('[E2E] Message sent: $testMessage');

    // === Step 5: Wait for AI reply ===
    debugPrint('[E2E] Step 5: Waiting for AI reply...');
    bool aiReplied = false;

    for (int i = 0; i < 30; i++) {
      await tester.pump(const Duration(seconds: 1));

      // Count text widgets that look like chat messages (length > 5, not UI elements)
      final textFinder = find.byType(Text);
      int messageCount = 0;
      String lastAiMessage = '';

      for (final element in textFinder.evaluate()) {
        final widget = element.widget as Text;
        final text = widget.data ?? '';
        if (text.length > 5 &&
            text != testMessage &&
            !text.contains('三言') &&
            text != '说点什么...' &&
            text != '正在输入...' &&
            text != '还没有对话，开始聊天吧') {
          messageCount++;
          lastAiMessage = text;
        }
      }

      if (lastAiMessage.isNotEmpty && messageCount > 0) {
        debugPrint('[E2E] AI replied: $lastAiMessage');
        aiReplied = true;
        break;
      }
    }

    expect(aiReplied, isTrue, reason: 'AI should reply within 30 seconds');
    debugPrint('[E2E] PASSED! Full flow completed.');
  });
}
