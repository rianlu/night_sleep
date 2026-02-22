import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:night_sleep/core/theme/app_palette.dart';
import 'package:night_sleep/core/theme/theme_seed.dart';
import 'package:night_sleep/core/theme/theme_tokens.dart';

class AppTheme {
  static ThemeData build(ThemeTokens t, ThemeSeed seed, Brightness brightness) {
    final baseTextTheme = GoogleFonts.notoSansScTextTheme().apply(
      bodyColor: t.textPrimary,
      displayColor: t.textPrimary,
    );
    final textTheme = baseTextTheme;

    final isDark = brightness == Brightness.dark;
    final colorScheme = isDark
        ? ColorScheme.dark(
            primary: t.accent,
            onPrimary: t.accentOn,
            secondary: t.bgSoft,
            onSecondary: t.pillFg,
            surface: t.bgCard,
            onSurface: t.textPrimary,
            outline: t.border,
          )
        : ColorScheme.light(
            primary: t.accent,
            onPrimary: t.accentOn,
            secondary: t.bgSoft,
            onSecondary: t.pillFg,
            surface: t.bgCard,
            onSurface: t.textPrimary,
            outline: t.border,
          );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      visualDensity: VisualDensity.standard,
      scaffoldBackgroundColor: t.bgBase,
      colorScheme: colorScheme,
      textTheme: textTheme,
      splashColor: t.accent.withValues(alpha: 0.1),
      highlightColor: t.accent.withValues(alpha: 0.06),
      appBarTheme: AppBarTheme(
        backgroundColor: t.bgBase,
        elevation: 0,
        foregroundColor: t.textPrimary,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: t.textPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        color: t.bgCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(t.radiusCard),
          side: BorderSide(color: t.border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: t.bgCard,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        hintStyle: TextStyle(color: t.textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(t.radiusControl),
          borderSide: BorderSide(color: t.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(t.radiusControl),
          borderSide: BorderSide(color: t.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(t.radiusControl),
          borderSide: BorderSide(color: t.accent, width: 1.4),
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: t.accent,
        inactiveTrackColor: t.progressInactive,
        thumbColor: t.bgCard,
        overlayColor: t.accent.withValues(alpha: 0.1),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: t.accent,
          foregroundColor: t.accentOn,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(t.radiusControl),
          ),
          minimumSize: const Size.fromHeight(48),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: t.textSecondary,
          side: BorderSide(color: t.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(t.radiusPill),
          ),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: t.bgBase,
        selectedItemColor: t.accent,
        unselectedItemColor: t.navInactive,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: _CreamSunsetPageTransitionsBuilder(),
          TargetPlatform.iOS: _CreamSunsetPageTransitionsBuilder(),
          TargetPlatform.macOS: _CreamSunsetPageTransitionsBuilder(),
          TargetPlatform.windows: _CreamSunsetPageTransitionsBuilder(),
          TargetPlatform.linux: _CreamSunsetPageTransitionsBuilder(),
        },
      ),
      extensions: [AppPalette.fromTokens(t, seed, brightness)],
    );
  }
}

class _CreamSunsetPageTransitionsBuilder extends PageTransitionsBuilder {
  const _CreamSunsetPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.02),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}
