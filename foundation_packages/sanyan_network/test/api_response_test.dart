import 'package:flutter_test/flutter_test.dart';
import 'package:sanyan_network/sanyan_network.dart';

void main() {
  group('ApiResponse.fromJson', () {
    test('reads code and message from server BaseResp', () {
      final r = ApiResponse.fromJson(
        {'success': false, 'code': 1014, 'message': '该手机号已注册', 'data': null},
        (d) => d as Map<String, dynamic>?,
      );
      expect(r.success, isFalse);
      expect(r.code, 1014);
      expect(r.message, '该手机号已注册');
    });
    test('errMsg falls back to message for backward compatibility', () {
      final r = ApiResponse.fromJson(
        {'success': false, 'message': '验证码错误', 'data': null},
        (d) => d as Map<String, dynamic>?,
      );
      expect(r.errMsg, '验证码错误');
    });
    test('code parses from JSON num (float) safely', () {
      final r = ApiResponse.fromJson(
        {'success': false, 'code': 1014.0, 'message': 'x', 'data': null},
        (d) => d as Map<String, dynamic>?,
      );
      expect(r.code, 1014);
    });
    test('success response carries data and null code/message', () {
      final r = ApiResponse.fromJson(
        {'success': true, 'data': {'token': 't', 'userId': 1}},
        (d) => d as Map<String, dynamic>?,
      );
      expect(r.success, isTrue);
      expect(r.data, {'token': 't', 'userId': 1});
      expect(r.code, isNull);
    });
  });
}
