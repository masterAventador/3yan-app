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
  // 设置抽屉：右上角设置按钮 + 点击主体右移露出左侧抽屉
  // ─────────────────────────────────────────────────────────────────────────
  group('ChatPage - 设置抽屉', () {
    testWidgets('AppBar 右上角有设置按钮', (tester) async {
      await tester.pumpWidget(GetMaterialApp(home: ChatPage()));
      await tester.pump();

      expect(find.byIcon(Icons.settings), findsOneWidget);
    });

    testWidgets('点击设置按钮：主体整体右移露出设置抽屉', (tester) async {
      await tester.pumpWidget(GetMaterialApp(home: ChatPage()));
      await tester.pump();

      // 主体（AppBar 标题"小婉"所在）初始在最左
      final titleBefore = tester.getTopLeft(find.text('小婉')).dx;

      await tester.tap(find.byIcon(Icons.settings));
      await tester.pump(); // 触发 setState
      await tester.pump(const Duration(milliseconds: 350)); // 等平移动画完成

      // 主体右移，标题位置变大
      final titleAfter = tester.getTopLeft(find.text('小婉')).dx;
      expect(titleAfter, greaterThan(titleBefore));
      // 露出的抽屉里订阅入口可见
      expect(find.text('订阅会员'), findsOneWidget);
    });
  });
}
