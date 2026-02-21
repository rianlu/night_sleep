import 'package:flutter/material.dart';
import 'package:night_sleep/core/theme/theme_tokens.dart';

@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.titleStrong,
    required this.titleMuted,
    required this.titleSecondary,
    required this.cardElevated,
    required this.cardSubtle,
    required this.cardBorderSoft,
    required this.cardShadow,
    required this.panelDivider,
    required this.pillBg,
    required this.pillBorder,
    required this.pillText,
    required this.queueActiveBg,
    required this.queueActiveBorder,
    required this.queueMuted,
    required this.queueMutedSoft,
    required this.iconMuted,
    required this.sheetHandle,
    required this.modalBarrier,
    required this.successBg,
    required this.successFg,
    required this.successBorder,
    required this.warningBg,
    required this.warningFg,
    required this.warningBorder,
    required this.navBg,
    required this.navSelectedBg,
  });

  final Color titleStrong;
  final Color titleMuted;
  final Color titleSecondary;
  final Color cardElevated;
  final Color cardSubtle;
  final Color cardBorderSoft;
  final Color cardShadow;
  final Color panelDivider;
  final Color pillBg;
  final Color pillBorder;
  final Color pillText;
  final Color queueActiveBg;
  final Color queueActiveBorder;
  final Color queueMuted;
  final Color queueMutedSoft;
  final Color iconMuted;
  final Color sheetHandle;
  final Color modalBarrier;
  final Color successBg;
  final Color successFg;
  final Color successBorder;
  final Color warningBg;
  final Color warningFg;
  final Color warningBorder;
  final Color navBg;
  final Color navSelectedBg;

  factory AppPalette.fromTokens(ThemeTokens t) {
    return AppPalette(
      titleStrong: const Color(0xFF6B1F08),
      titleMuted: const Color(0xFFA97B5D),
      titleSecondary: const Color(0xFFA8A29E),
      cardElevated: t.bgCard,
      cardSubtle: const Color(0xFFFFF7ED),
      cardBorderSoft: const Color(0xFFF3DEC1),
      cardShadow: t.shadowAmber,
      panelDivider: const Color(0xFFF3DEC1),
      pillBg: const Color(0xFFFFF7ED),
      pillBorder: t.bgSoft,
      pillText: const Color(0xFF78350F),
      queueActiveBg: const Color(0xFFFEF2DE),
      queueActiveBorder: const Color(0xFFF3C278),
      queueMuted: const Color(0xFFBE9C8A),
      queueMutedSoft: const Color(0xFFD6C6BA),
      iconMuted: const Color(0xFFC4AD99),
      sheetHandle: const Color(0xFFA8A29E),
      modalBarrier: Colors.black.withValues(alpha: 0.4),
      successBg: const Color(0xFFDBF5E8),
      successFg: const Color(0xFF059669),
      successBorder: const Color(0xFFD1FAE5),
      warningBg: const Color(0xFFFFF7ED),
      warningFg: const Color(0xFFD97706),
      warningBorder: const Color(0xFFFED7AA),
      navBg: const Color(0xFFFBF8F1),
      navSelectedBg: const Color(0xFFFFF2DE),
    );
  }

  @override
  AppPalette copyWith({
    Color? titleStrong,
    Color? titleMuted,
    Color? titleSecondary,
    Color? cardElevated,
    Color? cardSubtle,
    Color? cardBorderSoft,
    Color? cardShadow,
    Color? panelDivider,
    Color? pillBg,
    Color? pillBorder,
    Color? pillText,
    Color? queueActiveBg,
    Color? queueActiveBorder,
    Color? queueMuted,
    Color? queueMutedSoft,
    Color? iconMuted,
    Color? sheetHandle,
    Color? modalBarrier,
    Color? successBg,
    Color? successFg,
    Color? successBorder,
    Color? warningBg,
    Color? warningFg,
    Color? warningBorder,
    Color? navBg,
    Color? navSelectedBg,
  }) {
    return AppPalette(
      titleStrong: titleStrong ?? this.titleStrong,
      titleMuted: titleMuted ?? this.titleMuted,
      titleSecondary: titleSecondary ?? this.titleSecondary,
      cardElevated: cardElevated ?? this.cardElevated,
      cardSubtle: cardSubtle ?? this.cardSubtle,
      cardBorderSoft: cardBorderSoft ?? this.cardBorderSoft,
      cardShadow: cardShadow ?? this.cardShadow,
      panelDivider: panelDivider ?? this.panelDivider,
      pillBg: pillBg ?? this.pillBg,
      pillBorder: pillBorder ?? this.pillBorder,
      pillText: pillText ?? this.pillText,
      queueActiveBg: queueActiveBg ?? this.queueActiveBg,
      queueActiveBorder: queueActiveBorder ?? this.queueActiveBorder,
      queueMuted: queueMuted ?? this.queueMuted,
      queueMutedSoft: queueMutedSoft ?? this.queueMutedSoft,
      iconMuted: iconMuted ?? this.iconMuted,
      sheetHandle: sheetHandle ?? this.sheetHandle,
      modalBarrier: modalBarrier ?? this.modalBarrier,
      successBg: successBg ?? this.successBg,
      successFg: successFg ?? this.successFg,
      successBorder: successBorder ?? this.successBorder,
      warningBg: warningBg ?? this.warningBg,
      warningFg: warningFg ?? this.warningFg,
      warningBorder: warningBorder ?? this.warningBorder,
      navBg: navBg ?? this.navBg,
      navSelectedBg: navSelectedBg ?? this.navSelectedBg,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;

    return AppPalette(
      titleStrong: Color.lerp(titleStrong, other.titleStrong, t)!,
      titleMuted: Color.lerp(titleMuted, other.titleMuted, t)!,
      titleSecondary: Color.lerp(titleSecondary, other.titleSecondary, t)!,
      cardElevated: Color.lerp(cardElevated, other.cardElevated, t)!,
      cardSubtle: Color.lerp(cardSubtle, other.cardSubtle, t)!,
      cardBorderSoft: Color.lerp(cardBorderSoft, other.cardBorderSoft, t)!,
      cardShadow: Color.lerp(cardShadow, other.cardShadow, t)!,
      panelDivider: Color.lerp(panelDivider, other.panelDivider, t)!,
      pillBg: Color.lerp(pillBg, other.pillBg, t)!,
      pillBorder: Color.lerp(pillBorder, other.pillBorder, t)!,
      pillText: Color.lerp(pillText, other.pillText, t)!,
      queueActiveBg: Color.lerp(queueActiveBg, other.queueActiveBg, t)!,
      queueActiveBorder: Color.lerp(
        queueActiveBorder,
        other.queueActiveBorder,
        t,
      )!,
      queueMuted: Color.lerp(queueMuted, other.queueMuted, t)!,
      queueMutedSoft: Color.lerp(queueMutedSoft, other.queueMutedSoft, t)!,
      iconMuted: Color.lerp(iconMuted, other.iconMuted, t)!,
      sheetHandle: Color.lerp(sheetHandle, other.sheetHandle, t)!,
      modalBarrier: Color.lerp(modalBarrier, other.modalBarrier, t)!,
      successBg: Color.lerp(successBg, other.successBg, t)!,
      successFg: Color.lerp(successFg, other.successFg, t)!,
      successBorder: Color.lerp(successBorder, other.successBorder, t)!,
      warningBg: Color.lerp(warningBg, other.warningBg, t)!,
      warningFg: Color.lerp(warningFg, other.warningFg, t)!,
      warningBorder: Color.lerp(warningBorder, other.warningBorder, t)!,
      navBg: Color.lerp(navBg, other.navBg, t)!,
      navSelectedBg: Color.lerp(navSelectedBg, other.navSelectedBg, t)!,
    );
  }
}
