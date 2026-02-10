import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:night_sleep/core/theme/promax_colors.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ProMaxColors.stitchReportBg,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: ProMaxColors.stitchReportCardBg,
                shape: BoxShape.circle,
                border: Border.all(color: ProMaxColors.stitchReportAccent.withValues(alpha: 0.2), width: 4),
              ),
              child: const Icon(Icons.person_rounded, size: 50, color: ProMaxColors.stitchReportAccent),
            ),
            const SizedBox(height: 24),
            Text(
              "个人中心",
              style: GoogleFonts.manrope(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "现已跳过具体功能实现，仅保留入口",
              style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
