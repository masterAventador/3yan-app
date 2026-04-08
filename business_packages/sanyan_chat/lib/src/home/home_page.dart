import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sanyan_common_ui/sanyan_common_ui.dart';
import 'package:sanyan_routes/sanyan_routes.dart';
import '../models/conversation.dart';
import 'home_controller.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(HomeController());
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: SizedBox(
                height: 56,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '消息',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {/* TODO: new conversation */},
                      child: const Icon(Icons.add_circle_outline, size: 24, color: AppColors.brandButton),
                    ),
                  ],
                ),
              ),
            ),

            // Conversation list
            Expanded(
              child: Obx(() {
                if (c.isLoading.value && c.conversations.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.brandButton),
                  );
                }
                if (c.conversations.isEmpty) {
                  return const Center(
                    child: Text('还没有对话，开始聊天吧', style: TextStyle(color: AppColors.textSecondary)),
                  );
                }
                return RefreshIndicator(
                  color: AppColors.brandButton,
                  onRefresh: c.loadConversations,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    itemCount: c.conversations.length,
                    itemBuilder: (context, index) => _ConversationItem(
                      conversation: c.conversations[index],
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _BottomNavBar(),
    );
  }
}

class _ConversationItem extends StatelessWidget {
  final Conversation conversation;
  const _ConversationItem({required this.conversation});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.toNamed(AppRoutes.chat, arguments: conversation),
      child: Container(
        height: 76,
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            // Avatar with badge
            SizedBox(
              width: 52,
              height: 52,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.brandGradient,
                    ),
                    child: const Icon(Icons.favorite, color: Colors.white, size: 24),
                  ),
                  if (conversation.unreadCount > 0)
                    Positioned(
                      right: -4,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF3B30),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: Text(
                          '${conversation.unreadCount}',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        conversation.characterName ?? '未知',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        _formatTime(conversation.lastMessageAt),
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      conversation.lastMessage ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(String? time) {
    if (time == null) return '';
    try {
      final dt = DateTime.parse(time);
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 1) return '刚刚';
      if (diff.inHours < 1) return '${diff.inMinutes}分钟前';
      if (diff.inDays < 1) return '${diff.inHours}小时前';
      if (diff.inDays < 7) return '${diff.inDays}天前';
      return '${dt.month}/${dt.day}';
    } catch (_) {
      return '';
    }
  }
}

class _BottomNavBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF0F0F0))),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 56,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _tab(Icons.chat_bubble_outline, '消息', true),
              _tab(Icons.explore_outlined, '发现', false),
              _tab(Icons.person_outline, '我的', false),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tab(IconData icon, String label, bool active) {
    final color = active ? AppColors.brandButton : AppColors.textSecondary;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 24, color: color),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: active ? FontWeight.w600 : FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }
}
