import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:sanyan_chat/src/api/models/relationship.dart';
import 'package:sanyan_chat/src/chat/chat_controller.dart';
import 'package:sanyan_chat/src/chat/chat_page.dart';
import 'package:sanyan_chat/src/chat/widgets/intimacy_progress_bar.dart';
import 'package:sanyan_network/sanyan_network.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Stub WsClient
// ─────────────────────────────────────────────────────────────────────────────
class _FakeWsClient extends WsClient {
  final _ctrl = StreamController<WsEvent>.broadcast();

  @override
  Stream<WsEvent> get eventStream => _ctrl.stream;

  void inject(WsEvent event) => _ctrl.add(event);

  @override
  void onClose() {
    _ctrl.close();
    super.onClose();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 测试用 stub Relationship
// ─────────────────────────────────────────────────────────────────────────────
const _baseRelationship = Relationship(
  userId: 1,
  characterId: 1,
  intimacyScore: 100,
  currentStage: 1,
  currentStageName: '朋友',
  nextStageThreshold: 300,
  percentToNextStage: 0.33,
);

void main() {
  late _FakeWsClient fakeWs;
  late ChatController controller;

  setUp(() {
    Get.testMode = true;
    fakeWs = _FakeWsClient();
    Get.put<WsClient>(fakeWs);
    controller = Get.put(ChatController());
    // 绕过网络，直接设置初始 relationship
    controller.relationship.value = _baseRelationship;
  });

  tearDown(() async {
    controller.onClose();
    Get.reset();
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 集成测试：IntimacyProgressBar 在 chat_page 中的渲染
  // ─────────────────────────────────────────────────────────────────────────
  group('ChatPage - IntimacyProgressBar 集成', () {
    testWidgets('relationship 不为 null 时 IntimacyProgressBar 出现在页面中',
        (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(home: ChatPage()),
      );
      await tester.pump();

      expect(find.byType(IntimacyProgressBar), findsOneWidget);
    });

    testWidgets('relationship 为 null 时 IntimacyProgressBar 不渲染',
        (tester) async {
      controller.relationship.value = null;

      await tester.pumpWidget(
        GetMaterialApp(home: ChatPage()),
      );
      await tester.pump();

      expect(find.byType(IntimacyProgressBar), findsNothing);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 集成测试：pendingStoryMessage 触发 StageTransitionDialog
  // ─────────────────────────────────────────────────────────────────────────
  group('ChatPage - StageTransitionDialog 集成', () {
    testWidgets('pendingStoryMessage 变为非空时弹出 dialog', (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(home: ChatPage()),
      );
      await tester.pump();

      // 触发 ever() 监听
      controller.pendingStoryMessage.value = '她半夜悄悄想你……';
      // pump 推进 dialog 弹出和 TweenAnimationBuilder 动画（300ms）
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      // dialog 应出现（显示 storyMessage 文字）
      expect(find.text('她半夜悄悄想你……'), findsOneWidget);
    });

    testWidgets('dialog 显示后 pendingStoryMessage 被清空', (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(home: ChatPage()),
      );
      await tester.pump();

      controller.pendingStoryMessage.value = '测试故事文案';
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      // dialog 弹出后 controller 字段应已清空（消费语义）
      expect(controller.pendingStoryMessage.value, '');
    });
  });
}
