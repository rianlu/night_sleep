import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF8B5CF6); // 紫色 (主题色)
  static const Color secondaryColor = Color(0xFF10B981); // 翠绿色 (功能色)
  static const Color backgroundColor = Color(0xFF0F172A); // 深蓝背景 (Slate 900)
  static const Color surfaceColor = Color(0xFF1E293B); // 卡片背景 (Slate 800)
  static const Color textColor = Color(0xFFF8FAFC); // 主文字颜色
  static const Color secondaryTextColor = Color(0xFF94A3B8); // 次要文字颜色

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF0F172A),
      Color(0xFF020617),
    ],
  );

  /// 只有深色模式，符合睡前使用场景
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: backgroundColor,
      primaryColor: primaryColor,
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: surfaceColor,
        onPrimary: Colors.white,
        onSurface: textColor,
      ),
      textTheme: GoogleFonts.outfitTextTheme(
        ThemeData.dark().textTheme,
      ).apply(
        bodyColor: textColor,
        displayColor: textColor,
      ),
      cardTheme: CardThemeData(
        color: surfaceColor.withAlpha(200), // 毛玻璃效果提示
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Colors.white.withAlpha(20), width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent, // 用于支持渐变背景
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: textColor,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: primaryColor,
        inactiveTrackColor: surfaceColor,
        thumbColor: Colors.white,
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
      ),
    );
  }
}
