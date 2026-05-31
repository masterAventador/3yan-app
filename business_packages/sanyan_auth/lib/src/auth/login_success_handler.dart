import 'package:get/get.dart';
import 'package:sanyan_network/sanyan_network.dart';
import 'package:sanyan_routes/sanyan_routes.dart';
import 'package:sanyan_user/sanyan_user.dart';

/// 登录成功统一处理（手机号登录/注册/第三方登录三处复用）。
abstract class LoginSuccessHandler {
  void handle({
    required String token,
    required int userId,
    bool registerPush,
  });
}

class LoginSuccessHandlerImpl implements LoginSuccessHandler {
  // 副作用 seam（测试可覆写）
  void registerPushToken() => AuthApi.registerPushTokenAfterLogin();
  void connectWs() => Get.find<WsClient>().connect();
  void navigateToChat() => Get.offAllNamed(AppRoutes.chat);

  @override
  void handle({
    required String token,
    required int userId,
    bool registerPush = true,
  }) {
    LocalStorage.token = token;
    LocalStorage.userId = userId;
    if (registerPush) {
      registerPushToken();
    }
    connectWs();
    navigateToChat();
  }
}
