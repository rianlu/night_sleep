import 'package:flutter/material.dart';
import 'package:night_sleep/core/theme/app_theme.dart';
import 'package:night_sleep/core/theme/theme_seed.dart';
import 'package:night_sleep/core/theme/theme_tokens.dart';

class ThemeController extends ChangeNotifier {
  ThemeController({ThemeSeed? initialSeed})
      : _seed = initialSeed ?? ThemeSeed.creamSunset;

  ThemeSeed _seed;

  ThemeSeed get seed => _seed;

  ThemeTokens get tokens => ThemeTokens.creamSunset(_seed);

  ThemeData get themeData => AppTheme.build(tokens);

  void setPrimaryColor(Color color) {
    _seed = _seed.copyWith(primary: color);
    notifyListeners();
  }
}
