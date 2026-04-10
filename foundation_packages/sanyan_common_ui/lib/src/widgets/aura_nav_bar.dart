import 'dart:ui';
import 'package:flutter/material.dart';
import '../aura_colors.dart';
import '../aura_fonts.dart';

/// Navigation tab data model.
class AuraNavItem {
  final String label;
  final IconData activeIcon;
  final IconData inactiveIcon;

  const AuraNavItem({
    required this.label,
    required this.activeIcon,
    required this.inactiveIcon,
  });
}

/// Frosted glass bottom navigation bar with 4 tabs.
/// Active tab has a mintAzure gradient pill.
///
/// Usage:
/// ```dart
/// AuraNavBar(
///   currentIndex: c.tabIndex.value,
///   onTap: c.onTabChanged,
/// )
/// ```
class AuraNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  static const _items = [
    AuraNavItem(
      label: 'MESSAGES',
      activeIcon: Icons.chat_bubble,
      inactiveIcon: Icons.chat_bubble_outline,
    ),
    AuraNavItem(
      label: 'CONTACTS',
      activeIcon: Icons.people,
      inactiveIcon: Icons.people_outline,
    ),
    AuraNavItem(
      label: 'STATUS',
      activeIcon: Icons.circle_notifications,
      inactiveIcon: Icons.circle_notifications_outlined,
    ),
    AuraNavItem(
      label: 'SETTINGS',
      activeIcon: Icons.settings,
      inactiveIcon: Icons.settings_outlined,
    ),
  ];

  const AuraNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          decoration: BoxDecoration(
            color: AuraColors.glassColor,
            border: const Border(
              top: BorderSide(color: AuraColors.glassBorder, width: 1),
            ),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 64,
              child: Row(
                children: List.generate(_items.length, (index) {
                  final item = _items[index];
                  final active = index == currentIndex;
                  return Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onTap(index),
                      child: _AuraNavTabItem(item: item, active: active),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AuraNavTabItem extends StatelessWidget {
  final AuraNavItem item;
  final bool active;

  const _AuraNavTabItem({required this.item, required this.active});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          width: active ? 52 : 40,
          height: 32,
          decoration: active
              ? BoxDecoration(
                  gradient: AuraColors.mintAzureGradient,
                  borderRadius: BorderRadius.circular(16),
                )
              : null,
          alignment: Alignment.center,
          child: Icon(
            active ? item.activeIcon : item.inactiveIcon,
            size: 22,
            color: active ? AuraColors.onSurface : AuraColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          item.label,
          style: TextStyle(
            fontFamily: AuraFonts.manrope,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: active ? AuraColors.primary : AuraColors.onSurfaceVariant,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
