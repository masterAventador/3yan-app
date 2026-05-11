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
  /// 超时判定基于 Message.createdAt（发消息时记录）。
  final _pending = <String, Message>{};

  /// 单 Timer 周期扫描 _pending，超时（10s 未收到 ack）的整体标 failed。
  /// _pending 非空时懒启动；空了自动停。每发一条消息开 N 个 Timer 太重，
  /// 单 Timer 扫描精度损失最多一个扫描周期（2s）—— 对聊天体感差几秒无感。
  Timer? _scanTimer;
  static const _sendTimeout = Duration(seconds: 10);
  static const _scanInterval = Duration(seconds: 2);

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
            _stopScanIfIdle();
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

  /// 真正向 WS 投递。失败立即标 failed；成功则确保扫描 Timer 在跑（等 ack 或超时）。
  void _dispatchSend(String clientMsgId, String content) {
    final ok = Get.find<WsClient>().sendMessage(content: content, clientMsgId: clientMsgId);
    if (!ok) {
      // WS 断开 / 写入失败：立即标 failed，等用户点重试
      _markFailed(clientMsgId);
      return;
    }
    // sink.add 成功不代表 server 真收到。让扫描 Timer 在背景检测超时。
    _ensureScanTimer();
  }

  void _markFailed(String clientMsgId) {
    final msg = _pending.remove(clientMsgId);
    if (msg != null) {
      msg.status = MessageStatus.failed;
      messages.refresh();
    }
    _stopScanIfIdle();
  }

  /// _pending 非空且 Timer 未跑时启动周期扫描。已在跑就不重复启。
  void _ensureScanTimer() {
    if (_scanTimer != null) return;
    if (_pending.isEmpty) return;
    _scanTimer = Timer.periodic(_scanInterval, (_) => _scanTimeouts());
  }

  /// _pending 空了就停 Timer，避免空转省电。
  void _stopScanIfIdle() {
    if (_pending.isEmpty) {
      _scanTimer?.cancel();
      _scanTimer = null;
    }
  }

  /// 扫一遍 _pending，把发送时间超过 _sendTimeout 的标 failed。
  void _scanTimeouts() {
    if (_pending.isEmpty) {
      _stopScanIfIdle();
      return;
    }
    final now = DateTime.now();
    final timedOut = <String>[];
    for (final entry in _pending.entries) {
      final sentAt = DateTime.tryParse(entry.value.createdAt);
      if (sentAt != null && now.difference(sentAt) > _sendTimeout) {
        timedOut.add(entry.key);
      }
    }
    for (final clientMsgId in timedOut) {
      _markFailed(clientMsgId);
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
    _scanTimer?.cancel();
    _scanTimer = null;
    inputController.dispose();
    scrollController.dispose();
    super.onClose();
  }
}
