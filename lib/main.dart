import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sanyan_common_ui/sanyan_common_ui.dart';
import 'package:sanyan_network/sanyan_network.dart';
import 'package:sanyan_routes/sanyan_routes.dart';
import 'package:sanyan_user/sanyan_user.dart';
import 'package:sanyan_auth/sanyan_auth.dart';
import 'package:sanyan_chat/sanyan_chat.dart';
import 'home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalStorage.init();
  // Clean up voice cache files older than 7 days
  unawaited(VoiceCacheManager.cleanupOldFiles());

  // Wire up token providers so network module can access auth token
  ApiClient.tokenProvider = () => LocalStorage.token;
  WsClient.tokenProvider = () => LocalStorage.token;

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
        GetPage(name: AppRoutes.home, page: () => const HomePage()),
        GetPage(name: AppRoutes.chat, page: () => ChatPage()),
      ],
    );
  }
}
