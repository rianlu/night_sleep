import 'package:animated_theme_switcher/animated_theme_switcher.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:night_sleep/core/constants/app_constants.dart';
import 'package:night_sleep/core/theme/theme_controller.dart';
import 'package:night_sleep/core/theme/theme_seed.dart';
import 'package:night_sleep/features/home/presentation/main_navigation_screen.dart';
import 'package:night_sleep/features/player/data/audio_player_handler.dart';
import 'package:night_sleep/core/utils/app_preferences.dart';
import 'package:provider/provider.dart';

late AudioHandler audioHandler;
final AudioHandler _fallbackAudioHandler = _SilentAudioHandler();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AppPreferences.init();

  audioHandler = await AudioService.init(
    builder: () => AudioPlayerHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.nightsleep.channel.audio',
      androidNotificationChannelName: 'NightSleep Audio',
      androidNotificationOngoing: true,
    ),
  );

  // 初始化 AudioHandler 的默认配置
  if (audioHandler is AudioPlayerHandler) {
    (audioHandler as AudioPlayerHandler).setFadeOutEnabled(
      AppPreferences.instance.fadeOutEnabled,
    );
  }

  runApp(const NightSleepApp());
}

class NightSleepApp extends StatefulWidget {
  const NightSleepApp({super.key});

  @override
  State<NightSleepApp> createState() => _NightSleepAppState();
}

class _NightSleepAppState extends State<NightSleepApp>
    with WidgetsBindingObserver {
  late final ThemeController _themeController;
  final AppPreferences _prefs = AppPreferences.instance;

  AudioHandler _resolveAudioHandler() {
    try {
      return audioHandler;
    } catch (_) {
      return _fallbackAudioHandler;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    final presetIndex = _prefs.themePresetIndex.clamp(
      0,
      ThemeSeed.presets.length - 1,
    );
    final initialSeed = ThemeSeed.presets[presetIndex];
    final modeIndex = _prefs.themeMode.clamp(
      0,
      ThemeAppearanceMode.values.length - 1,
    );
    final initialMode = ThemeAppearanceMode.values[modeIndex];
    final systemBrightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;

    _themeController = ThemeController(
      initialSeed: initialSeed,
      initialMode: initialMode,
      initialSystemBrightness: systemBrightness,
    );
  }

  @override
  void didChangePlatformBrightness() {
    _themeController.setSystemBrightness(
      WidgetsBinding.instance.platformDispatcher.platformBrightness,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _themeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final resolvedHandler = _resolveAudioHandler();
    return MultiProvider(
      providers: [
        Provider<AudioHandler>(create: (_) => resolvedHandler),
        ChangeNotifierProvider.value(value: AppPreferences.instance),
        ChangeNotifierProvider.value(value: _themeController),
      ],
      child: Consumer<ThemeController>(
        builder: (context, controller, _) => ThemeProvider(
          initTheme: controller.themeData,
          duration: Duration.zero,
          builder: (context, theme) {
            return MaterialApp(
              title: AppConstants.appName,
              theme: theme,
              themeAnimationDuration:
                  Duration.zero, // Disable native AnimatedTheme
              home: const MainNavigationScreen(),
            );
          },
        ),
      ),
    );
  }
}

class _SilentAudioHandler extends BaseAudioHandler
    with QueueHandler, SeekHandler {
  _SilentAudioHandler() {
    queue.add([]);
    mediaItem.add(null);
    playbackState.add(
      PlaybackState(
        controls: [MediaControl.play, MediaControl.pause],
        systemActions: {MediaAction.seek},
        processingState: AudioProcessingState.idle,
        playing: false,
        updatePosition: Duration.zero,
      ),
    );
  }
}
