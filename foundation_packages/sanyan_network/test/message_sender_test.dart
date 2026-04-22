import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:sanyan_network/sanyan_network.dart';

import 'support/fake_ws_client.dart';

/// Drain 所有 pending microtasks，确保 async broadcast 已 deliver。
Future<void> _flushMicrotasks() => Future<void>.delayed(Duration.zero);

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async => '/tmp');
    Get.reset();
    await GetStorage.init('sanyan_pending_test');
    await GetStorage('sanyan_pending_test').erase();
  });

  test('MessageSender can be constructed with dependencies', () {
    final ws = FakeWsClient();
    final sender = MessageSender(
      wsClient: ws,
      timeout: const Duration(milliseconds: 100),
      scanInterval: const Duration(milliseconds: 20),
    );
    expect(sender, isNotNull);
    expect(sender.getPending(1), isEmpty);
    ws.disposeForTest();
  });

  test('MessageSender.statusChanges is a broadcast stream', () {
    final ws = FakeWsClient();
    final sender = MessageSender(wsClient: ws);
    expect(sender.statusChanges, isA<Stream<PendingEntry>>());
    // broadcast 特性：允许多个 listener
    final sub1 = sender.statusChanges.listen((_) {});
    final sub2 = sender.statusChanges.listen((_) {});
    sub1.cancel();
    sub2.cancel();
    ws.disposeForTest();
  });

  test('getPending returns only entries for the requested conversation', () {
    // 这个测试此刻会走空流程（骨架还没 send 方法），但 API shape 必须正确
    final ws = FakeWsClient();
    final sender = MessageSender(wsClient: ws);
    expect(sender.getPending(1), isA<List<PendingEntry>>());
    expect(sender.getPending(1), isEmpty);
    ws.disposeForTest();
  });

  test('sendText: message enters pending, calls wsClient.sendMessage', () {
    final ws = FakeWsClient();
    final sender = MessageSender(
      wsClient: ws,
      timeout: const Duration(milliseconds: 500),
      scanInterval: const Duration(milliseconds: 50),
    );

    sender.sendText(
      conversationId: 1,
      clientMsgId: 'cid-1',
      messageJson: {
        'content': 'hi',
        'contentType': 'text',
        'clientMsgId': 'cid-1',
        'conversationId': 1,
        'status': 'sending',
      },
    );

    expect(sender.getPending(1), hasLength(1));
    expect(sender.getPending(1).first.clientMsgId, 'cid-1');
    expect(ws.sentTexts, hasLength(1));
    expect(ws.sentTexts.first['clientMsgId'], 'cid-1');
    expect(ws.sentTexts.first['content'], 'hi');

    ws.disposeForTest();
  });

  test('ACK: pending entry marked sent, removed, broadcasted', () async {
    final ws = FakeWsClient();
    final sender = MessageSender(
      wsClient: ws,
      timeout: const Duration(milliseconds: 500),
      scanInterval: const Duration(milliseconds: 50),
    );

    final changes = <PendingEntry>[];
    sender.statusChanges.listen(changes.add);

    sender.sendText(
      conversationId: 1,
      clientMsgId: 'cid-ack',
      messageJson: {
        'content': 'hi',
        'contentType': 'text',
        'clientMsgId': 'cid-ack',
        'conversationId': 1,
        'status': 'sending',
      },
    );

    ws.simulateAck('cid-ack');
    await Future.delayed(const Duration(milliseconds: 20));

    expect(sender.getPending(1), isEmpty);
    expect(changes, hasLength(1));
    expect(changes.first.messageJson['status'], 'sent');
    expect(changes.first.clientMsgId, 'cid-ack');

    ws.disposeForTest();
  });

  test('ACK for unknown clientMsgId: no pending change, no broadcast', () async {
    final ws = FakeWsClient();
    final sender = MessageSender(wsClient: ws);
    final changes = <PendingEntry>[];
    sender.statusChanges.listen(changes.add);

    ws.simulateAck('nonexistent-id');
    await Future.delayed(const Duration(milliseconds: 20));

    expect(changes, isEmpty);
    ws.disposeForTest();
  });

  test('timeout: pending message exceeding timeout is marked failed', () async {
    final ws = FakeWsClient();
    final sender = MessageSender(
      wsClient: ws,
      timeout: const Duration(milliseconds: 100),
      scanInterval: const Duration(milliseconds: 20),
    );
    final changes = <PendingEntry>[];
    sender.statusChanges.listen(changes.add);

    sender.sendText(
      conversationId: 1,
      clientMsgId: 'cid-timeout',
      messageJson: {
        'content': 'hi',
        'contentType': 'text',
        'clientMsgId': 'cid-timeout',
        'conversationId': 1,
        'status': MessageWireStatus.sending,
      },
    );

    // 等超过 timeout + 一轮 scan（scanInterval = 20ms）
    await Future.delayed(const Duration(milliseconds: 200));

    // failed 条目保留在 _pending 中等待 retry / removePending
    expect(sender.getPending(1), hasLength(1));
    expect(sender.getPending(1).first.messageJson['status'],
        MessageWireStatus.failed);
    // 没有 sending 条目了，scan Timer 应停
    expect(sender.isScanActive, isFalse);
    // failed 只应广播 1 次（不会每次 scan tick 重复广播）
    expect(changes, hasLength(1));
    expect(changes.first.messageJson['status'], MessageWireStatus.failed);
    expect(changes.first.clientMsgId, 'cid-timeout');

    ws.disposeForTest();
  });

  test('scan timer starts on sendText and stops when pending is emptied', () async {
    final ws = FakeWsClient();
    final sender = MessageSender(
      wsClient: ws,
      timeout: const Duration(milliseconds: 500),
      scanInterval: const Duration(milliseconds: 20),
    );
    final changes = <PendingEntry>[];
    sender.statusChanges.listen(changes.add);

    // 发一条 → Timer 应启动
    sender.sendText(
      conversationId: 1,
      clientMsgId: 'cid-lazy',
      messageJson: {
        'content': 'hi',
        'clientMsgId': 'cid-lazy',
        'conversationId': 1,
        'status': MessageWireStatus.sending,
      },
    );
    expect(sender.isScanActive, isTrue);

    // ACK 移除 → Timer 应停
    ws.simulateAck('cid-lazy');
    await Future.delayed(const Duration(milliseconds: 30));
    expect(sender.getPending(1), isEmpty);
    expect(sender.isScanActive, isFalse);

    // 只应广播 1 次（sent），不应该因为停掉的 timer 继续扫出 failed
    expect(changes, hasLength(1));
    expect(changes.first.messageJson['status'], MessageWireStatus.sent);

    // 再等更长时间，确保 timer 真停了（不会异步触发额外广播）
    await Future.delayed(const Duration(milliseconds: 80));
    expect(changes, hasLength(1));

    ws.disposeForTest();
  });

  test('disconnect: all pending messages marked failed, broadcast, retained for retry', () async {
    final ws = FakeWsClient();
    final sender = MessageSender(
      wsClient: ws,
      timeout: const Duration(seconds: 30),
      scanInterval: const Duration(seconds: 1),
    );
    final changes = <PendingEntry>[];
    sender.statusChanges.listen(changes.add);

    sender.sendText(
      conversationId: 1,
      clientMsgId: 'a',
      messageJson: {
        'content': 'x',
        'clientMsgId': 'a',
        'conversationId': 1,
        'status': MessageWireStatus.sending,
      },
    );
    sender.sendText(
      conversationId: 2, // 另一个会话
      clientMsgId: 'b',
      messageJson: {
        'content': 'y',
        'clientMsgId': 'b',
        'conversationId': 2,
        'status': MessageWireStatus.sending,
      },
    );

    expect(sender.getPending(1), hasLength(1));
    expect(sender.getPending(2), hasLength(1));
    expect(sender.isScanActive, isTrue);

    ws.simulateDisconnect();
    await Future.delayed(const Duration(milliseconds: 20));

    // failed 条目保留在 _pending（等待 retry/removePending），不清空
    expect(sender.getPending(1), hasLength(1));
    expect(sender.getPending(2), hasLength(1));
    expect(sender.getPending(1).first.messageJson['status'],
        MessageWireStatus.failed);
    expect(sender.getPending(2).first.messageJson['status'],
        MessageWireStatus.failed);
    expect(sender.isScanActive, isFalse); // Timer 也停了
    expect(changes, hasLength(2));
    for (final c in changes) {
      expect(c.messageJson['status'], MessageWireStatus.failed);
    }

    ws.disposeForTest();
  });

  test('disconnect with empty pending: no broadcast, no exception', () async {
    final ws = FakeWsClient();
    final sender = MessageSender(wsClient: ws);
    final changes = <PendingEntry>[];
    sender.statusChanges.listen(changes.add);

    ws.simulateDisconnect();
    await Future.delayed(const Duration(milliseconds: 20));

    expect(changes, isEmpty); // 没有 pending 就不该广播

    ws.disposeForTest();
  });

  test('persist: sendText writes pending to GetStorage', () async {
    final ws = FakeWsClient();
    final sender = MessageSender(
      wsClient: ws,
      timeout: const Duration(seconds: 30),
      scanInterval: const Duration(seconds: 1),
      boxName: 'sanyan_pending_test',
    );
    await sender.initAsync();

    sender.sendText(
      conversationId: 1,
      clientMsgId: 'persist-1',
      messageJson: {
        'content': 'hi',
        'clientMsgId': 'persist-1',
        'conversationId': 1,
        'status': MessageWireStatus.sending,
      },
    );

    final stored =
        GetStorage('sanyan_pending_test').read<List<dynamic>>('pending');
    expect(stored, isNotNull);
    expect(stored, hasLength(1));
    expect(stored!.first['clientMsgId'], 'persist-1');

    ws.disposeForTest();
  });

  test('persist: ACK removes entry from GetStorage', () async {
    final ws = FakeWsClient();
    final sender = MessageSender(
      wsClient: ws,
      boxName: 'sanyan_pending_test',
    );
    await sender.initAsync();

    sender.sendText(
      conversationId: 1,
      clientMsgId: 'persist-ack',
      messageJson: {
        'content': 'hi',
        'clientMsgId': 'persist-ack',
        'conversationId': 1,
        'status': MessageWireStatus.sending,
      },
    );
    ws.simulateAck('persist-ack');
    await Future.delayed(const Duration(milliseconds: 30));

    final stored =
        GetStorage('sanyan_pending_test').read<List<dynamic>>('pending');
    expect(stored ?? [], isEmpty);

    ws.disposeForTest();
  });

  test('sendVoice: enters pending, calls wsClient.sendVoiceMessage, starts scan timer', () {
    final ws = FakeWsClient();
    final sender = MessageSender(
      wsClient: ws,
      timeout: const Duration(seconds: 30),
      scanInterval: const Duration(seconds: 1),
    );

    sender.sendVoice(
      conversationId: 2,
      clientMsgId: 'voice-1',
      mediaUrl: 'https://cos/x.mp3',
      duration: 5,
      messageJson: {
        'content': '',
        'clientMsgId': 'voice-1',
        'conversationId': 2,
        'contentType': 'voice',
        'mediaUrl': 'https://cos/x.mp3',
        'duration': 5,
        'status': MessageWireStatus.sending,
      },
    );

    expect(sender.getPending(2), hasLength(1));
    expect(sender.isScanActive, isTrue);
    expect(ws.sentVoices, hasLength(1));
    expect(ws.sentVoices.first['clientMsgId'], 'voice-1');
    expect(ws.sentVoices.first['mediaUrl'], 'https://cos/x.mp3');
    expect(ws.sentVoices.first['duration'], 5);

    ws.disposeForTest();
  });

  test('retry text: re-enters sending with fresh sendTime and calls wsClient.sendMessage', () async {
    final ws = FakeWsClient();
    final sender = MessageSender(
      wsClient: ws,
      timeout: const Duration(milliseconds: 100),
      scanInterval: const Duration(milliseconds: 20),
    );
    final changes = <PendingEntry>[];
    sender.statusChanges.listen(changes.add);

    sender.sendText(
      conversationId: 1,
      clientMsgId: 'retry-t',
      messageJson: {
        'content': 'x',
        'clientMsgId': 'retry-t',
        'conversationId': 1,
        'contentType': 'text',
        'status': MessageWireStatus.sending,
      },
    );
    // 等超时
    await Future.delayed(const Duration(milliseconds: 200));
    expect(sender.getPending(1).first.messageJson['status'], MessageWireStatus.failed);
    changes.clear(); // 只观察 retry 后的广播

    final failedEntry = sender.getPending(1).first;
    final oldSendTime = failedEntry.sendTimeMs;

    sender.retry(failedEntry);

    await _flushMicrotasks();

    expect(sender.getPending(1), hasLength(1));
    expect(sender.getPending(1).first.messageJson['status'], MessageWireStatus.sending);
    // sendTimeMs 被刷新（>= 原值；ms 精度可能相等，但不允许倒退）
    expect(sender.getPending(1).first.sendTimeMs, greaterThanOrEqualTo(oldSendTime));
    expect(ws.sentTexts, hasLength(2)); // 第一次 + 重试
    expect(ws.sentTexts.last['clientMsgId'], 'retry-t');
    expect(changes, hasLength(1));
    expect(changes.first.messageJson['status'], MessageWireStatus.sending);

    ws.disposeForTest();
  });

  test('retry voice: dispatches to wsClient.sendVoiceMessage by contentType', () async {
    final ws = FakeWsClient();
    final sender = MessageSender(
      wsClient: ws,
      timeout: const Duration(milliseconds: 100),
      scanInterval: const Duration(milliseconds: 20),
    );

    sender.sendVoice(
      conversationId: 1,
      clientMsgId: 'retry-v',
      mediaUrl: 'https://cos/y.mp3',
      duration: 3,
      messageJson: {
        'content': '',
        'clientMsgId': 'retry-v',
        'conversationId': 1,
        'contentType': 'voice',
        'mediaUrl': 'https://cos/y.mp3',
        'duration': 3,
        'status': MessageWireStatus.sending,
      },
    );
    await Future.delayed(const Duration(milliseconds: 200));
    expect(sender.getPending(1).first.messageJson['status'], MessageWireStatus.failed);

    sender.retry(sender.getPending(1).first);

    await _flushMicrotasks();

    expect(sender.getPending(1).first.messageJson['status'], MessageWireStatus.sending);
    expect(ws.sentVoices, hasLength(2));
    expect(ws.sentVoices.last['mediaUrl'], 'https://cos/y.mp3');

    ws.disposeForTest();
  });

  test('removePending: entry removed, stops scan timer if last one', () {
    final ws = FakeWsClient();
    final sender = MessageSender(
      wsClient: ws,
      boxName: 'sanyan_pending_test',
    );

    sender.sendText(
      conversationId: 1,
      clientMsgId: 'rm-1',
      messageJson: {
        'content': 'x',
        'clientMsgId': 'rm-1',
        'conversationId': 1,
        'contentType': 'text',
        'status': MessageWireStatus.sending,
      },
    );
    expect(sender.isScanActive, isTrue);

    sender.removePending('rm-1');

    expect(sender.getPending(1), isEmpty);
    expect(sender.isScanActive, isFalse);

    ws.disposeForTest();
  });

  test('removePending unknown id: no-op', () {
    final ws = FakeWsClient();
    final sender = MessageSender(wsClient: ws);

    expect(() => sender.removePending('never-existed'), returnsNormally);

    ws.disposeForTest();
  });

  test('cold start: pending with sending status loaded as failed', () async {
    // 第一个 sender 写入一条 sending 消息并持久化
    final ws1 = FakeWsClient();
    final sender1 = MessageSender(
      wsClient: ws1,
      boxName: 'sanyan_pending_test',
    );
    await sender1.initAsync();
    sender1.sendText(
      conversationId: 1,
      clientMsgId: 'cold-start-1',
      messageJson: {
        'content': 'x',
        'clientMsgId': 'cold-start-1',
        'conversationId': 1,
        'status': MessageWireStatus.sending,
      },
    );
    sender1.onClose();
    ws1.disposeForTest();

    // 第二个 sender 从 disk 恢复（模拟冷启）
    final ws2 = FakeWsClient();
    final sender2 = MessageSender(
      wsClient: ws2,
      boxName: 'sanyan_pending_test',
    );
    await sender2.initAsync();

    final pending = sender2.getPending(1);
    expect(pending, hasLength(1));
    expect(pending.first.clientMsgId, 'cold-start-1');
    // 冷启后 sending 立即转 failed（Timer/socket 没了，没指望被 ACK）
    expect(pending.first.messageJson['status'], MessageWireStatus.failed);

    ws2.disposeForTest();
  });
}
