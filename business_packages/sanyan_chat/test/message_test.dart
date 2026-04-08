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
}
