import 'dart:async';
import 'package:get/get.dart';
import 'pending_entry.dart';
import 'ws_client.dart';

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

  final Map<String, PendingEntry> _pending = {};
  Timer? _scanTimer;

  final StreamController<PendingEntry> _statusChangesController =
      StreamController<PendingEntry>.broadcast();

  /// 状态变化事件流：Sender 更新了某条消息的 status（sent / failed）后广播。
  /// ChatController 订阅并刷新 messages 列表。
  Stream<PendingEntry> get statusChanges => _statusChangesController.stream;

  MessageSender({
    required WsClient wsClient,
    Duration timeout = const Duration(seconds: 30),
    Duration scanInterval = const Duration(seconds: 1),
  })  : _wsClient = wsClient,
        _timeout = timeout,
        _scanInterval = scanInterval;

  /// 取指定会话的所有 pending 条目（包含 sending 和 failed 状态）。
  /// ChatController onInit 时调用这个合并到 messages 列表。
  List<PendingEntry> getPending(int conversationId) {
    return _pending.values
        .where((e) => e.conversationId == conversationId)
        .toList();
  }

  @override
  void onClose() {
    _scanTimer?.cancel();
    _statusChangesController.close();
    super.onClose();
  }
}
