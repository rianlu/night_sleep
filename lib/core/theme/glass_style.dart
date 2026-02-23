import 'dart:ui';

import 'package:flutter/material.dart';

enum GlassLevel { nav, snackbar, sheet }

class GlassStyle {
  const GlassStyle._();

  static double blurSigma(
    Brightness brightness, {
    GlassLevel level = GlassLevel.nav,
  }) {
    final isDark = brightness == Brightness.dark;
    switch (level) {
      case GlassLevel.nav:
      case GlassLevel.snackbar:
        return isDark ? 30 : 25;
      case GlassLevel.sheet:
        return isDark ? 40 : 30;
    }
  }

  static double opacity(
    Brightness brightness, {
    GlassLevel level = GlassLevel.nav,
  }) {
    final isDark = brightness == Brightness.dark;
    switch (level) {
      case GlassLevel.nav:
      case GlassLevel.snackbar:
        return isDark ? 0.65 : 0.75;
      case GlassLevel.sheet:
        return isDark ? 0.65 : 0.80;
    }
  }

  static BorderSide border(Brightness brightness) {
    return BorderSide(
      color: Colors.white.withValues(
        alpha: brightness == Brightness.dark ? 0.10 : 0.8,
      ),
      width: 0.5,
    );
  }

  static ImageFilter blurFilter(
    Brightness brightness, {
    GlassLevel level = GlassLevel.nav,
  }) {
    final sigma = blurSigma(brightness, level: level);
    return ImageFilter.blur(sigmaX: sigma, sigmaY: sigma);
  }
}
