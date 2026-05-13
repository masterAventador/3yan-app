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
      final dt = DateTime.parse(iso8601).toLocal();
      final hh = dt.hour.toString().padLeft(2, '0');
      final mm = dt.minute.toString().padLeft(2, '0');
      return '$hh:$mm';
    } catch (_) {
      return '';
    }
  }
}
