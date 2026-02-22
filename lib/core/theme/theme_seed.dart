import 'package:flutter/material.dart';

/// 主题种子：浅色/深色各 4 个基准色，定义一套完整的双模式配色方案。
///
/// 所有色值均经过视觉校准，避免算法推导导致的"脏色"问题。
@immutable
class ThemeSeed {
  const ThemeSeed({
    required this.name,
    // Light mode
    required this.primary,
    required this.background,
    required this.container,
    required this.content,
    // Dark mode
    required this.darkPrimary,
    required this.darkBackground,
    required this.darkContainer,
    required this.darkContent,
  });

  final String name;

  // ── Light 模式 ──
  final Color primary;      // 核心动作色
  final Color background;   // 页面大背景
  final Color container;    // 胶囊/卡片容器底色
  final Color content;      // 主文字/图标

  // ── Dark 模式 ──
  final Color darkPrimary;
  final Color darkBackground;
  final Color darkContainer;
  final Color darkContent;

  // ── 5 套手工校准预设 ──

  static const creamSunset = ThemeSeed(
    name: '晚霞',
    primary:        Color(0xFFF59E0B),
    background:     Color(0xFFFFFBF2),
    container:      Color(0xFFFFEDD5),
    content:        Color(0xFF4B5563),
    darkPrimary:    Color(0xFFFBBF24),
    darkBackground: Color(0xFF1A1612),
    darkContainer:  Color(0xFF2D241D),
    darkContent:    Color(0xFFFDE68A),
  );

  static const lindenGreen = ThemeSeed(
    name: '森眠',
    primary:        Color(0xFF10B981),
    background:     Color(0xFFF0FDF4),
    container:      Color(0xFFDCFCE7),
    content:        Color(0xFF064E3B),
    darkPrimary:    Color(0xFF34D399),
    darkBackground: Color(0xFF0F1713),
    darkContainer:  Color(0xFF1A2E24),
    darkContent:    Color(0xFFD1FAE5),
  );

  static const lilacNight = ThemeSeed(
    name: '梦境',
    primary:        Color(0xFF8B5CF6),
    background:     Color(0xFFF5F3FF),
    container:      Color(0xFFEDE9FE),
    content:        Color(0xFF4C1D95),
    darkPrimary:    Color(0xFFA78BFA),
    darkBackground: Color(0xFF16141F),
    darkContainer:  Color(0xFF252136),
    darkContent:    Color(0xFFEDE9FE),
  );

  static const moonlightSea = ThemeSeed(
    name: '凉月',
    primary:        Color(0xFF0EA5E9),
    background:     Color(0xFFF0F9FF),
    container:      Color(0xFFE0F2FE),
    content:        Color(0xFF0C4A6E),
    darkPrimary:    Color(0xFF38BDF8),
    darkBackground: Color(0xFF0B1217),
    darkContainer:  Color(0xFF16252F),
    darkContent:    Color(0xFFE0F2FE),
  );

  static const dustFree = ThemeSeed(
    name: '无尘',
    primary:        Color(0xFF6B7280),
    background:     Color(0xFFF9FAFB),
    container:      Color(0xFFF3F4F6),
    content:        Color(0xFF1F2937),
    darkPrimary:    Color(0xFF9CA3AF),
    darkBackground: Color(0xFF111827),
    darkContainer:  Color(0xFF1F2937),
    darkContent:    Color(0xFFF3F4F6),
  );

  static const List<ThemeSeed> presets = [
    creamSunset,
    lindenGreen,
    lilacNight,
    moonlightSea,
    dustFree,
  ];
}
