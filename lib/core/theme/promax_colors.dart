import 'package:flutter/material.dart';

class ProMaxColors {
  static const Color backgroundTop = Color(0xFF0F0B1E);
  static const Color backgroundBottom = Color(0xFF040405);
  static const Color accentPurple = Color(0xFFA18CD1);
  static const Color accentPink = Color(0xFFFBC2EB);
  static const Color glassWhite = Color(0x1AFFFFFF);
  static const Color softText = Color(0xFFB0B0B0);

  // --- Canonical Stitch Theme (User Defined) ---
  // "Deep Warm Coffee" & "Amber Gold"
  static const Color stitchPrimary = Color(0xFFFFB13B); // #FFB13B Amber Gold
  static const Color stitchBackground = Color(0xFF1A1412); // #1A1412 Deep Warm Coffee
  
  // Secondary / Functional Colors
  static const Color stitchCardBg = Color(0xFF2D241E); // Lighter coffee for cards
  static const Color stitchTextLight = Color(0xFFE8E0D9); // Warm white text
  static const Color stitchTextMuted = Color(0xFFB9A89D); // Muted warm text
  static const Color stitchDivider = Color(0xFF54453B);
  
  // --- Legacy / Alias Compatibility ---
  // These map legacy specific colors to the new Canonical Palette to enforce consistency
  // and fix build errors.
  
  // Cozy (Main)
  static const Color stitchCozyPrimary = stitchPrimary;
  static const Color stitchCozyBg = stitchBackground;
  static const Color stitchCozyCardBg = stitchCardBg;
  static const Color stitchCozyAccent = stitchPrimary;
  static const Color stitchCozyTextLight = stitchTextLight;
  static const Color stitchCozyTextMuted = stitchTextMuted;
  
  // Mini Player (Previously light, now dark to match theme. Usages must be updated for contrast)
  static const Color stitchCozyMiniPlayerBg = stitchCardBg; 
  
  // Fluid Parser
  static const Color stitchFluidPrimary = stitchPrimary;
  static const Color stitchFluidBg = stitchBackground;
  static const Color stitchFluidCoffeeDark = stitchCardBg; // Mapped
  
  // Sleep Report (Previously specific dark palette, now unified)
  static const Color stitchReportBg = stitchBackground;
  static const Color stitchReportCardBg = stitchCardBg;
  static const Color stitchReportAccent = stitchPrimary;
}
