import 'package:flutter/material.dart';
import 'package:sanyan_common_ui/sanyan_common_ui.dart';

/// 聊天页左侧设置抽屉（占位骨架）。
///
/// 各项功能后续逐个接入，当前 onTap 回调由调用方（ChatPage）提供。
/// 订阅入口是收费功能入口，收费模式待定，先占位。
class ChatSettingsDrawer extends StatelessWidget {
  final VoidCallback? onProfile;
  final VoidCallback? onSubscribe;
  final VoidCallback? onProactiveSettings;
  final VoidCallback? onNotificationSettings;
  final VoidCallback? onAbout;
  final VoidCallback? onLogout;

  const ChatSettingsDrawer({
    super.key,
    this.onProfile,
    this.onSubscribe,
    this.onProactiveSettings,
    this.onNotificationSettings,
    this.onAbout,
    this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AuraColors.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 头部：头像 + 昵称（占位，接入用户中心后填真实数据）
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AuraColors.primary.withValues(alpha: 0.15),
                    child: const Icon(Icons.person, color: AuraColors.primary, size: 30),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('未登录',
                            style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: AuraColors.onSurface)),
                        SizedBox(height: 4),
                        Text('点击登录账号',
                            style: TextStyle(
                                fontSize: 13, color: AuraColors.onSurfaceVariant)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // 订阅入口（醒目渐变卡片，收费功能入口）
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _SubscribeCard(onTap: onSubscribe),
            ),
            const SizedBox(height: 8),
            _DrawerTile(
                icon: Icons.person_outline, label: '账号与资料', onTap: onProfile),
            _DrawerTile(
                icon: Icons.auto_awesome_outlined,
                label: '主动消息设置',
                onTap: onProactiveSettings),
            _DrawerTile(
                icon: Icons.notifications_none,
                label: '通知设置',
                onTap: onNotificationSettings),
            _DrawerTile(icon: Icons.info_outline, label: '关于', onTap: onAbout),
            const Spacer(),
            _DrawerTile(icon: Icons.logout, label: '退出登录', onTap: onLogout),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _SubscribeCard extends StatelessWidget {
  final VoidCallback? onTap;
  const _SubscribeCard({this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          gradient: AuraColors.mintAzureGradient,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          children: [
            Icon(Icons.workspace_premium, color: AuraColors.onSurface, size: 26),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('订阅会员',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AuraColors.onSurface)),
                  SizedBox(height: 2),
                  Text('解锁更多专属功能',
                      style: TextStyle(fontSize: 12, color: AuraColors.onSurface)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AuraColors.onSurface),
          ],
        ),
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _DrawerTile({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AuraColors.onSurfaceVariant),
      title: Text(label,
          style: const TextStyle(fontSize: 15, color: AuraColors.onSurface)),
      trailing: const Icon(Icons.chevron_right,
          size: 18, color: AuraColors.onSurfaceVariant),
      onTap: onTap,
    );
  }
}
