import 'dart:async';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'content_type.dart';
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

  // sync: true → 订阅者能在同一 tick 内看到 retry / ack / timeout 等状态变化，
  // 避免依赖 microtask 调度顺序（测试和 ChatController 监听都不需要异步 gap）。
  final StreamController<PendingEntry> _statusChangesController =
      StreamController<PendingEntry>.broadcast(sync: true);

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

  /// 发送语音消息：和 sendText 对称，把语音消息加入 pending 队列 +
  /// 调 WsClient.sendVoiceMessage。ACK/超时/断线 路径和文本消息一致。
  void sendVoice({
    required int conversationId,
    required String clientMsgId,
    required String mediaUrl,
    required int duration,
    required Map<String, dynamic> messageJson,
  }) {
    final entry = PendingEntry(
      clientMsgId: clientMsgId,
      conversationId: conversationId,
      sendTimeMs: DateTime.now().millisecondsSinceEpoch,
      // 浅拷贝够用：messageJson 字段都是扁平 primitive。
      messageJson: Map<String, dynamic>.from(messageJson),
    );
    _pending[clientMsgId] = entry;
    _wsClient.sendVoiceMessage(
      conversationId: conversationId,
      mediaUrl: mediaUrl,
      duration: duration,
      clientMsgId: clientMsgId,
    );
    _ensureScanTimer();
    _persist();
  }

  /// 重试一条 failed 的消息。保留 clientMsgId，刷新 sendTimeMs，按
  /// messageJson['contentType'] 分派到 WsClient 对应 send 方法。
  /// 广播 statusChanges 让 UI 切换回 sending 展示。
  void retry(PendingEntry entry) {
    final contentType = entry.messageJson['contentType'] as String?;
    final refreshed = PendingEntry(
      clientMsgId: entry.clientMsgId,
      conversationId: entry.conversationId,
      sendTimeMs: DateTime.now().millisecondsSinceEpoch,
      messageJson: Map<String, dynamic>.from(entry.messageJson),
    );
    refreshed.messageJson['status'] = MessageWireStatus.sending;
    _pending[entry.clientMsgId] = refreshed;

    if (contentType == ContentType.voice) {
      _wsClient.sendVoiceMessage(
        conversationId: entry.conversationId,
        mediaUrl: entry.messageJson['mediaUrl'] as String,
        duration: entry.messageJson['duration'] as int,
        clientMsgId: entry.clientMsgId,
      );
    } else {
      _wsClient.sendMessage(
        conversationId: entry.conversationId,
        content: entry.messageJson['content'] as String,
        clientMsgId: entry.clientMsgId,
      );
    }

    _ensureScanTimer();
    _statusChangesController.add(refreshed);
    _persist();
  }

  /// 彻底从 pending 队列移除一条消息。ChatController 在用户主动“删掉
  /// 失败消息”的交互里调（当前 UI 不暴露，留 API 给未来）。
  void removePending(String clientMsgId) {
    final removed = _pending.remove(clientMsgId);
    if (removed == null) return;
    _stopScanTimerIfNoSending();
    _persist();
  }

  void _onWsEvent(WsEvent event) {
    if (event.type == WsEventType.ack) {
      _handleAck(event.clientMsgId);
    }
  }

  void _handleAck(String? clientMsgId) {
    if (clientMsgId == null) return;
    // ACK 代表消息已经成功入库，从 pending 移除（它会进入正式消息列表）。
    final entry = _pending.remove(clientMsgId);
    if (entry == null) return;
    entry.messageJson['status'] = MessageWireStatus.sent;
    _statusChangesController.add(entry);
    _persist();
    _stopScanTimerIfNoSending();
  }

  void _onDisconnected(void _) {
    // 断线时把所有 sending 状态条目批量翻成 failed。保留条目在 _pending，
    // 等待用户 retry 或 removePending。
    final sendingEntries = _pending.values
        .where((e) => e.messageJson['status'] == MessageWireStatus.sending)
        .toList();
    if (sendingEntries.isEmpty) return;
    for (final entry in sendingEntries) {
      entry.messageJson['status'] = MessageWireStatus.failed;
      _statusChangesController.add(entry);
    }
    // 剩下的都是 failed，scan 没事干了。
    _scanTimer?.cancel();
    _scanTimer = null;
    _persist();
  }

  void _ensureScanTimer() {
    _scanTimer ??= Timer.periodic(_scanInterval, (_) => _scan());
  }

  /// 当 _pending 中已无 sending 状态条目（全是 failed 或空），停扫描 Timer。
  /// failed 条目留着等 retry / removePending，不需要 Timer 轮询。
  void _stopScanTimerIfNoSending() {
    final hasSending = _pending.values
        .any((e) => e.messageJson['status'] == MessageWireStatus.sending);
    if (!hasSending) {
      _scanTimer?.cancel();
      _scanTimer = null;
    }
  }

  void _scan() {
    // 超时扫描：只处理 sending 条目，翻成 failed 后保留在 _pending 中
    // 等待 retry / removePending。避免迭代时修改 map，先收集 ids 再改。
    final now = DateTime.now().millisecondsSinceEpoch;
    final expiredIds = <String>[];
    for (final entry in _pending.values) {
      if (entry.messageJson['status'] != MessageWireStatus.sending) continue;
      if (now - entry.sendTimeMs > _timeout.inMilliseconds) {
        expiredIds.add(entry.clientMsgId);
      }
    }
    for (final id in expiredIds) {
      final entry = _pending[id];
      if (entry != null) {
        entry.messageJson['status'] = MessageWireStatus.failed;
        _statusChangesController.add(entry);
      }
    }
    if (expiredIds.isNotEmpty) {
      _persist();
    }
    _stopScanTimerIfNoSending();
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
