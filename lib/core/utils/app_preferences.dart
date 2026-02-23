import 'dart:convert';

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
  static const String _kPlaybackQueue = 'playback_queue_v1';

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

  // --- 播放队列持久化 ---
  List<Map<String, dynamic>> get playbackQueue {
    final raw = _prefs.getString(_kPlaybackQueue);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map((e) => e.map((k, v) => MapEntry(k.toString(), v)))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> setPlaybackQueue(List<Map<String, dynamic>> items) async {
    await _prefs.setString(_kPlaybackQueue, jsonEncode(items));
  }
}
