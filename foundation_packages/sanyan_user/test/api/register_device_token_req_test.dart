import 'package:flutter_test/flutter_test.dart';
import 'package:sanyan_user/src/api/req/register_device_token_req.dart';

void main() {
  group('RegisterDeviceTokenReq', () {
    test('path 与 method 正确', () {
      final req = RegisterDeviceTokenReq(platform: 'ios', vendor: 'apns', token: 'abc123');
      expect(req.path, '/api/devices/register');
      expect(req.method, 'POST');
    });
    test('toJson 带 platform / vendor / token', () {
      final req = RegisterDeviceTokenReq(platform: 'ios', vendor: 'apns', token: 'abc123');
      expect(req.toJson(), {'platform': 'ios', 'vendor': 'apns', 'token': 'abc123'});
    });
  });
}
