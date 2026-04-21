import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:sanyan_network/sanyan_network.dart';

import 'support/fake_ws_client.dart';

void main() {
  setUp(() {
    Get.reset();
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
}
