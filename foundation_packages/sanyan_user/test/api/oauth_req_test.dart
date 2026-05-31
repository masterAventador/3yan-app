import 'package:flutter_test/flutter_test.dart';
import 'package:sanyan_user/src/api/req/oauth_challenge_req.dart';
import 'package:sanyan_user/src/api/req/oauth_login_req.dart';
import 'package:sanyan_user/src/api/req/oauth_bind_phone_req.dart';

void main() {
  test('OauthChallengeReq path/method/body', () {
    final r = OauthChallengeReq();
    expect(r.path, '/api/auth/oauth/challenge');
    expect(r.method, 'POST');
    expect(r.toJson(), {});
  });
  test('OauthLoginReq carries provider/credential/nonce', () {
    final r = OauthLoginReq(provider: 'APPLE', credential: 'idtoken', nonce: 'raw-nonce');
    expect(r.path, '/api/auth/oauth/login');
    expect(r.method, 'POST');
    expect(r.toJson(), {'provider': 'APPLE', 'credential': 'idtoken', 'nonce': 'raw-nonce'});
  });
  test('OauthLoginReq omits null nonce (wechat)', () {
    final r = OauthLoginReq(provider: 'WECHAT', credential: 'code', nonce: null);
    expect(r.toJson(), {'provider': 'WECHAT', 'credential': 'code'});
  });
  test('OauthBindPhoneReq carries ticket/phone/code, optional password', () {
    final r = OauthBindPhoneReq(bindTicket: 'bt', phone: '13800000000', code: '1234', password: 'pw');
    expect(r.path, '/api/auth/oauth/bind-phone');
    expect(r.method, 'POST');
    expect(r.toJson(), {'bindTicket': 'bt', 'phone': '13800000000', 'code': '1234', 'password': 'pw'});
  });
  test('OauthBindPhoneReq omits null password', () {
    final r = OauthBindPhoneReq(bindTicket: 'bt', phone: '13800000000', code: '1234', password: null);
    expect(r.toJson(), {'bindTicket': 'bt', 'phone': '13800000000', 'code': '1234'});
  });
}
