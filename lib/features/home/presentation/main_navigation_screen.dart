import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:night_sleep/core/theme/promax_colors.dart';
import 'package:night_sleep/data/models/video_item.dart';
import 'package:night_sleep/features/import/presentation/import_screen.dart';
import 'package:night_sleep/features/import/presentation/widgets/clipboard_popup.dart';
import 'package:night_sleep/features/home/presentation/home_screen.dart';
import 'package:night_sleep/features/home/presentation/widgets/stitch_bottom_nav_bar.dart';
import 'package:night_sleep/features/stats/presentation/sleep_report_screen.dart';
import 'package:night_sleep/features/settings/presentation/profile_screen.dart';
import 'package:night_sleep/features/player/presentation/player_screen.dart';
import 'package:night_sleep/features/player/data/audio_player_handler.dart';
import 'package:audio_service/audio_service.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;
  String? _lastClipboardText;
  String? _detectedLink;

  final List<Widget> _screens = [
    const HomeScreen(),
    const SleepReportScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkClipboard();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkClipboard();
    }
  }

  Future<void> _checkClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text != null && text != _lastClipboardText) {
      if (text.contains("bilibili.com") || text.contains("BV")) {
        setState(() {
          _detectedLink = text;
          _lastClipboardText = text;
        });
      }
    }
  }

  void _onParseLink() {
    final link = _detectedLink;
    setState(() => _detectedLink = null);
    if (link != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ImportScreen(initialText: link)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),
          
          // Global Mini Player (Home only)
          if (_currentIndex == 0) _buildFloatingMiniPlayer(),

          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: StitchBottomNavBar(
              currentIndex: _currentIndex,
              onTap: (index) => setState(() => _currentIndex = index),
            ),
          ),
          if (_detectedLink != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 180, // Moved up to avoid crossing with miniplayer/nav
              child: ClipboardPopup(
                content: _detectedLink!,
                onParse: _onParseLink,
                onDismiss: () => setState(() => _detectedLink = null),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFloatingMiniPlayer() {
    return StreamBuilder<MediaItem?>(
      stream: context.watch<AudioHandler>().mediaItem,
      builder: (context, snapshot) {
        final mediaItem = snapshot.data;
        if (mediaItem == null) return const SizedBox.shrink();

        return Positioned(
          bottom: 110, // Just above the bottom nav bar
          left: 20,
          right: 20,
          child: GestureDetector(
            onTap: () {
              // Open player screen using the mediaItem info
              // We'll reconstruct a VideoItem from extras or just enough for PlayerScreen
              final video = VideoItem(
                id: mediaItem.id,
                title: mediaItem.title,
                artist: mediaItem.artist ?? "",
                coverUrl: mediaItem.artUri.toString(),
                duration: mediaItem.duration?.inSeconds ?? 0,
                endTime: mediaItem.extras?['endTime'] ?? mediaItem.duration?.inSeconds ?? 0,
                startTime: mediaItem.extras?['startTime'] ?? 0,
                addedAt: DateTime.now(),
              );
              Navigator.push(
                context,
                PageRouteBuilder(
                  transitionDuration: const Duration(milliseconds: 420),
                  pageBuilder: (_, __, ___) => PlayerScreen(
                    videoItem: video,
                    heroCoverTag: 'mini-cover-${video.id}',
                    heroTitleTag: 'mini-title-${video.id}',
                  ),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
                    return FadeTransition(
                      opacity: curved,
                      child: ScaleTransition(
                        scale: Tween<double>(begin: 0.98, end: 1.0).animate(curved),
                        child: child,
                      ),
                    );
                  },
                ),
              );
            },
            child: Container(
              height: 72,
              decoration: BoxDecoration(
                color: ProMaxColors.stitchCozyMiniPlayerBg,
                borderRadius: BorderRadius.circular(36),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 5)),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(36),
                child: Stack(
                  children: [
                    // Progress Indicator Background
                    StreamBuilder<Duration>(
                      stream: AudioService.position,
                      builder: (context, posSnapshot) {
                         final pos = posSnapshot.data?.inMilliseconds.toDouble() ?? 0.0;
                         final total = mediaItem.duration?.inMilliseconds.toDouble() ?? 1.0;
                         final progress = (pos / total).clamp(0.0, 1.0);
                         return FractionallySizedBox(
                           widthFactor: progress,
                           heightFactor: 1.0,
                           child: Container(color: Colors.black.withValues(alpha: 0.03)),
                         );
                      }
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: Row(
                        children: [
                          StreamBuilder<PlaybackState>(
                            stream: context.read<AudioHandler>().playbackState,
                            builder: (context, pSnapshot) {
                              final playing = pSnapshot.data?.playing ?? false;
                              final cover = Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white24, width: 2),
                                  image: DecorationImage(
                                    image: NetworkImage(mediaItem.artUri.toString()),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              );

                              return Hero(
                                tag: 'mini-cover-${mediaItem.id}',
                                child: playing
                                  ? cover.animate(onPlay: (c) => c.repeat()).rotate(duration: 15.seconds)
                                  : cover,
                              );
                            },
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "正在播放",
                                  style: TextStyle(color: ProMaxColors.stitchCozyCardBg.withValues(alpha: 0.5), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1),
                                ),
                                Hero(
                                  tag: 'mini-title-${mediaItem.id}',
                                  child: Text(
                                    mediaItem.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: ProMaxColors.stitchCozyCardBg, fontSize: 13, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.skip_next_rounded, size: 26),
                                color: ProMaxColors.stitchCozyCardBg.withValues(alpha: 0.7),
                                onPressed: () => context.read<AudioHandler>().skipToNext(),
                              ),
                              StreamBuilder<PlaybackState>(
                                stream: context.read<AudioHandler>().playbackState,
                                builder: (context, pSnapshot) {
                                  final playing = pSnapshot.data?.playing ?? false;
                                  return Container(
                                    decoration: const BoxDecoration(shape: BoxShape.circle, color: ProMaxColors.stitchCozyCardBg),
                                    child: IconButton(
                                      icon: Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded, color: ProMaxColors.stitchCozyAccent, size: 22),
                                      onPressed: () => playing ? context.read<AudioHandler>().pause() : context.read<AudioHandler>().play(),
                                    ),
                                  );
                                }
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ).animate().slideY(begin: 1.0, end: 0, curve: Curves.easeOutCubic, duration: 600.ms),
        );
      },
    );
  }
}
