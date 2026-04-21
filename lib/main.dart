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
  // 把 AVAudioSession 默认 category 改成 playAndRecord，避免 audioplayers 默认的
  // .playback 占用 session 导致 record 的 AAC 编码器初始化失败。必须在任何 AudioPlayer
  // 使用之前调用。
  await initAudioSession();
  // Clean up voice cache files older than 7 days
  unawaited(VoiceCacheManager.cleanupOldFiles());

  // Wire up token providers so network module can access auth token
  ApiClient.tokenProvider = () => LocalStorage.token;
  WsClient.tokenProvider = () => LocalStorage.token;

  // Register network services as permanent GetxService singletons.
  // MessageSender 跨聊天页生命周期存活，必须在 route 启动前 initAsync 完成，
  // 这样冷启的 pending 消息（之前 sending 被转成 failed）已经可见，
  // ChatController onInit 合并 pending 时直接显示感叹号，避免 UI 闪烁。
  final wsClient = Get.put<WsClient>(WsClient(), permanent: true);
  final messageSender = MessageSender(wsClient: wsClient);
  await messageSender.initAsync();
  Get.put<MessageSender>(messageSender, permanent: true);

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
        GetPage(
          name: AppRoutes.chat,
          page: () => ChatPage(conversation: Get.arguments as Conversation),
        ),
      ],
    );
  }
}
