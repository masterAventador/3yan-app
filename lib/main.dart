import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'app/routes.dart';

void main() {
  runApp(const SanyanApp());
}

class SanyanApp extends StatelessWidget {
  const SanyanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: '三言',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C5CE7),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C5CE7),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      initialRoute: AppRoutes.splash,
      getPages: AppRoutes.pages,
    );
  }
}
