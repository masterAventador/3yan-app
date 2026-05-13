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
}
