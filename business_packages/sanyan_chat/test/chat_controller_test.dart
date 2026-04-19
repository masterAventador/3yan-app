import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sanyan_chat/sanyan_chat.dart';
import 'package:sanyan_network/sanyan_network.dart';
import 'package:sanyan_user/sanyan_user.dart';

// Fake WsClient —— 避免走真实网络/lifecycle。
// 不用 mocktail 是因为 WsClient 继承自 GetxService，Get.put 时会触发 onStart，
// Mock 对象的 onStart 返回 null 而签名期望 InternalFinalCallback<void>，会抛类型错。
class _FakeWsClient extends WsClient {
  @override
  Stream<WsEvent> get eventStream => const Stream.empty();
}

class _MockRecorder extends Mock implements IVoiceRecorder {}

Conversation _fixtureConv() => Conversation(
      id: 1,
      characterId: 100,
      characterName: 'A',
      unreadCount: 0,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
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

  group('ChatController.inputMode', () {
    setUpAll(() async {
      // get_storage 底层依赖 path_provider，测试环境下需要 mock 其 platform channel。
      final tmp = await Directory.systemTemp.createTemp('gs_test_');
      const channel = MethodChannel('plugins.flutter.io/path_provider');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async => tmp.path);
      await LocalStorage.init();
    });

    tearDown(Get.reset);

    test('initial inputMode reads from storage', () {
      Get.put<WsClient>(_FakeWsClient());
      final c = ChatController(
        _fixtureConv(),
        recorder: _MockRecorder(),
      );
      expect(c.inputMode.value, isA<ChatInputMode>());
    });

    test('toggleInputMode flips between keyboard and voice', () {
      Get.put<WsClient>(_FakeWsClient());
      final c = ChatController(
        _fixtureConv(),
        recorder: _MockRecorder(),
      );
      final before = c.inputMode.value;
      c.toggleInputMode();
      expect(c.inputMode.value, isNot(before));
      c.toggleInputMode();
      expect(c.inputMode.value, before);
    });
  });
}
