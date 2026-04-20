import 'package:flutter_test/flutter_test.dart';
import 'package:sanyan_chat/sanyan_chat.dart';

void main() {
  test('should parse message from json', () {
    final json = {
      'id': 1,
      'conversationId': 100,
      'senderType': 'ai',
      'contentType': 'text',
      'content': '你好呀',
      'source': 'reply',
      'createdAt': '2026-04-07 20:30:15',
    };

    final msg = Message.fromJson(json);
    expect(msg.id, 1);
    expect(msg.senderType, 'ai');
    expect(msg.content, '你好呀');
    expect(msg.isFromAi, true);
  });

  test('should detect proactive message', () {
    final msg = Message.fromJson({
      'id': 2,
      'conversationId': 100,
      'senderType': 'ai',
      'contentType': 'text',
      'content': '在干嘛呢',
      'source': 'proactive',
      'createdAt': '2026-04-07 20:30:15',
    });

    expect(msg.isProactive, true);
  });

  test('should parse fallbackReason from json', () {
    final msg = Message.fromJson({
      'id': 3,
      'conversationId': 100,
      'senderType': 'ai',
      'contentType': 'text',
      'content': '嗯嗯',
      'source': 'reply',
      'createdAt': '2026-04-21 00:00:00',
      'fallbackReason': 'asr_failed',
    });

    expect(msg.fallbackReason, 'asr_failed');
  });

  test('fallbackReason is null when absent from json (normal reply)', () {
    final msg = Message.fromJson({
      'id': 4,
      'conversationId': 100,
      'senderType': 'ai',
      'contentType': 'text',
      'content': '你好呀',
      'source': 'reply',
      'createdAt': '2026-04-21 00:00:00',
    });

    expect(msg.fallbackReason, isNull);
  });

  test('toJson includes fallbackReason', () {
    final msg = Message(
      id: 5,
      conversationId: 100,
      senderType: 'ai',
      contentType: 'text',
      content: '嗯嗯',
      source: 'reply',
      createdAt: '2026-04-21 00:00:00',
      fallbackReason: 'tts_failed',
    );

    expect(msg.toJson()['fallbackReason'], 'tts_failed');
  });
}
