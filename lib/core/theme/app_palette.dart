import 'dart:math';

import 'package:flutter/material.dart';
import 'package:night_sleep/core/theme/theme_seed.dart';
import 'package:night_sleep/core/theme/theme_tokens.dart';

/// 语义调色板：为 UI 组件提供更丰富的语义化颜色。
///
/// 通过 [ThemeTokens] + [ThemeSeed] + [Brightness] 衍生，
/// 作为 [ThemeExtension] 挂载到 [ThemeData]，UI 层通过
/// `Theme.of(context).extension<AppPalette>()!` 访问。
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
    required this.switchActiveTrack,
    required this.switchInactiveTrack,
    required this.switchThumb,
    required this.headerAvatar,
    required this.headerAvatarBorder,
    required this.headerAvatarShadow,
    required this.chevronColor,
    required this.groupBg,
    required this.groupShadow,
  });

  // ── 标题 / 文字 ──
  final Color titleStrong;
  final Color titleMuted;
  final Color titleSecondary;

  // ── 卡片 ──
  final Color cardElevated;
  final Color cardSubtle;
  final Color cardBorderSoft;
  final Color cardShadow;
  final Color panelDivider;

  // ── 胶囊 / Chip ──
  final Color pillBg;
  final Color pillBorder;
  final Color pillText;

  // ── 队列 ──
  final Color queueActiveBg;
  final Color queueActiveBorder;
  final Color queueMuted;
  final Color queueMutedSoft;

  // ── 杂项 ──
  final Color iconMuted;
  final Color sheetHandle;
  final Color modalBarrier;

  // ── 语义色 ──
  final Color successBg;
  final Color successFg;
  final Color successBorder;
  final Color warningBg;
  final Color warningFg;
  final Color warningBorder;

  // ── 导航 ──
  final Color navBg;
  final Color navSelectedBg;

  // ── 开关 ──
  final Color switchActiveTrack;
  final Color switchInactiveTrack;
  final Color switchThumb;

  // ── Profile 页专用 ──
  final Color headerAvatar;
  final Color headerAvatarBorder;
  final Color headerAvatarShadow;
  final Color chevronColor;
  final Color groupBg;
  final Color groupShadow;

  // ─────────────────────────────────────────────
  //  工厂方法
  // ─────────────────────────────────────────────

  factory AppPalette.fromTokens(
    ThemeTokens t,
    ThemeSeed seed,
    Brightness brightness,
  ) {
    final isDark = brightness == Brightness.dark;
    // 核心 4 token 根据模式选择
    final primary = isDark ? seed.darkPrimary : seed.primary;
    final background = isDark ? seed.darkBackground : seed.background;
    final container = isDark ? seed.darkContainer : seed.container;
    final content = isDark ? seed.darkContent : seed.content;
    final hsl = HSLColor.fromColor(primary);
    final contentHsl = HSLColor.fromColor(content);
    final bgHsl = HSLColor.fromColor(background);
    final ctHsl = HSLColor.fromColor(container);

    return AppPalette(
      // ── 标题 ──
      titleStrong: content,
      titleMuted: isDark
          ? _hsl(contentHsl.hue, min(contentHsl.saturation, 0.20), 0.55)
          : _hsl(contentHsl.hue, 0.30, 0.51),
      titleSecondary: isDark
          ? _hsl(contentHsl.hue, min(contentHsl.saturation, 0.10), 0.50)
          : _hsl(contentHsl.hue, 0.05, 0.64),

      // ── 卡片 ──
      cardElevated: t.bgCard,
      cardSubtle: isDark
          ? _hsl(ctHsl.hue, max(ctHsl.saturation, 0.06), ctHsl.lightness + 0.03)
          : _hsl(ctHsl.hue, min(1.0, max(0.05, ctHsl.saturation)), 0.96), // 稍微提亮卡片
      cardBorderSoft: isDark
          ? _hsl(ctHsl.hue, max(ctHsl.saturation, 0.06), ctHsl.lightness + 0.10)
          : _hsl(hsl.hue, 0.30, 0.90), // 加深边框增加层级
      cardShadow: t.shadowColor,
      panelDivider: isDark
          ? _hsl(ctHsl.hue, max(ctHsl.saturation, 0.06), ctHsl.lightness + 0.10)
          : _hsl(hsl.hue, 0.40, 0.86),

      // ── 胶囊 ──
      pillBg: isDark
          ? _hsl(ctHsl.hue, max(ctHsl.saturation, 0.08), ctHsl.lightness + 0.04)
          : _hsl(bgHsl.hue, min(1.0, max(0.15, bgHsl.saturation)), 0.93),
      pillBorder: t.bgSoft,
      pillText: isDark
          ? _hsl(hsl.hue, 0.50, 0.70)
          : content,

      // ── 队列 ──
      queueActiveBg: isDark
          ? _hsl(hsl.hue, 0.20, 0.16)
          : _hsl(hsl.hue, 0.90, 0.93),
      queueActiveBorder: isDark
          ? _hsl(hsl.hue, 0.50, 0.40)
          : _hsl(hsl.hue, 0.80, 0.71),
      queueMuted: isDark
          ? _hsl(hsl.hue, 0.10, 0.50)
          : _hsl(hsl.hue, 0.20, 0.64),
      queueMutedSoft: isDark
          ? _hsl(hsl.hue, 0.08, 0.40)
          : _hsl(hsl.hue, 0.18, 0.78),

      // ── 杂项 ──
      iconMuted: isDark
          ? _hsl(hsl.hue, 0.08, 0.45)
          : _hsl(hsl.hue, 0.18, 0.68),
      sheetHandle: isDark
          ? const Color(0xFF6B7280)
          : const Color(0xFFA8A29E),
      modalBarrier: Colors.black.withValues(alpha: isDark ? 0.6 : 0.4),

      // ── 语义色（固定，不跟种子色走）──
      successBg: isDark
          ? const Color(0xFF052E16)
          : const Color(0xFFDBF5E8),
      successFg: isDark
          ? const Color(0xFF34D399)
          : const Color(0xFF059669),
      successBorder: isDark
          ? const Color(0xFF065F46)
          : const Color(0xFFD1FAE5),
      warningBg: isDark
          ? const Color(0xFF451A03)
          : const Color(0xFFFFF7ED),
      warningFg: isDark
          ? const Color(0xFFFBBF24)
          : const Color(0xFFD97706),
      warningBorder: isDark
          ? const Color(0xFF78350F)
          : const Color(0xFFFED7AA),

      // ── 导航 ──
      navBg: isDark
          ? _hsl(bgHsl.hue, min(1.0, max(bgHsl.saturation, 0.06) * 1.2), bgHsl.lightness + 0.02)
          : _hsl(hsl.hue, min(1.0, hsl.saturation * 1.1), 0.96),
      navSelectedBg: isDark
          ? _hsl(hsl.hue, 0.20, 0.18)
          : _hsl(hsl.hue, 0.90, 0.93),

      // ── 开关 ──
      switchActiveTrack: primary,
      switchInactiveTrack: isDark
          ? _hsl(ctHsl.hue, max(ctHsl.saturation, 0.06), ctHsl.lightness + 0.08)
          : _hsl(hsl.hue, 0.10, 0.85),
      switchThumb: isDark
          ? const Color(0xFFF9FAFB)
          : const Color(0xFFFFFDFB),

      // ── Profile 头像 ──
      headerAvatar: isDark ? container : seed.container,
      headerAvatarBorder: isDark
          ? _hsl(ctHsl.hue, max(ctHsl.saturation, 0.06), ctHsl.lightness + 0.12)
          : _hsl(hsl.hue, 0.1, 0.96),
      headerAvatarShadow: isDark
          ? Colors.black.withValues(alpha: 0.3)
          : primary.withValues(alpha: 0.1),

      // ── 分组/卡片容器 ──
      chevronColor: isDark
          ? _hsl(ctHsl.hue, max(ctHsl.saturation, 0.06), ctHsl.lightness + 0.15)
          : _hsl(hsl.hue, 0.10, 0.85),
      groupBg: isDark
          ? _hsl(bgHsl.hue, max(bgHsl.saturation, 0.06), bgHsl.lightness + 0.04)
          : _hsl(bgHsl.hue, min(max(0.1, bgHsl.saturation), 0.3), 0.98), // 卡片相对背景提亮到接近白但带有一丝特征色
      groupShadow: isDark
          ? Colors.black.withValues(alpha: 0.2)
          : Colors.black.withValues(alpha: 0.02),
    );
  }

  /// HSL 辅助构造
  static Color _hsl(double h, double s, double l) {
    return HSLColor.fromAHSL(
      1.0,
      h.clamp(0, 360),
      s.clamp(0, 1),
      l.clamp(0, 1),
    ).toColor();
  }

  // ─────────────────────────────────────────────
  //  ThemeExtension 必须实现
  // ─────────────────────────────────────────────

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
    Color? switchActiveTrack,
    Color? switchInactiveTrack,
    Color? switchThumb,
    Color? headerAvatar,
    Color? headerAvatarBorder,
    Color? headerAvatarShadow,
    Color? chevronColor,
    Color? groupBg,
    Color? groupShadow,
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
      switchActiveTrack: switchActiveTrack ?? this.switchActiveTrack,
      switchInactiveTrack: switchInactiveTrack ?? this.switchInactiveTrack,
      switchThumb: switchThumb ?? this.switchThumb,
      headerAvatar: headerAvatar ?? this.headerAvatar,
      headerAvatarBorder: headerAvatarBorder ?? this.headerAvatarBorder,
      headerAvatarShadow: headerAvatarShadow ?? this.headerAvatarShadow,
      chevronColor: chevronColor ?? this.chevronColor,
      groupBg: groupBg ?? this.groupBg,
      groupShadow: groupShadow ?? this.groupShadow,
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
      switchActiveTrack: Color.lerp(switchActiveTrack, other.switchActiveTrack, t)!,
      switchInactiveTrack: Color.lerp(switchInactiveTrack, other.switchInactiveTrack, t)!,
      switchThumb: Color.lerp(switchThumb, other.switchThumb, t)!,
      headerAvatar: Color.lerp(headerAvatar, other.headerAvatar, t)!,
      headerAvatarBorder: Color.lerp(headerAvatarBorder, other.headerAvatarBorder, t)!,
      headerAvatarShadow: Color.lerp(headerAvatarShadow, other.headerAvatarShadow, t)!,
      chevronColor: Color.lerp(chevronColor, other.chevronColor, t)!,
      groupBg: Color.lerp(groupBg, other.groupBg, t)!,
      groupShadow: Color.lerp(groupShadow, other.groupShadow, t)!,
    );
  }
}
