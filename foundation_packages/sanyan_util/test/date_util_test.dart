import 'package:flutter_test/flutter_test.dart';
import 'package:sanyan_util/sanyan_util.dart';

void main() {
  group('DateUtil.formatHHmm', () {
    test('null returns empty string', () {
      expect(DateUtil.formatHHmm(null), '');
    });

    test('empty string returns empty string', () {
      expect(DateUtil.formatHHmm(''), '');
    });

    test('invalid string returns empty string', () {
      expect(DateUtil.formatHHmm('not-a-date'), '');
    });

    test('valid local ISO 8601 (no timezone) returns HH:mm verbatim', () {
      expect(DateUtil.formatHHmm('2026-05-14T14:05:30'), '14:05');
    });

    test('single-digit hour and minute are zero-padded', () {
      expect(DateUtil.formatHHmm('2026-05-14T03:07:00'), '03:07');
    });

    test('UTC ISO 8601 (Z suffix) is converted to local timezone', () {
      final result = DateUtil.formatHHmm('2026-05-14T14:05:30Z');
      expect(result, matches(RegExp(r'^\d{2}:\d{2}$')));
    });
  });

  group('DateUtil.formatChatTimestamp', () {
    test('null returns empty string', () {
      expect(DateUtil.formatChatTimestamp(null), '');
    });

    test('empty string returns empty string', () {
      expect(DateUtil.formatChatTimestamp(''), '');
    });

    test('invalid string returns empty string', () {
      expect(DateUtil.formatChatTimestamp('not-a-date'), '');
    });

    test('same day shows only HH:mm', () {
      expect(
        DateUtil.formatChatTimestamp(
          '2026-05-31T14:05:30',
          now: DateTime(2026, 5, 31, 20, 0),
        ),
        '14:05',
      );
    });

    test('yesterday shows 昨天 prefix', () {
      expect(
        DateUtil.formatChatTimestamp(
          '2026-05-30T09:30:00',
          now: DateTime(2026, 5, 31, 8, 0),
        ),
        '昨天 09:30',
      );
    });

    test('earlier this year shows M月d日 without year', () {
      expect(
        DateUtil.formatChatTimestamp(
          '2026-05-14T18:20:00',
          now: DateTime(2026, 5, 31, 8, 0),
        ),
        '5月14日 18:20',
      );
    });

    test('previous year shows full yyyy年M月d日', () {
      expect(
        DateUtil.formatChatTimestamp(
          '2025-12-01T10:00:00',
          now: DateTime(2026, 5, 31, 8, 0),
        ),
        '2025年12月1日 10:00',
      );
    });

    test('time part is zero-padded but date part is not', () {
      expect(
        DateUtil.formatChatTimestamp(
          '2026-03-05T03:07:00',
          now: DateTime(2026, 5, 31, 8, 0),
        ),
        '3月5日 03:07',
      );
    });

    test('yesterday boundary across year is still 昨天', () {
      expect(
        DateUtil.formatChatTimestamp(
          '2025-12-31T23:00:00',
          now: DateTime(2026, 1, 1, 8, 0),
        ),
        '昨天 23:00',
      );
    });
  });
}
