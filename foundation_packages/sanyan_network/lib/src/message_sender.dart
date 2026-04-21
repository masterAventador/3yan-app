import 'dart:async';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'message_wire_status.dart';
import 'pending_entry.dart';
import 'ws_client.dart';
import 'ws_event_type.dart';

/// 跨 ChatController 生命周期的消息发送管理器（GetxService 单例）。
///
/// 职责：
/// - 所有 pending 消息的追踪（Map<clientMsgId, PendingEntry>）
/// - 超时检测（1 个周期扫描 Timer，懒启动）
/// - ACK / 断线事件处理
/// - 本地持久化（GetStorage，App 冷启恢复）
/// - 统一 retry 入口
///
/// 单例注册方式（由 `main.dart` 在启动流程里完成）：
/// ```dart
/// final sender = MessageSender(wsClient: wsClient);
/// await sender.initAsync(); // T10 会加，冷启加载 pending
/// Get.put<MessageSender>(sender, permanent: true);
/// ```
///
/// 测试时直接构造（skip GetxService 生命周期 onInit），
/// 传入 FakeWsClient + 短 timeout/scanInterval。
///
/// T6 skeleton 说明：仅建立 API shape（getPending + statusChanges）
/// 和 onClose 清理；ACK / timeout / disconnect / 持久化 / retry 由后续
/// task（T7-T11）逐步追加。
class MessageSender extends GetxService {
  final WsClient _wsClient;
  final Duration _timeout;
  final Duration _scanInterval;
  final String _boxName;
  GetStorage? _box;
  static const _storeKey = 'pending';

  final Map<String, PendingEntry> _pending = {};
  Timer? _scanTimer;
  StreamSubscription<WsEvent>? _wsEventSub;
  StreamSubscription<void>? _wsDisconnectSub;

  final StreamController<PendingEntry> _statusChangesController =
      StreamController<PendingEntry>.broadcast();

  /// 状态变化事件流：Sender 更新了某条消息的 status（sent / failed）后广播。
  /// ChatController 订阅并刷新 messages 列表。
  Stream<PendingEntry> get statusChanges => _statusChangesController.stream;

  MessageSender({
    required WsClient wsClient,
    Duration timeout = const Duration(seconds: 30),
    Duration scanInterval = const Duration(seconds: 1),
    String boxName = 'sanyan_pending',
  })  : _wsClient = wsClient,
        _timeout = timeout,
        _scanInterval = scanInterval,
        _boxName = boxName {
    _wsEventSub = _wsClient.eventStream.listen(_onWsEvent);
    _wsDisconnectSub = _wsClient.onDisconnected.listen(_onDisconnected);
  }

  /// 冷启加载。main.dart onInit 里 await 它，保证 GetStorage 初始化 +
  /// pending 加载完毕再启路由。
  Future<void> initAsync() async {
    await GetStorage.init(_boxName);
    _box = GetStorage(_boxName);
    _loadFromDisk();
  }

  void _loadFromDisk() {
    final raw = _box?.read<List<dynamic>>(_storeKey);
    if (raw == null) return;
    for (final item in raw) {
      final entry =
          PendingEntry.fromJson(Map<String, dynamic>.from(item as Map));
      // 冷启 sending 状态立即转 failed——timer 和 socket 都随进程消亡，
      // 等不到 ACK 了。客户端按 failed 展示感叹号可重试。
      if (entry.messageJson['status'] == MessageWireStatus.sending) {
        entry.messageJson['status'] = MessageWireStatus.failed;
      }
      _pending[entry.clientMsgId] = entry;
    }
  }

  void _persist() {
    // 初始化前的调用（理论上不应该发生，但防御一下）
    if (_box == null) return;
    _box!.write(
      _storeKey,
      _pending.values.map((e) => e.toJson()).toList(),
    );
  }

  /// 取指定会话的所有 pending 条目（包含 sending 和 failed 状态）。
  /// ChatController onInit 时调用这个合并到 messages 列表。
  List<PendingEntry> getPending(int conversationId) {
    return _pending.values
        .where((e) => e.conversationId == conversationId)
        .toList();
  }

  @visibleForTesting
  bool get isScanActive => _scanTimer != null;

  /// 发送文本消息：把消息加入 pending 队列 + 调 WsClient.sendMessage。
  /// ACK / 超时 / 断线 后续由 eventStream 订阅 + 周期扫描处理。
  void sendText({
    required int conversationId,
    required String clientMsgId,
    required Map<String, dynamic> messageJson,
  }) {
    final entry = PendingEntry(
      clientMsgId: clientMsgId,
      conversationId: conversationId,
      sendTimeMs: DateTime.now().millisecondsSinceEpoch,
      // 浅拷贝够用：messageJson 字段都是扁平 primitive（content/status/
      // clientMsgId/conversationId），没有嵌套 Map。
      messageJson: Map<String, dynamic>.from(messageJson),
    );
    _pending[clientMsgId] = entry;
    _wsClient.sendMessage(
      conversationId: conversationId,
      content: messageJson['content'] as String,
      clientMsgId: clientMsgId,
    );
    _ensureScanTimer();
    _persist();
  }

  void _onWsEvent(WsEvent event) {
    if (event.type == WsEventType.ack) {
      _handleAck(event.clientMsgId);
    }
  }

  void _handleAck(String? clientMsgId) {
    if (clientMsgId == null) return;
    final entry = _pending.remove(clientMsgId);
    if (entry == null) return;
    entry.messageJson['status'] = MessageWireStatus.sent;
    _statusChangesController.add(entry);
    _persist();
    _stopScanTimerIfEmpty();
  }

  void _onDisconnected(void _) {
    if (_pending.isEmpty) return;
    final entries = _pending.values.toList();
    _pending.clear();
    for (final entry in entries) {
      entry.messageJson['status'] = MessageWireStatus.failed;
      _statusChangesController.add(entry);
    }
    _scanTimer?.cancel();
    _scanTimer = null;
    _persist();
  }

  void _ensureScanTimer() {
    _scanTimer ??= Timer.periodic(_scanInterval, (_) => _scan());
  }

  void _stopScanTimerIfEmpty() {
    if (_pending.isEmpty) {
      _scanTimer?.cancel();
      _scanTimer = null;
    }
  }

  void _scan() {
    // 两阶段扫描：先收集 expired ids 再 remove + 广播，
    // 避免迭代 _pending.values 时修改 _pending 触发 ConcurrentModificationError。
    final now = DateTime.now().millisecondsSinceEpoch;
    final expiredIds = <String>[];
    for (final entry in _pending.values) {
      if (now - entry.sendTimeMs > _timeout.inMilliseconds) {
        expiredIds.add(entry.clientMsgId);
      }
    }
    for (final id in expiredIds) {
      final entry = _pending.remove(id);
      if (entry != null) {
        entry.messageJson['status'] = MessageWireStatus.failed;
        _statusChangesController.add(entry);
      }
    }
    if (expiredIds.isNotEmpty) {
      _persist();
    }
    _stopScanTimerIfEmpty();
  }

  @override
  void onClose() {
    _scanTimer?.cancel();
    _wsEventSub?.cancel();
    _wsDisconnectSub?.cancel();
    _statusChangesController.close();
    super.onClose();
  }
}
