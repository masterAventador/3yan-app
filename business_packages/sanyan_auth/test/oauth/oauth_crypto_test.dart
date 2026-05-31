import 'package:flutter_test/flutter_test.dart';
import 'package:sanyan_auth/src/oauth/oauth_crypto.dart';

void main() {
  test('sha256Hex matches known vector', () {
    // sha256("abc") = ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad
    expect(sha256Hex('abc'),
        'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad');
  });
  test('sha256Hex of empty string', () {
    expect(sha256Hex(''),
        'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855');
  });
}
