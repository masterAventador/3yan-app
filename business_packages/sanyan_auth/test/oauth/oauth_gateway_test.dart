import 'package:flutter_test/flutter_test.dart';
import 'package:sanyan_auth/src/oauth/oauth_gateway.dart';

void main() {
  test('OauthGatewayImpl is constructable and is an OauthGateway', () {
    final g = OauthGatewayImpl();
    expect(g, isA<OauthGateway>());
  });
}
