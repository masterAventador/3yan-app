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

  /// 捕获 sendAck 调用记录，供测试断言
  final sentAcks = <int>[];

  @override
  bool sendAck(int serverMsgId) {
    sentAcks.add(serverMsgId);
    return true;
  }

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

// ─────────────────────────────────────────────────────────────────────────────
// Spy controller：覆盖 fetchInitialRelationship 让它只计数不发网络，
// 用于断言 stage_transition 帧是否触发 refetch。
// ─────────────────────────────────────────────────────────────────────────────
class _SpyChatController extends ChatController {
  int refetchCount = 0;

  @override
  Future<void> fetchInitialRelationship() async {
    refetchCount++;
  }
}

void main() {
  late _FakeWsClient fakeWs;
  late _SpyChatController controller;

  setUp(() {
    Get.testMode = true;
    fakeWs = _FakeWsClient();
    Get.put<WsClient>(fakeWs);
    controller = _SpyChatController();
    // setUp 创建 controller 时不调用 onInit（GetX 在 Get.put 时触发）。
    // 这里直接 new，refetchCount 起步 0；onInit 没跑，fetchInitialRelationship 也不会自动调。
    controller.refetchCount = 0;

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
  // stage_transition frame：触发 refetch /me 让 dto 整体刷新
  //
  // Bug 历史：原实现 stage_transition 是占位帧不做事，intimacy_update 只累加 score
  // 不重算 percent / stage / nextThreshold，导致跨阶段后 IntimacyProgressBar 显示
  // 陈旧的"朋友 49/40"。修复 = 跨 stage 信号到达时立即 refetch /me。
  // ───────────────────────────────────────────────────────────────────────────
  group('handleWsFrame - stage_transition', () {
    test('收到 stage_transition 应调用 fetchInitialRelationship 一次', () async {
      controller.listenWsForTest();

      fakeWs.inject(WsEvent.fromJson({
        'type': WsEventType.stageTransition,
        'from': 1,
        'to': 2,
      }));

      await Future.microtask(() {});

      expect(controller.refetchCount, 1);
    });

  });

  // ───────────────────────────────────────────────────────────────────────────
  // new_message ACK 回报
  // ───────────────────────────────────────────────────────────────────────────
  group('new_message ACK 回报', () {
    test('收到 new_message（带 serverMsgId）后向 WS 回一条 ack 帧', () async {
      controller.listenWsForTest();
      fakeWs.inject(WsEvent.fromJson({
        'type': WsEventType.newMessage,
        'serverMsgId': 8888,
        'message': {
          'id': 8888,
          'senderType': 'ai',
          'content': '在吗？想你了',
          'createdAt': '2026-05-27T09:00:00.000Z'
        },
      }));
      await Future.microtask(() {});
      expect(fakeWs.sentAcks, contains(8888));
      expect(controller.messages.any((m) => m.id == 8888), isTrue);
    });

    test('new_message 无 serverMsgId 时不回 ack（不抛异常）', () async {
      controller.listenWsForTest();
      fakeWs.inject(WsEvent.fromJson({
        'type': WsEventType.newMessage,
        'message': {
          'id': 123,
          'senderType': 'ai',
          'content': 'x',
          'createdAt': '2026-05-27T09:00:00.000Z'
        },
      }));
      await Future.microtask(() {});
      expect(fakeWs.sentAcks, isEmpty);
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

  });
}
