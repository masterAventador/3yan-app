import 'package:flutter/material.dart';
import 'package:sanyan_common_ui/sanyan_common_ui.dart';

class ContactsPage extends StatelessWidget {
  const ContactsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Contacts',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AuraColors.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '敬请期待',
                style: TextStyle(
                  fontSize: 14,
                  color: AuraColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
