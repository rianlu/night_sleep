import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:night_sleep/core/constants/app_constants.dart';
import 'package:night_sleep/core/theme/app_theme.dart';
import 'package:night_sleep/features/home/presentation/main_navigation_screen.dart';
import 'package:night_sleep/features/player/data/audio_player_handler.dart';
import 'package:night_sleep/features/ambience/logic/ambience_provider.dart';
import 'package:provider/provider.dart';

late AudioHandler audioHandler;

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

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AudioHandler>(create: (_) => audioHandler),
        ChangeNotifierProvider(create: (_) => AmbienceProvider(audioHandler)),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        theme: AppTheme.darkTheme, // 仅支持深色模式
        home: const MainNavigationScreen(),
      ),
    );
  }
}
