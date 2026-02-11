import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:night_sleep/core/theme/promax_colors.dart';

class AppTheme {
  // Canonical Colors from ProMaxColors
  static const Color primaryColor = ProMaxColors.stitchPrimary; // Amber Gold #FFB13B
  static const Color secondaryColor = Color(0xFF10B981); // Keep functional green
  static const Color backgroundColor = ProMaxColors.stitchBackground; // Deep Warm Coffee #1A1412
  static const Color surfaceColor = ProMaxColors.stitchCardBg; // Lighter Coffee #2D241E
  static const Color textColor = ProMaxColors.stitchTextLight; // #E8E0D9
  static const Color secondaryTextColor = ProMaxColors.stitchTextMuted; // #B9A89D

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      ProMaxColors.stitchBackground,
      Color(0xFF0F0B09), // Even darker coffee at bottom for depth
    ],
  );

  /// Deep Warm Coffee Theme
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
        onPrimary: Color(0xFF1A1412), // Dark text on amber
        onSurface: textColor,
        background: backgroundColor,
      ),
      textTheme: GoogleFonts.outfitTextTheme(
        ThemeData.dark().textTheme,
      ).apply(
        bodyColor: textColor,
        displayColor: textColor,
      ),
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.05), width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: textColor,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        iconTheme: IconThemeData(color: textColor),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: primaryColor,
        inactiveTrackColor: Colors.white.withValues(alpha: 0.1),
        thumbColor: primaryColor,
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
        overlayColor: primaryColor.withValues(alpha: 0.2),
      ),
      iconTheme: const IconThemeData(color: textColor),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: primaryColor),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: const Color(0xFF140F0D), // Dark text on button
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
