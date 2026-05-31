import 'package:flutter/material.dart';
import 'package:fluwx/fluwx.dart';
import 'package:get/get.dart';
import 'package:sanyan_common_ui/sanyan_common_ui.dart';
import 'package:sanyan_network/sanyan_network.dart';
import 'package:sanyan_routes/sanyan_routes.dart';
import 'package:sanyan_user/sanyan_user.dart';
import 'package:sanyan_auth/sanyan_auth.dart';
import 'package:sanyan_chat/sanyan_chat.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalStorage.init();

  // 初始化 fluwx：向微信原生 SDK 注册 WXApi。appId 为空时不可用微信登录，
  // 但不应让 app 启动崩溃（Apple 登录不受影响），故 try/catch 兜底。
  try {
    final fluwx = Fluwx();
    await fluwx.registerApi(
      appId: const String.fromEnvironment('WECHAT_APPID', defaultValue: ''),
      universalLink:
          const String.fromEnvironment('WECHAT_UNIVERSAL_LINK', defaultValue: ''),
    );
  } catch (e) {
    debugPrint('fluwx registerApi 失败（微信登录将不可用）: $e');
  }

  ApiClient.tokenProvider = () => LocalStorage.token;
  WsClient.tokenProvider = () => LocalStorage.token;

  // oauth 依赖装配（permanent，先于任何页面 build）
  registerOauthDependencies();

  runApp(const SanyanApp());
}

class SanyanApp extends StatelessWidget {
  const SanyanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: '三言',
      debugShowCheckedModeBanner: false,
      theme: AuraTheme.light,
      initialRoute: AppRoutes.splash,
      getPages: [
        GetPage(name: AppRoutes.splash, page: () => const SplashPage()),
        GetPage(name: AppRoutes.login, page: () => const LoginPage()),
        GetPage(name: AppRoutes.register, page: () => const RegisterPage()),
        GetPage(name: AppRoutes.chat, page: () => ChatPage()),
      ],
    );
  }
}
