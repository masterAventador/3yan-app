import 'auth/login_success_handler_test.dart' as login_success_handler_test;
import 'auth/login_page_oauth_test.dart' as login_page_oauth_test;
import 'oauth/oauth_crypto_test.dart' as oauth_crypto_test;
import 'oauth/apple_auth_provider_test.dart' as apple_auth_provider_test;
import 'oauth/wechat_auth_provider_test.dart' as wechat_auth_provider_test;
import 'oauth/oauth_gateway_test.dart' as oauth_gateway_test;
import 'oauth/oauth_login_controller_test.dart' as oauth_login_controller_test;
import 'oauth/bind_phone_controller_test.dart' as bind_phone_controller_test;

void main() {
  login_success_handler_test.main();
  login_page_oauth_test.main();
  oauth_crypto_test.main();
  apple_auth_provider_test.main();
  wechat_auth_provider_test.main();
  oauth_gateway_test.main();
  oauth_login_controller_test.main();
  bind_phone_controller_test.main();
}
