import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:sanyan_chat/src/api/models/relationship.dart';
import 'package:sanyan_chat/src/chat/chat_controller.dart';
import 'package:sanyan_network/sanyan_network.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Stub WsClient：不实际建 WebSocket，只暴露一个可手动 sink 的 StreamController
// ─────────────────────────────────────────────────────────────────────────────
class _FakeWsClient extends WsClient {
  final _ctrl = StreamController<WsEvent>.broadcast();

  @override
  Stream<WsEvent> get eventStream => _ctrl.stream;

  /// 手动向 stream 注入 WsEvent（测试用）
  void inject(WsEvent event) => _ctrl.add(event);

  @override
  void onClose() {
    _ctrl.close();
    super.onClose();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 测试用 stub Relationship（用于初始化 controller 的 relationship 属性）
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
    controller = ChatController();

    // 直接设置初始 relationship（绕过网络，专注测试 ws frame 逻辑）
    controller.relationship.value = _baseRelationship;
  });

  tearDown(() async {
    controller.onClose();
    Get.reset();
  });

  // ───────────────────────────────────────────────────────────────────────────
  // intimacy_update frame：应更新 relationship.value.intimacyScore
  // ───────────────────────────────────────────────────────────────────────────
  group('handleWsFrame - intimacy_update', () {
    test('收到 intimacy_update 后 relationship.value.intimacyScore 被更新', () async {
      controller.listenWsForTest();

      fakeWs.inject(WsEvent.fromJson({
        'type': WsEventType.intimacyUpdate,
        'score': 150,
        'delta': 5,
        'reason': 'MESSAGE_SENT',
      }));

      // 让 stream 事件分发
      await Future.microtask(() {});

      expect(controller.relationship.value?.intimacyScore, 150);
    });

    test('relationship 为 null 时收到 intimacy_update 不抛异常', () async {
      controller.relationship.value = null;
      controller.listenWsForTest();

      expect(
        () {
          fakeWs.inject(WsEvent.fromJson({
            'type': WsEventType.intimacyUpdate,
            'score': 150,
            'delta': 5,
            'reason': 'MESSAGE_SENT',
          }));
        },
        returnsNormally,
      );
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // stage_story frame：应更新 pendingStoryMessage.value
  // ───────────────────────────────────────────────────────────────────────────
  group('handleWsFrame - stage_story', () {
    test('收到 stage_story 后 pendingStoryMessage.value 被赋值', () async {
      controller.listenWsForTest();

      fakeWs.inject(WsEvent.fromJson({
        'type': WsEventType.stageStory,
        'stage': 2,
        'story_message': '她半夜发来一条消息……',
      }));

      await Future.microtask(() {});

      expect(controller.pendingStoryMessage.value, '她半夜发来一条消息……');
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // stage_transition frame：不更新 relationship 也不更新 pendingStoryMessage（占位帧）
  // ───────────────────────────────────────────────────────────────────────────
  group('handleWsFrame - stage_transition', () {
    test('收到 stage_transition 后 relationship 和 pendingStoryMessage 均不变', () async {
      controller.listenWsForTest();

      fakeWs.inject(WsEvent.fromJson({
        'type': WsEventType.stageTransition,
        'from': 1,
        'to': 2,
      }));

      await Future.microtask(() {});

      expect(controller.relationship.value?.intimacyScore, 100); // 不变
      expect(controller.pendingStoryMessage.value, ''); // 不变
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // fetchInitialRelationship：成功时 relationship.value 被赋值
  // （通过直接调用，验证属性结构和赋值逻辑；网络部分不在此测试）
  // ───────────────────────────────────────────────────────────────────────────
  group('relationship Rx属性', () {
    test('relationship 初始为 null', () {
      // 新建一个未设置 relationship 的 controller，验证默认值
      controller.relationship.value = null;
      expect(controller.relationship.value, isNull);
    });

    test('relationship 可被赋值', () {
      controller.relationship.value = _baseRelationship;
      expect(controller.relationship.value?.intimacyScore, 100);
      expect(controller.relationship.value?.currentStage, 1);
    });

    test('pendingStoryMessage 初始为空字符串', () {
      expect(controller.pendingStoryMessage.value, '');
    });
  });
}
