import 'package:flutter_test/flutter_test.dart';
import 'package:sanyan_network/sanyan_network.dart';

void main() {
  test('PendingEntry construction + field access', () {
    final entry = PendingEntry(
      clientMsgId: 'abc-123',
      conversationId: 42,
      sendTimeMs: 1700000000000,
      messageJson: {'content': '你好', 'contentType': 'text'},
    );
    expect(entry.clientMsgId, 'abc-123');
    expect(entry.conversationId, 42);
    expect(entry.sendTimeMs, 1700000000000);
    expect(entry.messageJson['content'], '你好');
  });

  test('PendingEntry.toJson serializes all fields', () {
    final entry = PendingEntry(
      clientMsgId: 'abc-123',
      conversationId: 42,
      sendTimeMs: 1700000000000,
      messageJson: {'content': '你好'},
    );
    final json = entry.toJson();
    expect(json['clientMsgId'], 'abc-123');
    expect(json['conversationId'], 42);
    expect(json['sendTimeMs'], 1700000000000);
    expect(json['message'], {'content': '你好'});
  });

  test('PendingEntry.fromJson roundtrip', () {
    final entry = PendingEntry(
      clientMsgId: 'abc-123',
      conversationId: 42,
      sendTimeMs: 1700000000000,
      messageJson: {'content': '你好', 'n': 7},
    );
    final back = PendingEntry.fromJson(entry.toJson());
    expect(back.clientMsgId, entry.clientMsgId);
    expect(back.conversationId, entry.conversationId);
    expect(back.sendTimeMs, entry.sendTimeMs);
    expect(back.messageJson, entry.messageJson);
  });

  test('PendingEntry.fromJson handles nested Map from dynamic storage', () {
    // GetStorage 存回来的 Map 类型是 Map<dynamic, dynamic>，
    // fromJson 必须能正确转成 Map<String, dynamic>
    final raw = <String, dynamic>{
      'clientMsgId': 'x',
      'conversationId': 1,
      'sendTimeMs': 100,
      'message': <dynamic, dynamic>{'content': 'hi'},
    };
    final entry = PendingEntry.fromJson(raw);
    expect(entry.messageJson['content'], 'hi');
    expect(entry.messageJson, isA<Map<String, dynamic>>());
  });
}
