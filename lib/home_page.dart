import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sanyan_common_ui/sanyan_common_ui.dart';
import 'package:sanyan_chat/sanyan_chat.dart';
import 'package:sanyan_contacts/sanyan_contacts.dart';
import 'package:sanyan_settings/sanyan_settings.dart';
import 'package:sanyan_status/sanyan_status.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final currentTab = 0.obs;
    final pages = [
      const MessagesTab(),
      const ContactsPage(),
      const StatusPage(),
      const SettingsPage(),
    ];
    return Scaffold(
      backgroundColor: AuraColors.surface,
      body: Obx(() => IndexedStack(index: currentTab.value, children: pages)),
      bottomNavigationBar: Obx(
        () => AuraNavBar(
          currentIndex: currentTab.value,
          onTap: (i) => currentTab.value = i,
        ),
      ),
    );
  }
}
