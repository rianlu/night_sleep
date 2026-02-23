import 'package:animated_theme_switcher/animated_theme_switcher.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:night_sleep/core/constants/app_constants.dart';
import 'package:night_sleep/core/theme/app_palette.dart';
import 'package:night_sleep/core/theme/theme_controller.dart';
import 'package:night_sleep/core/theme/theme_seed.dart';
import 'package:night_sleep/features/home/presentation/main_navigation_screen.dart';
import 'package:night_sleep/features/player/data/audio_player_handler.dart';
import 'package:night_sleep/core/utils/app_preferences.dart';
import 'package:provider/provider.dart';

late AudioHandler audioHandler;
final AudioHandler _fallbackAudioHandler = _SilentAudioHandler();

Future<void> main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

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
    final prefs = AppPreferences.instance;
    final presetIndex = prefs.themePresetIndex.clamp(
      0,
      ThemeSeed.presets.length - 1,
    );
    final initialSeed = ThemeSeed.presets[presetIndex];
    final initialBrightness = prefs.darkMode
        ? Brightness.dark
        : Brightness.light;

    return MultiProvider(
      providers: [
        Provider<AudioHandler>(create: (_) => resolvedHandler),
        ChangeNotifierProvider.value(value: AppPreferences.instance),
        ChangeNotifierProvider(
          create: (_) => ThemeController(
            initialSeed: initialSeed,
            initialBrightness: initialBrightness,
          ),
        ),
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
              home: const _StartupShell(),
            );
          },
        ),
      ),
    );
  }
}

class _StartupShell extends StatefulWidget {
  const _StartupShell();

  @override
  State<_StartupShell> createState() => _StartupShellState();
}

class _StartupShellState extends State<_StartupShell> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      setState(() => _ready = true);
      FlutterNativeSplash.remove();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<AppPalette>()!;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 380),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        final fade = CurvedAnimation(parent: animation, curve: Curves.easeOut);
        final scale = Tween<double>(begin: 0.985, end: 1.0).animate(fade);
        return FadeTransition(
          opacity: fade,
          child: ScaleTransition(scale: scale, child: child),
        );
      },
      child: _ready
          ? const MainNavigationScreen(key: ValueKey('main'))
          : Scaffold(
              key: const ValueKey('splash'),
              backgroundColor: theme.scaffoldBackgroundColor,
              body: Center(
                child: Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: palette.cardElevated,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: palette.cardBorderSoft.withValues(alpha: 0.45),
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.asset(
                    'assets/icons/night_sleep_foreground.png',
                    fit: BoxFit.contain,
                  ),
                ),
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
