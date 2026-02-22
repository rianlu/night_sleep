import 'dart:math';

import 'package:flutter/material.dart';
import 'package:night_sleep/core/theme/theme_seed.dart';

/// 设计 Token：从 [ThemeSeed] 的手工校准基准色 + [Brightness] 生成全部细粒度颜色。
///
/// Light 模式使用 seed 的浅色值，Dark 模式使用 seed 的深色值。
/// 辅助 token（阴影、边框等）仍从核心 4 token 算法派生。
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
    required this.shadowColor,
    required this.radiusCard,
    required this.radiusControl,
    required this.radiusPill,
    required this.spacingBase,
    required this.pagePadding,
  });

  // ── 颜色 ──
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
  final Color shadowColor;

  // ── 间距 / 圆角 ──
  final double radiusCard;
  final double radiusControl;
  final double radiusPill;
  final double spacingBase;
  final double pagePadding;

  // ─────────────────────────────────────────────
  //  核心工厂：从手工校准的种子值生成全部 token
  // ─────────────────────────────────────────────

  static ThemeTokens generate(ThemeSeed seed, Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    // ── 核心 4 token：直接从种子读取 ──
    final primary    = isDark ? seed.darkPrimary    : seed.primary;
    final background = isDark ? seed.darkBackground : seed.background;
    final container  = isDark ? seed.darkContainer  : seed.container;
    final content    = isDark ? seed.darkContent    : seed.content;

    final hsl = HSLColor.fromColor(primary);
    final bgHsl = HSLColor.fromColor(background);
    final ctHsl = HSLColor.fromColor(container);

    // ── 背景层 ──
    final bgBase = background;

    // Card: dark 用 container, light 用纯白
    final bgCard = isDark ? container : Colors.white;

    // Soft: container 就是 soft 层
    final bgSoft = container;

    // ── 强调色 ──
    final accent = primary;
    final accentOn = _contrastForeground(accent);

    // ── 文字 ──
    final textPrimary = content;

    // textSecondary: content 色的淡化版
    final contentHsl = HSLColor.fromColor(content);
    final textSecondary = isDark
        ? _hsl(contentHsl.hue, min(contentHsl.saturation, 0.15), 0.55)
        : _hsl(contentHsl.hue, 0.08, 0.55);

    // ── 辅助色 ──
    final pillFg = isDark
        ? _hsl(hsl.hue, 0.50, 0.70)
        : content;

    // progressInactive: 进度条底色
    final progressInactive = isDark
        ? _hsl(bgHsl.hue, max(bgHsl.saturation, 0.10), bgHsl.lightness + 0.12)
        : _hsl(ctHsl.hue, min(ctHsl.saturation, 0.50), 0.92);

    // navInactive
    final navInactive = isDark
        ? const Color(0xFF6B7280)
        : const Color(0xFFD1D5DB);

    // border
    final border = isDark
        ? _hsl(bgHsl.hue, max(bgHsl.saturation, 0.06), bgHsl.lightness + 0.14)
        : _hsl(ctHsl.hue, min(ctHsl.saturation, 0.30), 0.90);

    // shadow
    final shadowColor = isDark
        ? Colors.black.withValues(alpha: 0.30)
        : primary.withValues(alpha: 0.08);

    return ThemeTokens(
      bgBase: bgBase,
      bgCard: bgCard,
      bgSoft: bgSoft,
      textPrimary: textPrimary,
      textSecondary: textSecondary,
      accent: accent,
      accentOn: accentOn,
      pillFg: pillFg,
      progressInactive: progressInactive,
      navInactive: navInactive,
      border: border,
      shadowColor: shadowColor,
      radiusCard: 24,
      radiusControl: 16,
      radiusPill: 999,
      spacingBase: 8,
      pagePadding: 20,
    );
  }

  // ─────────────────────────────────────────────
  //  辅助函数
  // ─────────────────────────────────────────────

  /// 从 HSL 值生成 Color，参数范围：H [0,360], S [0,1], L [0,1]
  static Color _hsl(double h, double s, double l) {
    return HSLColor.fromAHSL(1.0, h.clamp(0, 360), s.clamp(0, 1), l.clamp(0, 1)).toColor();
  }

  /// 根据背景色亮度自动选择深色/浅色前景文字
  static Color _contrastForeground(Color bg) {
    return bg.computeLuminance() > 0.45
        ? const Color(0xFF1F1F1F)
        : Colors.white;
  }
}
