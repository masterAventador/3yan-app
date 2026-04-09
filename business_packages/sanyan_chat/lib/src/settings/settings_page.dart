import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sanyan_common_ui/sanyan_common_ui.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

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
                'Settings',
                style: GoogleFonts.manrope(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AuraColors.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '敬请期待',
                style: GoogleFonts.manrope(
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
