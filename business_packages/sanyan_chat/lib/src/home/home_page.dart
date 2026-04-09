import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sanyan_common_ui/sanyan_common_ui.dart';
import 'package:sanyan_routes/sanyan_routes.dart';
import '../contacts/contacts_page.dart';
import '../settings/settings_page.dart';
import '../status/status_page.dart';
import '../models/conversation.dart';
import 'home_controller.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(HomeController());
    final currentTab = 0.obs;
    final pages = [
      _MessagesTab(c: c),
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

// ─────────────────────────────────────────────────────────────────────────────
// Messages Tab
// ─────────────────────────────────────────────────────────────────────────────

class _MessagesTab extends StatelessWidget {
  final HomeController c;
  const _MessagesTab({required this.c});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top bar ────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Row(
              children: [
                // Logo avatar
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AuraColors.surfaceContainerLowest,
                    border: Border.all(
                      color: AuraColors.primaryFixed,
                      width: 2,
                    ),
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/logo.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // "三言" gradient text
                ShaderMask(
                  shaderCallback: (bounds) =>
                      AuraColors.userBubbleGradient.createShader(bounds),
                  child: Text(
                    '三言',
                    style: GoogleFonts.manrope(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
                const Spacer(),
                // Search icon
                GestureDetector(
                  onTap: () {},
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AuraColors.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.search_rounded,
                      color: AuraColors.onSurfaceVariant,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Search box ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                color: AuraColors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  const Icon(
                    Icons.search_rounded,
                    color: AuraColors.onSurfaceVariant,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '搜索对话...',
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      color: AuraColors.outlineVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ── "Messages" title ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Messages',
              style: GoogleFonts.manrope(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AuraColors.onSurface,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ── Conversation list ─────────────────────────────────────────────
          Expanded(
            child: Obx(() {
              if (c.isLoading.value && c.conversations.isEmpty) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: AuraColors.primary,
                  ),
                );
              }
              if (c.conversations.isEmpty) {
                return Center(
                  child: Text(
                    '还没有对话，开始聊天吧',
                    style: GoogleFonts.manrope(
                      color: AuraColors.onSurfaceVariant,
                    ),
                  ),
                );
              }
              return RefreshIndicator(
                color: AuraColors.primary,
                onRefresh: c.loadConversations,
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Conversation list item — Stitch Ethereal style
// ─────────────────────────────────────────────────────────────────────────────

class _ConversationItem extends StatelessWidget {
  final Conversation conversation;
  const _ConversationItem({required this.conversation});

  bool get _hasUnread => conversation.unreadCount > 0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.toNamed(AppRoutes.chat, arguments: conversation),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: _hasUnread
            ? BoxDecoration(
                color: AuraColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AuraColors.glassShadow,
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              )
            : null,
        child: Row(
          children: [
            // ── Avatar with online dot ──────────────────────────────────────
            SizedBox(
              width: 56,
              height: 56,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AuraColors.mintAzureGradient,
                    ),
                    child: const Icon(
                      Icons.favorite,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  // Online green dot
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: const Color(0xFF34C759),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AuraColors.surface,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 14),

            // ── Name / preview / badge ──────────────────────────────────────
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Name + time
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        conversation.characterName ?? '未知',
                        style: GoogleFonts.manrope(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AuraColors.onSurface,
                        ),
                      ),
                      Text(
                        _formatTime(conversation.lastMessageAt),
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: AuraColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 5),

                  // Preview + unread badge
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conversation.lastMessage ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            color: _hasUnread
                                ? AuraColors.onSurface
                                : AuraColors.onSurfaceVariant,
                            fontWeight: _hasUnread
                                ? FontWeight.w500
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                      if (_hasUnread) ...[
                        const SizedBox(width: 8),
                        Container(
                          constraints: const BoxConstraints(minWidth: 20),
                          height: 20,
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          decoration: const BoxDecoration(
                            gradient: AuraColors.mintAzureGradient,
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${conversation.unreadCount}',
                            style: GoogleFonts.manrope(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AuraColors.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ],
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
      if (diff.inHours < 1) return '${diff.inMinutes}m';
      if (diff.inDays < 1) return '${diff.inHours}h';
      if (diff.inDays < 7) return '${diff.inDays}d';
      return '${dt.month}/${dt.day}';
    } catch (_) {
      return '';
    }
  }
}
