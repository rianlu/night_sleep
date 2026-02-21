import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:night_sleep/core/constants/app_constants.dart';
import 'package:night_sleep/core/theme/app_theme.dart';
import 'package:night_sleep/core/theme/theme_controller.dart';
import 'package:night_sleep/features/home/presentation/main_navigation_screen.dart';
import 'package:night_sleep/features/player/data/audio_player_handler.dart';
import 'package:provider/provider.dart';

late AudioHandler audioHandler;
final AudioHandler _fallbackAudioHandler = _SilentAudioHandler();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  audioHandler = await AudioService.init(
    builder: () => AudioPlayerHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.nightsleep.channel.audio',
      androidNotificationChannelName: 'NightSleep Audio',
      androidNotificationOngoing: true,
    ),
  );

  runApp(const NightSleepApp());
}

class NightSleepApp extends StatelessWidget {
  const NightSleepApp({super.key});

  AudioHandler _resolveAudioHandler() {
    try {
      return audioHandler;
    } catch (_) {
      return _fallbackAudioHandler;
    }
  }

  @override
  Widget build(BuildContext context) {
    final resolvedHandler = _resolveAudioHandler();
    return MultiProvider(
      providers: [
        Provider<AudioHandler>(create: (_) => resolvedHandler),
        ChangeNotifierProvider(create: (_) => ThemeController()),
      ],
      child: Consumer<ThemeController>(
        builder: (context, controller, _) => MaterialApp(
          title: AppConstants.appName,
          theme: AppTheme.build(controller.tokens),
          home: const MainNavigationScreen(),
        ),
      ),
    );
  }
}

class _SilentAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  _SilentAudioHandler() {
    queue.add([]);
    mediaItem.add(null);
    playbackState.add(PlaybackState(
      controls: [MediaControl.play, MediaControl.pause],
      systemActions: {MediaAction.seek},
      processingState: AudioProcessingState.idle,
      playing: false,
      updatePosition: Duration.zero,
    ));
  }
}
