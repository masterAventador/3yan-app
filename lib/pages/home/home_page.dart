import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/routes.dart';
import 'home_controller.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(HomeController());
    return Scaffold(
      appBar: AppBar(title: const Text('三言')),
      body: Obx(() {
        if (c.isLoading.value && c.conversations.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (c.conversations.isEmpty) {
          return const Center(child: Text('还没有对话，开始聊天吧'));
        }
        return RefreshIndicator(
          onRefresh: c.loadConversations,
          child: ListView.builder(
            itemCount: c.conversations.length,
            itemBuilder: (context, index) {
              final conv = c.conversations[index];
              return ListTile(
                leading: CircleAvatar(
                  child: Text(conv.characterName?.substring(0, 1) ?? '?'),
                ),
                title: Text(conv.characterName ?? '未知角色'),
                subtitle: Text(
                  conv.lastMessage ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: conv.unreadCount > 0
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${conv.unreadCount}',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12),
                        ),
                      )
                    : null,
                onTap: () => Get.toNamed(AppRoutes.chat, arguments: conv),
              );
            },
          ),
        );
      }),
    );
  }
}
