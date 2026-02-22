import 'package:flutter/material.dart';
import 'package:night_sleep/core/theme/app_theme.dart';
import 'package:night_sleep/core/theme/theme_seed.dart';
import 'package:night_sleep/core/theme/theme_tokens.dart';
import 'package:night_sleep/core/utils/app_preferences.dart';

/// 主题控制器：管理当前主题预设和深色模式状态。
///
/// 通过 [ChangeNotifier] 通知 UI 重建，配合 [Consumer<ThemeController>]
/// 在 MaterialApp 层实时切换主题。
class ThemeController extends ChangeNotifier {
  ThemeController({
    ThemeSeed? initialSeed,
    Brightness? initialBrightness,
  })  : _seed = initialSeed ?? ThemeSeed.creamSunset,
        _brightness = initialBrightness ?? Brightness.light;

  ThemeSeed _seed;
  Brightness _brightness;

  // ── 对外只读属性 ──

  ThemeSeed get seed => _seed;
  bool get isDark => _brightness == Brightness.dark;
  Brightness get brightness => _brightness;

  ThemeTokens get tokens => ThemeTokens.generate(_seed, _brightness);
  ThemeData get themeData => AppTheme.build(tokens, _seed, _brightness);

  // ── 主题切换 ──

  /// 切换为指定主题预设
  void setTheme(ThemeSeed preset) {
    if (_seed == preset) return;
    _seed = preset;
    _persistSeed();
    notifyListeners();
  }

  /// 切换深色/浅色模式
  void toggleBrightness() {
    _brightness = _brightness == Brightness.light
        ? Brightness.dark
        : Brightness.light;
    _persistBrightness();
    notifyListeners();
  }

  // ── 持久化 ──

  void _persistSeed() {
    final index = ThemeSeed.presets.indexOf(_seed);
    if (index >= 0) {
      AppPreferences.instance.setThemePresetIndex(index);
    }
  }

  void _persistBrightness() {
    AppPreferences.instance.setDarkMode(_brightness == Brightness.dark);
  }
}
