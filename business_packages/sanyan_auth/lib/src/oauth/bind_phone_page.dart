import 'package:flutter/material.dart';

/// 绑定手机号页（占位，Task 12 补全完整 UI）。
class BindPhonePage extends StatelessWidget {
  final String bindTicket;
  const BindPhonePage({super.key, required this.bindTicket});
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('绑定手机号')));
}
