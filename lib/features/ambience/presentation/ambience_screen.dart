import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:night_sleep/core/theme/promax_colors.dart';
import 'package:night_sleep/features/ambience/data/ambience_definition.dart';
import 'package:night_sleep/features/ambience/logic/ambience_provider.dart';
import 'package:night_sleep/features/ambience/presentation/widgets/ambience_card.dart';
import 'package:provider/provider.dart';

class AmbienceScreen extends StatelessWidget {
  const AmbienceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sounds = AmbienceDefinition.getAll();
    final provider = context.watch<AmbienceProvider>();

    return Scaffold(
      backgroundColor: ProMaxColors.ambienceBg,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "氛围空间",
                        style: GoogleFonts.manrope(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: ProMaxColors.stitchTextLight,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "定制你的专属睡眠声场",
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          color: ProMaxColors.stitchTextMuted,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: ProMaxColors.stitchCardBg,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                       icon: const Icon(Icons.tune_rounded, color: ProMaxColors.stitchTextMuted),
                       onPressed: () {
                         // Settings? Or Reset?
                         provider.stopAll();
                       },
                    ),
                  ),
                ],
              ),
            ),
            
            // Grid
            Expanded(
              child: GridView.count(
                crossAxisCount: 3,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                childAspectRatio: 0.9,
                children: sounds.map((def) => AmbienceCard(definition: def)).toList(),
              ),
            ),
            
            // Control Panel
            Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: ProMaxColors.ambienceCardBg,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                   BoxShadow(
                     color: Colors.black.withValues(alpha: 0.2), 
                     blurRadius: 20, 
                     offset: const Offset(0, 10)
                   ),
                ],
              ),
              child: Column(
                children: [
                  // Volume
                  Row(
                    children: [
                      const Icon(Icons.volume_down_rounded, color: ProMaxColors.stitchTextMuted),
                      const SizedBox(width: 12),
                      Text("氛围音量", style: GoogleFonts.manrope(color: ProMaxColors.stitchTextLight, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      Text("${(provider.masterVolume * 100).toInt()}%", 
                           style: GoogleFonts.manrope(color: ProMaxColors.ambienceAmber, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: ProMaxColors.ambienceAmber,
                      inactiveTrackColor: ProMaxColors.ambienceAmber.withValues(alpha: 0.2),
                      thumbColor: ProMaxColors.ambienceAmber,
                      overlayColor: ProMaxColors.ambienceAmber.withValues(alpha: 0.1),
                    ),
                    child: Slider(
                      value: provider.masterVolume,
                      onChanged: (v) => provider.setMasterVolume(v),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Divider(color: ProMaxColors.stitchDivider, height: 1),
                  const SizedBox(height: 20),
                  
                  // Mix Toggle
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.layers_rounded, color: ProMaxColors.stitchTextMuted, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("与 B 站音频叠加播放", 
                                 style: GoogleFonts.manrope(color: ProMaxColors.stitchTextLight, fontWeight: FontWeight.bold)),
                             const SizedBox(height: 4),
                             Text("开启后可作为视频背景白噪音", 
                                  style: GoogleFonts.manrope(color: ProMaxColors.stitchTextMuted, fontSize: 11)),
                          ],
                        ),
                      ),
                      Switch(
                        value: provider.mixWithMainAudio,
                        onChanged: (v) => provider.setMixWithMainAudio(v),
                        activeColor: ProMaxColors.ambienceAmber,
                        activeTrackColor: ProMaxColors.ambienceAmber.withValues(alpha: 0.2),
                        inactiveThumbColor: ProMaxColors.stitchTextMuted,
                        inactiveTrackColor: Colors.white.withValues(alpha: 0.1),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // "Now Playing" Indicator (If sounds active)
            if (provider.isPlaying)
               Container(
                 margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                 padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                 decoration: BoxDecoration(
                   color: Colors.black.withValues(alpha: 0.5),
                   borderRadius: BorderRadius.circular(40),
                   border: Border.all(color: ProMaxColors.stitchDivider),
                 ),
                 child: Row(
                   children: [
                     Container(
                       width: 32, height: 32,
                       decoration: const BoxDecoration(
                         shape: BoxShape.circle,
                         color: ProMaxColors.ambienceCardBg,
                       ),
                       child: const Icon(Icons.equalizer_rounded, color: ProMaxColors.ambienceAmber, size: 16),
                     ),
                     const SizedBox(width: 12),
                     Expanded(
                       child: Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           Text("当前混音", style: GoogleFonts.manrope(color: Colors.white, fontSize: 12)),
                           Text(
                             _getActiveSoundNames(sounds, provider.activeSoundIds),
                             maxLines: 1, overflow: TextOverflow.ellipsis,
                             style: GoogleFonts.manrope(color: ProMaxColors.stitchTextMuted, fontSize: 11),
                           ),
                         ],
                       ),
                     ),
                     IconButton(
                       icon: const Icon(Icons.pause_circle_rounded, color: ProMaxColors.ambienceAmber, size: 32),
                       onPressed: () => provider.stopAll(),
                     ),
                   ],
                 ),
               )
             else 
               const SizedBox(height: 80), // Spacer
               
             const SizedBox(height: 80), // Nav Bar space
          ],
        ),
      ),
    );
  }

  String _getActiveSoundNames(List<AmbienceDefinition> all, Set<String> activeIds) {
    if (activeIds.isEmpty) return "";
    return all.where((d) => activeIds.contains(d.id)).map((d) => d.name).join(" + ") + " (播放中)";
  }
}
