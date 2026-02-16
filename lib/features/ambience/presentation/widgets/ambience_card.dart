import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:night_sleep/core/theme/promax_colors.dart';
import 'package:night_sleep/features/ambience/data/ambience_definition.dart';
import 'package:provider/provider.dart';
import 'package:night_sleep/features/ambience/logic/ambience_provider.dart';

class AmbienceCard extends StatelessWidget {
  final AmbienceDefinition definition;

  const AmbienceCard({super.key, required this.definition});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AmbienceProvider>();
    final isActive = provider.activeSoundIds.contains(definition.id);
    final isLoading = provider.loadingSoundIds.contains(definition.id);

    return GestureDetector(
      onTap: isLoading ? null : () => provider.toggleSound(definition),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: ProMaxColors.ambienceCardBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isActive ? ProMaxColors.ambienceAmber : Colors.white.withValues(alpha: 0.1),
            width: isActive ? 2 : 1,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: ProMaxColors.ambienceAmber.withValues(alpha: 0.2),
                    blurRadius: 15,
                    spreadRadius: 2,
                  )
                ]
              : [],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 1. Background Animations based on type
              if (isActive) _buildBackgroundAnimation(definition.type),

              // 2. Icon & Label
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isLoading)
                    const SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        valueColor: AlwaysStoppedAnimation<Color>(ProMaxColors.ambienceAmber),
                      ),
                    )
                  else
                    _buildIcon(isActive),
                  const SizedBox(height: 12),
                  Text(
                    definition.name,
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                      color: isActive ? ProMaxColors.ambienceAmber : ProMaxColors.stitchTextMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(bool isActive) {
    // Breathing animation for icon
    Widget icon = Icon(
      definition.iconData,
      size: 32,
      color: isActive ? ProMaxColors.ambienceAmber : ProMaxColors.stitchTextMuted,
    );
    
    if (isActive) {
      if (definition.type == AmbienceType.fire) {
        // Fire flicker
        return icon.animate(onPlay: (c) => c.repeat(reverse: true))
            .fade(begin: 0.7, end: 1.0, duration: 1200.ms, curve: Curves.easeInOut)
            .scale(begin: const Offset(0.95, 0.95), end: const Offset(1.05, 1.05));
      } else {
        // General breathing
        return icon.animate(onPlay: (c) => c.repeat(reverse: true))
            .scale(begin: const Offset(0.95, 0.95), end: const Offset(1.05, 1.05), duration: 2000.ms, curve: Curves.easeInOut);
      }
    }
    return icon;
  }

  Widget _buildBackgroundAnimation(AmbienceType type) {
    switch (type) {
      case AmbienceType.rain:
        return const _RainAnimation();
      case AmbienceType.tide:
      case AmbienceType.deepSea:
        return const _RippleAnimation();
      case AmbienceType.fire:
        return const _FireGlowAnimation();
      case AmbienceType.cicada:
      case AmbienceType.meditation:
        return const _PulseAnimation();
    }
  }
}

// --- Specific Animations ---

class _RainAnimation extends StatelessWidget {
  const _RainAnimation();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: List.generate(5, (index) {
        final random = Random(index);
        final duration = 1500 + random.nextInt(1000);
        final delay = random.nextInt(1000);
        
        return Positioned(
          top: -20,
          left: 0,
          right: 0, 
          bottom: 0,
          child: Align(
             alignment: Alignment(random.nextDouble() * 2 - 1, -1),
             child: Container(
               width: 2,
               height: 20 + random.nextDouble() * 20,
               decoration: BoxDecoration(
                 gradient: LinearGradient(
                   begin: Alignment.topCenter,
                   end: Alignment.bottomCenter,
                   colors: [
                     Colors.transparent, 
                     ProMaxColors.ambienceAmber.withValues(alpha: 0.3)
                   ],
                 ),
                 borderRadius: BorderRadius.circular(1),
               ),
             ),
          ),
        ).animate(onPlay: (c) => c.repeat())
         .moveY(begin: 0, end: 200, duration: duration.ms, delay: delay.ms, curve: Curves.linear)
         .fadeOut(begin: 1.0, delay: (duration * 0.8).ms, duration: (duration*0.2).ms); // Fade out at bottom
      }),
    );
  }
}

class _RippleAnimation extends StatelessWidget {
  const _RippleAnimation();

  @override
  Widget build(BuildContext context) {
     return Center(
       child: Container(
         width: 10, height: 10,
         decoration: BoxDecoration(
           shape: BoxShape.circle,
           border: Border.all(color: ProMaxColors.ambienceAmber.withValues(alpha: 0.2), width: 1),
         ),
       ).animate(onPlay: (c) => c.repeat())
        .scale(begin: const Offset(1,1), end: const Offset(15, 15), duration: 4000.ms)
        .fadeOut(curve: Curves.easeOut, duration: 4000.ms),
     );
  }
}

class _FireGlowAnimation extends StatelessWidget {
  const _FireGlowAnimation();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 60, height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              ProMaxColors.ambienceAmber.withValues(alpha: 0.15),
              Colors.transparent
            ],
          ),
        ),
      ).animate(onPlay: (c) => c.repeat(reverse: true))
       .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.5, 1.5), duration: 1500.ms)
       .fade(begin: 0.5, end: 1.0, duration: 1500.ms),
    );
  }
}

class _PulseAnimation extends StatelessWidget {
  const _PulseAnimation();
  @override
  Widget build(BuildContext context) {
      return Center(
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
             color: ProMaxColors.ambienceAmber.withValues(alpha: 0.03),
          ),
        ).animate(onPlay: (c) => c.repeat(reverse: true))
         .scale(begin: const Offset(0.0, 0.0), end: const Offset(10.0, 10.0), duration: 5000.ms),
      );
  }
}
