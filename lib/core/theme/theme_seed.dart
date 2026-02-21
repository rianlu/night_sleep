import 'package:flutter/material.dart';

@immutable
class ThemeSeed {
  const ThemeSeed({
    required this.primary,
    this.highContrast = false,
  });

  final Color primary;
  final bool highContrast;

  ThemeSeed copyWith({Color? primary, bool? highContrast}) {
    return ThemeSeed(
      primary: primary ?? this.primary,
      highContrast: highContrast ?? this.highContrast,
    );
  }

  static const ThemeSeed creamSunset = ThemeSeed(
    primary: Color(0xFFF59E0B),
    highContrast: false,
  );
}
