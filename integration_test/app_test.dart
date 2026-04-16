import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sanyan_user/sanyan_user.dart';
import 'package:sanyan_app/main.dart' as app;

/// E2E 全流程测试：登录 → 进入聊天 → 发消息 → 收 AI 语音回复 → 点击播放 → 等播放完成
///
/// 服务器: http://154.8.162.83
/// 账号: 13900001111 / 123456（预置测试账号）
///
/// 等某个 widget 出现，每 100ms pump 一次，到了立即返回。
/// 用来替代 pumpAndSettle(Duration(seconds: X))——因为页面上如果有
/// CircularProgressIndicator 这种无限动画，pumpAndSettle 会一直等到 timeout，
/// 让 E2E 看起来特别卡。
Future<void> _waitFor(
  WidgetTester tester,
  Finder finder, {
  int maxSeconds = 10,
  String? reason,
}) async {
  for (int i = 0; i < maxSeconds * 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) return;
  }
  throw Exception('等待超时（${maxSeconds}s）: ${reason ?? finder.toString()}');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const loginPhone = '13900001111';
  const loginPassword = '123456';

  testWidgets('全流程: 登录 → 发消息 → AI 语音回复 → 播放', (tester) async {
    // 清除登录态
    await LocalStorage.init();
    LocalStorage.token = null;
    LocalStorage.userId = null;

    app.main();
    // 启动只有登录页一个页面，不存在转场动画双页面共存问题，
    // 用 _waitFor 轮询，避免被启动期 spinner 卡到 timeout。
    await _waitFor(tester, find.text('走进更温暖的连接方式'), reason: '启动 → 登录页');
    await Future.delayed(const Duration(milliseconds: 250));

    // ========== Step 1: 登录 ==========
    debugPrint('[E2E] Step 1: 登录 ($loginPhone)');

    final loginFields = find.byType(TextField);
    expect(loginFields, findsNWidgets(2));

    // 输入手机号
    await tester.enterText(loginFields.at(0), loginPhone);
    await tester.pumpAndSettle();

    // 输入密码
    await tester.enterText(loginFields.at(1), loginPassword);
    await tester.pumpAndSettle();

    // 点登录按钮
    await tester.tap(find.text('登录'));
    // 等首页出现（"Messages" 是首页 section 标题）
    await _waitFor(tester, find.text('Messages'), reason: '登录 → 首页');
    await Future.delayed(const Duration(milliseconds: 250));

    // ========== Step 2: 首页 - 会话列表 ==========
    debugPrint('[E2E] Step 2: 首页');
    // Messages 应已出现（前面 _waitFor 已等过）。稍等会话列表加载完。
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Messages'), findsAtLeastNWidgets(1));

    // 查找会话（小婉）
    expect(find.text('小婉'), findsOneWidget, reason: '首页应显示预置 AI 角色「小婉」');

    // ========== Step 3: 进入聊天 ==========
    debugPrint('[E2E] Step 3: 进入聊天');
    await tester.tap(find.text('小婉'));
    // 等聊天页加载完：TextField 出现（输入栏）
    await _waitFor(tester, find.byType(TextField), reason: '首页 → 聊天页');
    await Future.delayed(const Duration(milliseconds: 250));

    // 应该看到聊天页导航栏的名字
    expect(find.text('小婉'), findsWidgets);

    // ========== Step 4: 发送消息 ==========
    debugPrint('[E2E] Step 4: 发送消息');
    final chatInput = find.byType(TextField);
    expect(chatInput, findsOneWidget);

    final testMessage = 'E2E测试 ${DateTime.now().millisecondsSinceEpoch}';
    await tester.enterText(chatInput, testMessage);
    await tester.pumpAndSettle();

    // 通过软键盘 Send action 发送消息（输入栏没有独立发送按钮）
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pumpAndSettle();

    // 消息应出现在列表中
    expect(find.text(testMessage), findsOneWidget);
    debugPrint('[E2E] 消息已发送: $testMessage');

    // ========== Step 5: 等待 AI 语音回复 ==========
    debugPrint('[E2E] Step 5: 等待 AI 语音回复...');

    // 用 play_arrow icon 数量变化检测：每条 AI 语音气泡都有一个 play_arrow，
    // 比 Text 匹配更可靠（避免匹配到历史消息）。
    final initialPlayCount = find.byIcon(Icons.play_arrow).evaluate().length;
    debugPrint('[E2E] 当前已有 $initialPlayCount 条历史语音消息');

    bool aiReplied = false;
    for (int i = 0; i < 30; i++) {
      await tester.pump(const Duration(seconds: 1));
      final currentCount = find.byIcon(Icons.play_arrow).evaluate().length;
      if (currentCount > initialPlayCount) {
        aiReplied = true;
        debugPrint('[E2E] AI 语音消息到达（${i + 1}s 后），现在共 $currentCount 条');
        break;
      }
    }

    expect(aiReplied, isTrue, reason: 'AI 应在 30 秒内回复语音消息（play_arrow 数量增加）');

    // ========== Step 6: 点击播放 AI 语音回复 ==========
    debugPrint('[E2E] Step 6: 播放 AI 语音回复');

    // 等 1 秒让 AI 语音气泡完全渲染 + auto-scroll 稳定
    await tester.pump(const Duration(seconds: 1));

    final playIcons = find.byIcon(Icons.play_arrow);
    final playIconCount = playIcons.evaluate().length;
    debugPrint('[E2E] 找到 $playIconCount 个播放按钮，点击最后一个（AI 最新回复）');

    // 取最新 AI 语音气泡（最后一个 play_arrow）
    final latestPlayIcon = playIcons.at(playIconCount - 1);

    // ensureVisible 把它滚到视图中心，避开输入框遮挡
    await tester.ensureVisible(latestPlayIcon);
    await tester.pump(const Duration(milliseconds: 300));

    // 点击
    await tester.tap(latestPlayIcon);

    // 轮询等 pause icon 出现（tap 后应立即同步 setState，但保险起见最多等 3 秒）
    bool pauseVisible = false;
    for (int i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.byIcon(Icons.pause).evaluate().isNotEmpty) {
        pauseVisible = true;
        debugPrint('[E2E] pause icon 出现（${(i + 1) * 100}ms 后）');
        break;
      }
    }
    expect(pauseVisible, isTrue,
        reason: '点击后应在 3 秒内显示 pause icon（说明开始播放）');

    // ========== Step 7: 等待播放完成 ==========
    debugPrint('[E2E] Step 7: 等待播放完成...');
    bool playbackFinished = false;
    for (int i = 0; i < 60; i++) {
      await tester.pump(const Duration(seconds: 1));
      // 播放完成时 onPlayerComplete 回调把 _isPlaying 置 false，pause icon 消失
      if (find.byIcon(Icons.pause).evaluate().isEmpty) {
        playbackFinished = true;
        debugPrint('[E2E] 播放完成（${i + 1}s 后）');
        break;
      }
      if (i % 5 == 4) debugPrint('[E2E] 仍在播放... ${i + 1}s');
    }
    expect(playbackFinished, isTrue, reason: '播放应在 60 秒内结束');

    debugPrint('[E2E] 全流程通过！');
  });
}
