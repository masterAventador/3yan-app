import 'package:flutter_test/flutter_test.dart';
import 'package:sanyan_user/sanyan_user.dart';

void main() {
  group('OauthLoginData.fromJson', () {
    test('logged-in: token + userId, not needBind/needMerge', () {
      final d = OauthLoginData.fromJson({'token': 'jwt', 'userId': 42, 'nickname': '小婉'});
      expect(d.token, 'jwt');
      expect(d.userId, 42);
      expect(d.needBind, isFalse);
      expect(d.needMergeAuth, isFalse);
      expect(d.bindTicket, isNull);
      expect(d.nickname, '小婉');
      expect(d.loggedIn, isTrue);
    });
    test('needBind: carries bindTicket, no token', () {
      final d = OauthLoginData.fromJson({'needBind': true, 'bindTicket': 'bt-123'});
      expect(d.needBind, isTrue);
      expect(d.bindTicket, 'bt-123');
      expect(d.token, isNull);
      expect(d.loggedIn, isFalse);
    });
    test('needMergeAuth: flag true, no token', () {
      final d = OauthLoginData.fromJson({'needMergeAuth': true});
      expect(d.needMergeAuth, isTrue);
      expect(d.token, isNull);
    });
    test('missing flags default to false', () {
      final d = OauthLoginData.fromJson({'token': 't', 'userId': 1});
      expect(d.needBind, isFalse);
      expect(d.needMergeAuth, isFalse);
    });
  });
}
