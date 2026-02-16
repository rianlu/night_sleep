import 'package:flutter/material.dart';

enum AmbienceType {
  rain,
  tide,
  fire,
  cicada,
  deepSea,
  meditation,
}

class AmbienceDefinition {
  final String id;
  final String name;
  final AmbienceType type;
  final String iconPath; // Or IconData if using standard icons for now
  final IconData iconData; // Using IconData for MVP as we don't have SVGs yet
  final String audioUrl;
  final Color baseColor;

  const AmbienceDefinition({
    required this.id,
    required this.name,
    required this.type,
    required this.iconData,
    this.iconPath = '',
    required this.audioUrl,
    this.baseColor = const Color(0xFFFFB13B),
  });

  static List<AmbienceDefinition> getAll() {
    return [
      const AmbienceDefinition(
        id: 'rain',
        name: '细雨',
        type: AmbienceType.rain,
        iconData: Icons.water_drop_outlined,
        // Wikimedia Commons (CC)
        audioUrl: 'https://upload.wikimedia.org/wikipedia/commons/3/3d/Rain.ogg',
      ),
      const AmbienceDefinition(
        id: 'tide',
        name: '潮汐',
        type: AmbienceType.tide,
        iconData: Icons.waves_rounded,
        // Wikimedia Commons (CC)
        audioUrl: 'https://upload.wikimedia.org/wikipedia/commons/f/f1/Oceanwavescrushing.ogg',
      ),
      const AmbienceDefinition(
        id: 'fire',
        name: '篝火',
        type: AmbienceType.fire,
        iconData: Icons.local_fire_department_outlined,
        // Wikimedia Commons (CC)
        audioUrl: 'https://upload.wikimedia.org/wikipedia/commons/b/b1/Campfire_sound_ambience.ogg',
      ),
      const AmbienceDefinition(
        id: 'cicada',
        name: '夏蝉',
        type: AmbienceType.cicada,
        iconData: Icons.bug_report_outlined,
        // Wikimedia Commons (CC)
        audioUrl: 'https://upload.wikimedia.org/wikipedia/commons/d/d5/Cicada_sound.ogg',
      ),
      const AmbienceDefinition(
        id: 'deepSea',
        name: '深海',
        type: AmbienceType.deepSea,
        iconData: Icons.scuba_diving_rounded,
        // Wikimedia Commons (CC)
        audioUrl: 'https://upload.wikimedia.org/wikipedia/commons/a/aa/White_noise.ogg',
      ),
      const AmbienceDefinition(
        id: 'meditation',
        name: '冥想',
        type: AmbienceType.meditation,
        iconData: Icons.self_improvement_rounded,
        // Wikimedia Commons (CC)
        audioUrl: 'https://upload.wikimedia.org/wikipedia/commons/1/17/Small_tibetan_singing_bowl.ogg',
      ),
    ];
  }
}
