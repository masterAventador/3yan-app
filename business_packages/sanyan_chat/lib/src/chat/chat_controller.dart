import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sanyan_network/sanyan_network.dart';
import 'package:uuid/uuid.dart';
import '../api/chat_api.dart';
import '../api/models/message.dart';
import '../api/models/message_status.dart';

class ChatController extends GetxController {
  final messages = <Message>[].obs;
  final isLoading = true.obs;
  final isAiTyping = false.obs;
  final inputController = TextEditingController();
  final scrollController = ScrollController();
  StreamSubscription? _wsSub;
  static const _uuid = Uuid();

  /// 跟踪 sending 消息：clientMsgId → temp Message。ack 后从此 Map 找回来标 sent。
  final _pending = <String, Message>{};

  /// 每条 sending 消息的超时计时器（clientMsgId → Timer），
  /// 收到 ack 取消，超时未 ack 自动标 failed。
  final _timeouts = <String, Timer>{};
  static const _sendTimeout = Duration(seconds: 10);

  @override
  void onInit() {
    super.onInit();
    _loadHistory();
    _listenWs();
  }

  Future<void> _loadHistory() async {
    try {
      final resp = await ChatApi.listMessages();
      if (resp.success && resp.data != null) {
        messages.value = resp.data!;
      }
    } finally {
      isLoading.value = false;
      _scrollToBottom();
    }
  }

  void _listenWs() {
    _wsSub = Get.find<WsClient>().eventStream.listen((event) {
      switch (event.type) {
        case WsEventType.ack:
          if (event.clientMsgId != null) {
            _timeouts.remove(event.clientMsgId)?.cancel();
            final msg = _pending.remove(event.clientMsgId);
            if (msg != null) {
              // 用 server 落库的真实 id 替换本地临时 id，避免 cold start sync
              // 拉历史时同一条 user 消息因 id 不同显示两遍
              if (event.serverMsgId != null) {
                msg.id = event.serverMsgId!;
              }
              msg.status = MessageStatus.sent;
              messages.refresh();
            }
          }
          break;
        case WsEventType.typing:
          isAiTyping.value = true;
          break;
        case WsEventType.newMessage:
          isAiTyping.value = false;
          if (event.message != null) {
            messages.add(Message.fromJson(event.message!));
            _scrollToBottom();
          }
          break;
        case WsEventType.syncResult:
          if (event.messages != null) {
            for (final m in event.messages!) {
              final msg = Message.fromJson(m as Map<String, dynamic>);
              if (!messages.any((x) => x.id == msg.id)) {
                messages.add(msg);
              }
            }
            // 按 createdAt 时间序排序（ISO 8601 字符串字典序 == 时间序）。
            // 不能按 id 排——因为 sending/failed 临时消息的 id 跟 server 端
            // 已 ack 消息的 id 不可比（用户视觉时间和 server 落库顺序不一定一致）。
            messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
            _scrollToBottom();
          }
          break;
      }
    });
  }

  /// 临时消息 id 用大正数（1e15 + timestamp），确保按 id 排序时仍排在末尾，
  /// 不会被排到列表顶部消失在用户视野外。收到 ack 后会被 serverMsgId 替换为真实小数。
  static const int _tempIdBase = 1000000000000000;

  int _nextTempId() => _tempIdBase + DateTime.now().millisecondsSinceEpoch;

  void sendMessage() {
    final text = inputController.text.trim();
    if (text.isEmpty) return;
    final clientMsgId = _uuid.v4();
    final tempMsg = Message(
      id: _nextTempId(),
      senderType: SenderType.user,
      content: text,
      createdAt: DateTime.now().toIso8601String(),
      clientMsgId: clientMsgId,
      status: MessageStatus.sending,
    );
    _pending[clientMsgId] = tempMsg;
    messages.add(tempMsg);
    _dispatchSend(clientMsgId, text);
    inputController.clear();
    _scrollToBottom();
  }

  void retryMessage(Message msg) {
    if (msg.clientMsgId == null) return;
    msg.status = MessageStatus.sending;
    messages.refresh();
    _pending[msg.clientMsgId!] = msg;
    _dispatchSend(msg.clientMsgId!, msg.content);
  }

  /// 真正向 WS 投递 + 启动超时计时。失败立即标 failed，成功启动 10s timer 等 ack。
  void _dispatchSend(String clientMsgId, String content) {
    final ok = Get.find<WsClient>().sendMessage(content: content, clientMsgId: clientMsgId);
    if (!ok) {
      // WS 断开 / 写入失败：立即标 failed，等用户点重试
      _markFailed(clientMsgId);
      return;
    }
    // sink.add 成功不代表 server 真收到（可能 sink 已写但 server 没处理就断）。
    // 启动 10s 超时，超时还没收到 ack 就当失败。
    _timeouts[clientMsgId] = Timer(_sendTimeout, () => _markFailed(clientMsgId));
  }

  void _markFailed(String clientMsgId) {
    _timeouts.remove(clientMsgId)?.cancel();
    final msg = _pending.remove(clientMsgId);
    if (msg != null) {
      msg.status = MessageStatus.failed;
      messages.refresh();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void onClose() {
    _wsSub?.cancel();
    for (final t in _timeouts.values) {
      t.cancel();
    }
    _timeouts.clear();
    inputController.dispose();
    scrollController.dispose();
    super.onClose();
  }
}
