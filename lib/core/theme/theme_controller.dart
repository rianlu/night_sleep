import 'package:flutter/material.dart';
import 'package:night_sleep/core/theme/app_theme.dart';
import 'package:night_sleep/core/theme/theme_seed.dart';
import 'package:night_sleep/core/theme/theme_tokens.dart';
import 'package:night_sleep/core/utils/app_preferences.dart';

enum ThemeAppearanceMode { light, dark, system }

/// 主题控制器：管理当前主题预设和深色模式状态。
///
/// 通过 [ChangeNotifier] 通知 UI 重建，配合 [Consumer<ThemeController>]
/// 在 MaterialApp 层实时切换主题。
class ThemeController extends ChangeNotifier {
  ThemeController({
    ThemeSeed? initialSeed,
    Brightness? initialSystemBrightness,
    ThemeAppearanceMode? initialMode,
  }) : _seed = initialSeed ?? ThemeSeed.creamSunset,
       _systemBrightness = initialSystemBrightness ?? Brightness.light,
       _mode = initialMode ?? ThemeAppearanceMode.system;

  ThemeSeed _seed;
  Brightness _systemBrightness;
  ThemeAppearanceMode _mode;

  // ── 对外只读属性 ──

  ThemeSeed get seed => _seed;
  ThemeAppearanceMode get mode => _mode;
  Brightness get effectiveBrightness {
    switch (_mode) {
      case ThemeAppearanceMode.light:
        return Brightness.light;
      case ThemeAppearanceMode.dark:
        return Brightness.dark;
      case ThemeAppearanceMode.system:
        return _systemBrightness;
    }
  }

  bool get isDark => effectiveBrightness == Brightness.dark;

  ThemeTokens get tokens => ThemeTokens.generate(_seed, effectiveBrightness);
  ThemeData get themeData => AppTheme.build(tokens, _seed, effectiveBrightness);

  // ── 主题切换 ──

  /// 切换为指定主题预设
  void setTheme(ThemeSeed preset) {
    if (_seed == preset) return;
    _seed = preset;
    _persistSeed();
    notifyListeners();
  }

  /// 设置外观模式：浅色 / 深色 / 跟随系统
  void setAppearanceMode(ThemeAppearanceMode mode) {
    if (_mode == mode) return;
    _mode = mode;
    _persistMode();
    notifyListeners();
  }

  /// 兼容旧调用：在浅/深之间切换，并退出“跟随系统”模式。
  void toggleBrightness() {
    setAppearanceMode(
      isDark ? ThemeAppearanceMode.light : ThemeAppearanceMode.dark,
    );
  }

  /// 系统亮度变化时通知（仅跟随系统模式会触发主题更新）。
  void setSystemBrightness(Brightness brightness) {
    if (_systemBrightness == brightness) return;
    _systemBrightness = brightness;
    if (_mode == ThemeAppearanceMode.system) {
      notifyListeners();
    }
  }

  // ── 持久化 ──

  void _persistSeed() {
    final index = ThemeSeed.presets.indexOf(_seed);
    if (index >= 0) {
      AppPreferences.instance.setThemePresetIndex(index);
    }
  }

  void _persistMode() {
    AppPreferences.instance.setThemeMode(_mode.index);
    if (_mode != ThemeAppearanceMode.system) {
      AppPreferences.instance.setDarkMode(_mode == ThemeAppearanceMode.dark);
    }
  }
}
