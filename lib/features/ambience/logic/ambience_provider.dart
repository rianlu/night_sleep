import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:night_sleep/features/ambience/data/ambience_definition.dart';
import 'package:audio_service/audio_service.dart';

class AmbienceProvider extends ChangeNotifier {
  final AudioHandler _audioHandler;
  
  // State
  final Set<String> _activeSoundIds = {};
  final Set<String> _loadingSoundIds = {};
  double _masterVolume = 0.45;
  bool _mixWithMainAudio = false;
  
  // Players: ID -> Player
  final Map<String, AudioPlayer> _players = {};
  
  AmbienceProvider(this._audioHandler);

  Set<String> get activeSoundIds => _activeSoundIds;
  Set<String> get loadingSoundIds => _loadingSoundIds;
  double get masterVolume => _masterVolume;
  bool get mixWithMainAudio => _mixWithMainAudio;
  bool get isPlaying => _activeSoundIds.isNotEmpty;

  /// Toggle a sound on/off
  Future<void> toggleSound(AmbienceDefinition definition) async {
    if (_loadingSoundIds.contains(definition.id)) return;

    if (_activeSoundIds.contains(definition.id)) {
      await _stopSound(definition.id);
    } else {
      await _playSound(definition);
    }
  }

  /// Activate a sound
  Future<void> _playSound(AmbienceDefinition definition) async {
    _loadingSoundIds.add(definition.id);

    // Optimistic Update: Mark as active immediately so UI responds
    _activeSoundIds.add(definition.id);
    notifyListeners();

    // 1. Create or reuse player
    AudioPlayer player;
    if (_players.containsKey(definition.id)) {
      player = _players[definition.id]!;
    } else {
      player = AudioPlayer();
      _players[definition.id] = player;
      // Configure loop
      await player.setLoopMode(LoopMode.one);
    }

    // 2. Load and play
    try {
      if (player.audioSource == null) {
        print("NightSleep: Loading ambience ${definition.name} from ${definition.audioUrl}");
        await player
            .setUrl(definition.audioUrl)
            .timeout(const Duration(seconds: 12));
      }

      // Only pause main audio after ambience is prepared successfully.
      if (!_mixWithMainAudio) {
        await _audioHandler.pause();
      }

      await player.setVolume(_masterVolume);
      await player.play();
      print("NightSleep: Playing ambience ${definition.name}");
      
    } catch (e) {
      print("NightSleep: Error playing ambience ${definition.name}: $e");
      // Revert state on error
      _activeSoundIds.remove(definition.id);
    } finally {
      _loadingSoundIds.remove(definition.id);
      notifyListeners();
    }
  }

  /// Stop a sound
  Future<void> _stopSound(String id) async {
    _activeSoundIds.remove(id);
    _loadingSoundIds.remove(id);
    notifyListeners();
    
    if (_players.containsKey(id)) {
      final player = _players[id]!;
      await player.stop();
    }
  }

  /// Stop all sounds
  Future<void> stopAll() async {
    for (var id in _activeSoundIds.toList()) {
      if (_players.containsKey(id)) {
        await _players[id]!.stop();
      }
    }
    _activeSoundIds.clear();
    _loadingSoundIds.clear();
    notifyListeners();
  }

  /// Update Master Volume
  void setMasterVolume(double volume) {
    _masterVolume = volume;
    // Update all active players
    for (var player in _players.values) {
      player.setVolume(volume);
    }
    notifyListeners();
  }

  /// Toggle Mix Mode
  void setMixWithMainAudio(bool enable) {
    _mixWithMainAudio = enable;
    if (!enable && _activeSoundIds.isNotEmpty) {
      // If turning OFF mix while ambience is playing, pause main audio
      _audioHandler.pause();
    }
    notifyListeners();
  }
  
  @override
  void dispose() {
    for (var player in _players.values) {
      player.dispose();
    }
    super.dispose();
  }
}
