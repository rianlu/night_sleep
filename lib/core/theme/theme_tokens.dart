import 'package:flutter/material.dart';
import 'package:night_sleep/core/theme/theme_seed.dart';

@immutable
class ThemeTokens {
  const ThemeTokens({
    required this.bgBase,
    required this.bgCard,
    required this.bgSoft,
    required this.textPrimary,
    required this.textSecondary,
    required this.accent,
    required this.accentOn,
    required this.pillFg,
    required this.progressInactive,
    required this.navInactive,
    required this.border,
    required this.shadowAmber,
    required this.radiusCard,
    required this.radiusControl,
    required this.radiusPill,
    required this.spacingBase,
    required this.pagePadding,
  });

  final Color bgBase;
  final Color bgCard;
  final Color bgSoft;
  final Color textPrimary;
  final Color textSecondary;
  final Color accent;
  final Color accentOn;
  final Color pillFg;
  final Color progressInactive;
  final Color navInactive;
  final Color border;
  final Color shadowAmber;
  final double radiusCard;
  final double radiusControl;
  final double radiusPill;
  final double spacingBase;
  final double pagePadding;

  static ThemeTokens creamSunset(ThemeSeed seed) {
    final accentOn = seed.primary.computeLuminance() > 0.45
        ? const Color(0xFF3F2A0A)
        : Colors.white;

    return ThemeTokens(
      bgBase: const Color(0xFFFFFBF2),
      bgCard: const Color(0xFFFFFFFF),
      bgSoft: const Color(0xFFFFEDD5),
      textPrimary: const Color(0xFF4B5563),
      textSecondary: const Color(0xFF9CA3AF),
      accent: seed.primary,
      accentOn: accentOn,
      pillFg: const Color(0xFFB45309),
      progressInactive: const Color(0xFFFEF3C7),
      navInactive: const Color(0xFFD1D5DB),
      border: const Color(0xFFF3E9D7),
      shadowAmber: const Color(0x14F59E0B),
      radiusCard: 24,
      radiusControl: 16,
      radiusPill: 999,
      spacingBase: 8,
      pagePadding: 20,
    );
  }
}
