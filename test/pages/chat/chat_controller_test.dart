import 'package:flutter_test/flutter_test.dart';
import 'package:sanyan_app/models/message.dart';

void main() {
  test('should insert message in order', () {
    final messages = <Message>[];

    final msg1 = Message(
      id: 1,
      conversationId: 1,
      senderType: 'user',
      contentType: 'text',
      content: '你好',
      source: 'reply',
      createdAt: '2026-04-07 20:00:00',
    );
    final msg2 = Message(
      id: 2,
      conversationId: 1,
      senderType: 'ai',
      contentType: 'text',
      content: '你好呀',
      source: 'reply',
      createdAt: '2026-04-07 20:00:05',
    );

    messages.add(msg1);
    messages.add(msg2);

    expect(messages.length, 2);
    expect(messages.last.senderType, 'ai');
  });

  test('should detect ai message via isFromAi', () {
    final msg = Message(
      id: 1,
      conversationId: 1,
      senderType: 'ai',
      contentType: 'text',
      content: '你好',
      source: 'reply',
      createdAt: '2026-04-07 20:00:00',
    );
    expect(msg.isFromAi, true);
  });

  test('should detect user message via isFromAi', () {
    final msg = Message(
      id: 1,
      conversationId: 1,
      senderType: 'user',
      contentType: 'text',
      content: '你好',
      source: 'reply',
      createdAt: '2026-04-07 20:00:00',
    );
    expect(msg.isFromAi, false);
  });

  test('should detect proactive message', () {
    final msg = Message(
      id: 1,
      conversationId: 1,
      senderType: 'ai',
      contentType: 'text',
      content: '想你了',
      source: 'proactive',
      createdAt: '2026-04-07 20:00:00',
    );
    expect(msg.isProactive, true);
  });
}
