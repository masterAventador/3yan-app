import 'package:get/get.dart';
import '../auth/login_success_handler.dart';
import 'apple_auth_provider.dart';
import 'wechat_auth_provider.dart';
import 'oauth_gateway.dart';
import 'oauth_login_controller.dart';

/// 装配第三方登录依赖（composition root 在 main 调用一次）。
void registerOauthDependencies() {
  Get.put<OauthGateway>(OauthGatewayImpl(), permanent: true);
  Get.put<LoginSuccessHandler>(LoginSuccessHandlerImpl(), permanent: true);
  Get.put<OauthLoginController>(
    OauthLoginController(
      apple: AppleAuthProviderImpl(),
      wechat: WechatAuthProviderImpl(),
      gateway: Get.find<OauthGateway>(),
      successHandler: Get.find<LoginSuccessHandler>(),
    ),
    permanent: true,
  );
}
