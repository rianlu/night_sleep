import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppPreferences extends ChangeNotifier {
  static AppPreferences? _instance;
  late SharedPreferences _prefs;

  // Keys
  static const String _kFadeOutEnabled = 'setting_fade_out_enabled';
  static const String _kAutoDetectClipboard = 'setting_auto_detect_clipboard';

  AppPreferences._();

  static AppPreferences get instance => _instance!;

  static Future<void> init() async {
    if (_instance != null) return;
    final instance = AppPreferences._();
    instance._prefs = await SharedPreferences.getInstance();
    _instance = instance;
  }

  // --- Settings ---

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
}
