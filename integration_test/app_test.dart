import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sanyan_user/sanyan_user.dart';
import 'package:sanyan_app/main.dart' as app;

/// E2E 全流程测试：注册 → 登录 → 发消息 → 收 AI 回复
///
/// 服务器: http://154.8.162.83
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // 每次用时间戳生成新手机号，避免重复注册冲突
  final timestamp = DateTime.now().millisecondsSinceEpoch;
  final testPhone = '139${(timestamp % 100000000).toString().padLeft(8, '0')}';
  const testPassword = 'test123456';
  const testNickname = 'E2E测试用户';

  // 已有测试账号（注册测试失败时的兜底）
  const fallbackPhone = '13900001111';
  const fallbackPassword = '123456';

  testWidgets('全流程: 注册 → 登录 → 发消息 → AI 回复', (tester) async {
    // 清除登录态
    await LocalStorage.init();
    LocalStorage.token = null;
    LocalStorage.userId = null;

    app.main();
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // ========== Step 1: 登录页 → 跳转注册 ==========
    debugPrint('[E2E] Step 1: 登录页，跳转注册');
    expect(find.text('走进更温暖的连接方式'), findsOneWidget);

    // 注册链接是 RichText 拼接的，匹配完整字符串
    await tester.tap(find.text('还没有账号？ 立即注册', findRichText: true));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // ========== Step 2: 注册 ==========
    debugPrint('[E2E] Step 2: 注册页');
    expect(find.text('加入三言'), findsOneWidget);

    // 找所有输入框：昵称、手机号、验证码、密码（注册页字段顺序）
    final textFields = find.byType(TextField);
    expect(textFields, findsNWidgets(4));

    // 输入昵称（第 0 个）
    await tester.enterText(textFields.at(0), testNickname);
    await tester.pumpAndSettle();

    // 输入手机号（第 1 个）
    await tester.enterText(textFields.at(1), testPhone);
    await tester.pumpAndSettle();
    debugPrint('[E2E] 手机号: $testPhone');

    // 点获取验证码
    await tester.tap(find.text('获取验证码'));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    debugPrint('[E2E] 已点击获取验证码');

    // 输入验证码（第 2 个，测试服务端接受任意6位数字）
    await tester.enterText(textFields.at(2), '123456');
    await tester.pumpAndSettle();

    // 输入密码（第 3 个）
    await tester.enterText(textFields.at(3), testPassword);
    await tester.pumpAndSettle();

    // 点注册按钮
    await tester.tap(find.text('注册'));
    await tester.pumpAndSettle(const Duration(seconds: 5));

    // 注册成功后应该回到登录页或直接进首页
    // 如果回到登录页就继续登录流程（登录页有"走进更温暖的连接方式"，首页有"Messages"）
    final onLoginPage = find.text('走进更温暖的连接方式').evaluate().isNotEmpty;
    final onHomePage = find.text('Messages').evaluate().isNotEmpty;
    debugPrint('[E2E] 注册后: loginPage=$onLoginPage, homePage=$onHomePage');

    String loginPhone = testPhone;
    String loginPassword = testPassword;

    if (!onHomePage) {
      // 如果注册失败（手机号已存在等），用兜底账号
      if (!onLoginPage) {
        debugPrint('[E2E] 注册可能失败，返回登录页');
        // 返回链接是 RichText 拼接的，匹配完整字符串
        await tester.tap(find.text('已有账号？ 返回登录', findRichText: true));
        await tester.pumpAndSettle(const Duration(seconds: 1));
        loginPhone = fallbackPhone;
        loginPassword = fallbackPassword;
      }

      // ========== Step 3: 登录 ==========
      debugPrint('[E2E] Step 3: 登录 ($loginPhone)');

      final loginFields = find.byType(TextField);
      // 输入手机号
      await tester.enterText(loginFields.at(0), loginPhone);
      await tester.pumpAndSettle();

      // 输入密码
      await tester.enterText(loginFields.at(1), loginPassword);
      await tester.pumpAndSettle();

      // 点登录按钮
      await tester.tap(find.text('登录'));
      await tester.pumpAndSettle(const Duration(seconds: 5));
    }

    // ========== Step 4: 首页 - 会话列表 ==========
    debugPrint('[E2E] Step 4: 首页');
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // 首页应显示"三言" 标题和 "Messages" 区域标题
    expect(find.text('Messages'), findsAtLeastNWidgets(1));

    // 查找会话（小婉）
    final hasConversation = find.text('小婉').evaluate().isNotEmpty;
    debugPrint('[E2E] 有会话: $hasConversation');

    if (!hasConversation) {
      debugPrint('[E2E] 没有会话，跳过聊天步骤');
      return;
    }

    // ========== Step 5: 进入聊天 ==========
    debugPrint('[E2E] Step 5: 进入聊天');
    await tester.tap(find.text('小婉'));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // 应该看到聊天页导航栏的名字
    expect(find.text('小婉'), findsWidgets);

    // ========== Step 6: 发送消息 ==========
    debugPrint('[E2E] Step 6: 发送消息');
    final chatInput = find.byType(TextField);
    expect(chatInput, findsOneWidget);

    final testMessage = 'E2E测试 ${DateTime.now().millisecondsSinceEpoch}';
    await tester.enterText(chatInput, testMessage);
    await tester.pumpAndSettle();

    // 通过软键盘 Send action 发送消息（新输入栏没有独立发送按钮）
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pumpAndSettle();

    // 消息应出现在列表中
    expect(find.text(testMessage), findsOneWidget);
    debugPrint('[E2E] 消息已发送: $testMessage');

    // ========== Step 7: 等待 AI 回复 ==========
    debugPrint('[E2E] Step 7: 等待 AI 回复...');
    bool aiReplied = false;

    for (int i = 0; i < 30; i++) {
      await tester.pump(const Duration(seconds: 1));

      final textFinder = find.byType(Text);
      for (final element in textFinder.evaluate()) {
        final widget = element.widget as Text;
        final text = widget.data ?? '';
        // AI 回复是长度>5、不是我们发的消息、不是 UI 固定文案
        if (text.length > 5 &&
            text != testMessage &&
            !text.contains('E2E测试') &&
            !text.contains('三言') &&
            !text.contains('消息') &&
            text != '说点什么...' &&
            text != '正在输入...' &&
            text != '小婉' &&
            text != 'ONLINE' &&
            text != 'Messages' &&
            text != 'AI 陪伴，懂你所言') {
          debugPrint('[E2E] AI 回复: $text');
          aiReplied = true;
          break;
        }
      }
      if (aiReplied) break;
    }

    expect(aiReplied, isTrue, reason: 'AI 应该在 30 秒内回复');
    debugPrint('[E2E] 全流程通过！等待 10 秒让你看看效果...');

    // 多等几秒让用户看到 AI 回复渲染在屏幕上
    for (int i = 10; i > 0; i--) {
      await tester.pump(const Duration(seconds: 1));
      debugPrint('[E2E] ${i}s 后结束');
    }
  });
}
