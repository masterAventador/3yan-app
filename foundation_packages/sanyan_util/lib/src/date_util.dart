/// 日期/时间格式化工具。
///
/// 按 ~/.claude/CLAUDE.md "static 优先原则"：abstract class + 全 static 方法。
abstract class DateUtil {
  /// 把 ISO 8601 字符串格式化为本地时区 HH:mm。
  ///
  /// - null / 空串 / 解析失败 → 返回 ""
  /// - 合法 ISO 8601 → 转本地时区后取 hour:minute，左补 0 至 2 位
  static String formatHHmm(String? iso8601) {
    if (iso8601 == null || iso8601.isEmpty) return '';
    try {
      return _hhmm(DateTime.parse(iso8601).toLocal());
    } catch (_) {
      return '';
    }
  }

  /// 把 ISO 8601 字符串格式化为聊天气泡时间戳（智能相对格式）。
  ///
  /// 相对 [now]（默认当前时刻），统一转本地时区后判断：
  /// - null / 空串 / 解析失败 → ''
  /// - 今天 → 'HH:mm'
  /// - 昨天 → '昨天 HH:mm'
  /// - 今年内更早 → 'M月d日 HH:mm'（日期部分不补 0）
  /// - 更早的年份 → 'yyyy年M月d日 HH:mm'
  static String formatChatTimestamp(String? iso8601, {DateTime? now}) {
    if (iso8601 == null || iso8601.isEmpty) return '';
    try {
      final dt = DateTime.parse(iso8601).toLocal();
      final ref = (now ?? DateTime.now()).toLocal();
      final time = _hhmm(dt);

      final dtDay = DateTime(dt.year, dt.month, dt.day);
      final today = DateTime(ref.year, ref.month, ref.day);
      final diffDays = today.difference(dtDay).inDays;

      if (diffDays == 0) return time;
      if (diffDays == 1) return '昨天 $time';
      if (dt.year == ref.year) return '${dt.month}月${dt.day}日 $time';
      return '${dt.year}年${dt.month}月${dt.day}日 $time';
    } catch (_) {
      return '';
    }
  }

  /// 本地时区 DateTime → 'HH:mm'（时分各左补 0 至 2 位）。
  static String _hhmm(DateTime dt) {
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }
}
