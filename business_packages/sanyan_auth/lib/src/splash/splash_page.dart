import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sanyan_network/sanyan_network.dart';
import 'package:sanyan_routes/sanyan_routes.dart';
import 'package:sanyan_user/sanyan_user.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(WsClient(), permanent: true);

    // TODO: 对接极光/个推 SDK 后，在此获取 push token 并调用 DeviceApi.updatePushToken()
    Future.delayed(const Duration(milliseconds: 500), () {
      if (LocalStorage.token != null) {
        Get.find<WsClient>().connect();
        Get.offAllNamed(AppRoutes.home);
      } else {
        Get.offAllNamed(AppRoutes.login);
      }
    });

    return const Scaffold(
      body: Center(
        child: Text(
          '三言',
          style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
