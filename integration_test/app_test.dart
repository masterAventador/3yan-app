import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sanyan_chat/sanyan_chat.dart';
import 'package:sanyan_user/sanyan_user.dart';
import 'package:sanyan_app/main.dart' as app;

/// 匹配任意正在播放的语音气泡（VoiceBubble 在 _isPlaying 时会挂
/// ValueKey('voice_playing_[msgId]') 到外层 GestureDetector）。
final _playingVoiceFinder = find.byWidgetPredicate((w) {
  final k = w.key;
  return k is ValueKey &&
      k.value is String &&
      (k.value as String).startsWith('voice_playing_');
});

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

    // 判定 AI 回复：找到刚发的用户消息，它后面一条是 AI 消息就算回了。
    // 不能靠总数变化判断——AI 可能在 Step 4 的 pumpAndSettle 里就回完了。
    final chatCtrl = Get.find<ChatController>();

    Message? aiReply;
    for (int i = 0; i < 5; i++) {
      final userIdx =
          chatCtrl.messages.indexWhere((m) => m.content == testMessage);
      if (userIdx != -1 && userIdx < chatCtrl.messages.length - 1) {
        final after = chatCtrl.messages[userIdx + 1];
        if (after.isFromAi) {
          aiReply = after;
          debugPrint('[E2E] AI 回复已到 id=${after.id} '
              'type=${after.contentType} mediaUrl=${after.mediaUrl} '
              'duration=${after.duration}');
          break;
        }
      }
      await tester.pump(const Duration(seconds: 1));
    }

    expect(aiReply, isNotNull, reason: 'AI 应在 5 秒内回复');
    expect(aiReply!.isVoice, isTrue,
        reason: 'AI 回复应是语音消息，实际 contentType=${aiReply.contentType}');

    // ========== Step 6: 点击播放 AI 语音回复 ==========
    debugPrint('[E2E] Step 6: 播放 AI 语音回复');

    // 按消息 id 精准定位这一条 AI 语音气泡
    final aiReplyId = aiReply.id;
    final targetBubble = find.byWidgetPredicate(
      (w) => w is VoiceBubble && w.message.id == aiReplyId,
    );
    await _waitFor(tester, targetBubble,
        maxSeconds: 3, reason: 'AI 语音气泡应出现在列表中');

    // ensureVisible 把它滚到视图中心，避开输入框遮挡
    await tester.ensureVisible(targetBubble);
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(targetBubble);

    // 轮询等播放态 Key 出现（tap 后应立即同步 setState，但保险起见最多等 3 秒）
    bool playingVisible = false;
    for (int i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (_playingVoiceFinder.evaluate().isNotEmpty) {
        playingVisible = true;
        debugPrint('[E2E] 播放态 Key 出现（${(i + 1) * 100}ms 后）');
        break;
      }
    }
    expect(playingVisible, isTrue,
        reason: '点击后应在 3 秒内挂上 voice_playing_* Key（说明开始播放）');

    // ========== Step 7: 等待播放完成 ==========
    debugPrint('[E2E] Step 7: 等待播放完成...');
    bool playbackFinished = false;
    for (int i = 0; i < 60; i++) {
      await tester.pump(const Duration(seconds: 1));
      // 播放完成时 onPlayerComplete 回调把 _isPlaying 置 false，playing Key 消失
      if (_playingVoiceFinder.evaluate().isEmpty) {
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
