import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppPreferences extends ChangeNotifier {
  static AppPreferences? _instance;
  late SharedPreferences _prefs;

  // Keys
  static const String _kFadeOutEnabled = 'setting_fade_out_enabled';
  static const String _kAutoDetectClipboard = 'setting_auto_detect_clipboard';
  static const String _kThemePresetIndex = 'setting_theme_preset_index';
  static const String _kDarkMode = 'setting_dark_mode';
  static const String _kThemeMode = 'setting_theme_mode';

  AppPreferences._();

  static AppPreferences get instance => _instance!;

  static Future<void> init() async {
    if (_instance != null) return;
    final instance = AppPreferences._();
    instance._prefs = await SharedPreferences.getInstance();
    _instance = instance;
  }

  // --- 播放设置 ---

  bool get fadeOutEnabled => _prefs.getBool(_kFadeOutEnabled) ?? true;
  Future<void> setFadeOutEnabled(bool value) async {
    await _prefs.setBool(_kFadeOutEnabled, value);
    notifyListeners();
  }

  bool get autoDetectClipboard => _prefs.getBool(_kAutoDetectClipboard) ?? true;
  Future<void> setAutoDetectClipboard(bool value) async {
    await _prefs.setBool(_kAutoDetectClipboard, value);
    notifyListeners();
  }

  // --- 外观设置 ---

  /// 主题预设索引（对应 ThemeSeed.presets 的下标），默认 0 = 奶油晚霞
  int get themePresetIndex => _prefs.getInt(_kThemePresetIndex) ?? 0;
  Future<void> setThemePresetIndex(int value) async {
    await _prefs.setInt(_kThemePresetIndex, value);
  }

  /// 是否深色模式，默认 false
  bool get darkMode => _prefs.getBool(_kDarkMode) ?? false;
  Future<void> setDarkMode(bool value) async {
    await _prefs.setBool(_kDarkMode, value);
  }

  /// 主题模式：0=浅色 1=深色 2=跟随系统，默认跟随系统
  int get themeMode => _prefs.getInt(_kThemeMode) ?? 2;
  Future<void> setThemeMode(int value) async {
    await _prefs.setInt(_kThemeMode, value);
  }
}
