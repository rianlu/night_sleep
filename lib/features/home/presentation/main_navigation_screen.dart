import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:night_sleep/core/theme/promax_colors.dart';
import 'package:night_sleep/data/models/video_item.dart';
import 'package:night_sleep/features/import/presentation/import_screen.dart';
import 'package:night_sleep/features/home/presentation/home_screen.dart';
import 'package:night_sleep/features/home/presentation/widgets/stitch_bottom_nav_bar.dart';
import 'package:night_sleep/features/stats/presentation/sleep_report_screen.dart';
import 'package:night_sleep/features/settings/presentation/profile_screen.dart';
import 'package:night_sleep/features/player/presentation/player_screen.dart';
import 'package:night_sleep/features/import/presentation/widgets/clipboard_popup.dart';
import 'package:night_sleep/features/import/data/bilibili_import_service.dart';
import 'package:night_sleep/features/import/presentation/audio_parser_screen.dart';
import 'package:audio_service/audio_service.dart';
import 'package:provider/provider.dart';
import 'dart:ui';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> with TickerProviderStateMixin, WidgetsBindingObserver {
  int _currentIndex = 0;
  String? _lastClipboardText;
  
  late final AnimationController _playerExpandController;
  final List<Widget> _screens = [
    const HomeScreen(),
    const SleepReportScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _playerExpandController = AnimationController(
        vsync: this, 
        duration: const Duration(milliseconds: 350), 
        reverseDuration: const Duration(milliseconds: 350));
    _checkClipboard();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _playerExpandController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkClipboard();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _playerExpandController.value < 0.1,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _playerExpandController.value > 0.1) {
          _playerExpandController.animateTo(0.0, curve: Curves.easeOutCubic);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            IndexedStack(
              index: _currentIndex,
              children: _screens,
            ),
            
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: StitchBottomNavBar(
                currentIndex: _currentIndex,
                onTap: (index) => setState(() => _currentIndex = index),
              ),
            ),
            
            // Interactive Player (Always on top when expanded)
            _buildInteractivePlayer(),
          ],
        ),
      ),
    );
  }

  Future<void> _checkClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text != null && text != _lastClipboardText) {
      final bvRegex = RegExp(r'BV[a-zA-Z0-9]{10}');
      final b23Regex = RegExp(r'b23\.tv/[a-zA-Z0-9]+');

      if (text.contains("bilibili.com") || bvRegex.hasMatch(text) || b23Regex.hasMatch(text)) {
        setState(() {
          _lastClipboardText = text;
        });
        if (mounted) {
          _showClipboardBottomSheet(context, text);
        }
      }
    }
  }

  void _showClipboardBottomSheet(BuildContext context, String text) {
    VideoItem? cachedVideo;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          // Fetch real data if not already fetching/fetched
          if (cachedVideo == null) {
            final importService = BilibiliImportService();
            importService.resolveShortLink(text).then((bvId) {
              if (bvId != null) {
                return importService.fetchVideoInfo(bvId);
              }
              return null;
            }).then((video) {
              if (video != null && context.mounted) {
                setModalState(() => cachedVideo = video);
              }
            });
          }

          return ClipboardPopup(
            content: text,
            video: cachedVideo,
            onParse: () {
              Navigator.pop(context);
              if (cachedVideo != null) {
                 _onParseLink(text, video: cachedVideo);
              } else {
                 _onParseLink(text);
              }
            },
            onDismiss: () => Navigator.pop(context),
          );
        },
      ),
    );
  }

  void _onParseLink(String text, {VideoItem? video}) {
    if (video != null) {
      // Direct jump to parser since we already have the info
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => AudioParserScreen(video: video)),
      );
    } else {
      // Fallback to ImportScreen if metadata failed or not ready
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ImportScreen(initialText: text)),
      );
    }
  }

  Widget _buildInteractivePlayer() {
    return StreamBuilder<MediaItem?>(
      stream: context.watch<AudioHandler>().mediaItem,
      builder: (context, snapshot) {
        final mediaItem = snapshot.data;
        if (mediaItem == null) return const SizedBox.shrink();

        return AnimatedBuilder(
          animation: _playerExpandController,
          builder: (context, child) {
            // Finger Sync: While dragging, value is linear. 
            // Snapping: When animating via forward/reverse/animateTo, the curve is applied.
            final value = _playerExpandController.value;
            
            final double bottom = lerpDouble(110, 0, value)!;
            final double left = lerpDouble(20, 0, value)!;
            final double right = lerpDouble(20, 0, value)!;
            final double height = lerpDouble(72, MediaQuery.of(context).size.height, value)!;
            final double radius = lerpDouble(36, 0, value)!;
            final double miniOpacity = (1.0 - value * 5).clamp(0.0, 1.0); 

            return Positioned(
              bottom: bottom,
              left: left,
              right: right,
              height: height,
              child: GestureDetector(
                onTap: () {
                  if (value < 0.5) {
                    _playerExpandController.animateTo(1.0, curve: Curves.easeOutCubic);
                  }
                },
                onVerticalDragUpdate: (details) {
                  _playerExpandController.value -= details.primaryDelta! / MediaQuery.of(context).size.height;
                },
                onVerticalDragEnd: (details) {
                   final velocity = details.primaryVelocity ?? 0;
                   if (_playerExpandController.value > 0.3 || velocity < -1000) {
                     _playerExpandController.animateTo(1.0, curve: Curves.easeOutCubic);
                   } else {
                     _playerExpandController.animateTo(0.0, curve: Curves.easeOutCubic);
                   }
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: ProMaxColors.stitchCardBg,
                    borderRadius: BorderRadius.circular(radius),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 5)),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(radius),
                    child: Stack(
                      children: [
                        // Expanded Player
                        if (value > 0.01)
                          Opacity(
                             opacity: (value * 2).clamp(0.0, 1.0), 
                             child: IgnorePointer(
                               ignoring: value < 0.8, 
                               child: OverflowBox(
                                 minHeight: MediaQuery.of(context).size.height,
                                 maxHeight: MediaQuery.of(context).size.height,
                                 alignment: Alignment.topCenter,
                                 child: PlayerScreen(
                                   videoItem: _createVideoItem(mediaItem),
                                   heroCoverTag: 'player-cover-${mediaItem.id}',
                                   heroTitleTag: 'player-title-${mediaItem.id}',
                                   onClose: () => _playerExpandController.animateTo(0.0, curve: Curves.easeOutCubic),
                                   onDragUpdate: (delta) {
                                      _playerExpandController.value -= delta / MediaQuery.of(context).size.height;
                                   },
                                   onDragEnd: (velocity) {
                                      if (_playerExpandController.value > 0.7 && velocity < 1000) {
                                         _playerExpandController.animateTo(1.0, curve: Curves.easeOutCubic);
                                      } else {
                                         _playerExpandController.animateTo(0.0, curve: Curves.easeOutCubic);
                                      }
                                   },
                                 ),
                               ),
                             ),
                          ),

                        // Mini Player Content
                        if (value < 0.99)
                          Opacity(
                            opacity: miniOpacity,
                            child: _buildMiniPlayerContent(mediaItem),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMiniPlayerContent(MediaItem item) {
    const primaryColor = ProMaxColors.stitchPrimary;

    return Stack(
      children: [
        // Top Progress Bar
        Positioned(
          top: 0, left: 0, right: 0,
          child: StreamBuilder<Duration>(
            stream: AudioService.position,
            initialData: context.read<AudioHandler>().playbackState.value.position,
            builder: (context, posSnap) {
              final pos = posSnap.data ?? Duration.zero;
              final total = item.duration ?? const Duration(minutes: 1);
              final startSec = (item.extras?['startTime'] ?? 0).toDouble();
              var endSec = (item.extras?['endTime'] ?? total.inSeconds).toDouble();
              if (endSec <= startSec) endSec = total.inSeconds.toDouble();
              
              final range = (endSec - startSec).clamp(1.0, total.inSeconds.toDouble());
              final current = (pos.inSeconds.toDouble() - startSec).clamp(0.0, range);
              final progress = current / range;
              
              return LinearProgressIndicator(
                value: progress,
                minHeight: 2,
                backgroundColor: Colors.white10,
                valueColor: const AlwaysStoppedAnimation(primaryColor),
              );
            },
          ),
        ),
        
        // Main Content
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 2, 16, 0),
          child: Row(
            children: [
              Hero(
                tag: 'player-cover-${item.id}',
                child: Container(
                  width: 44, height: 44,
                  decoration: const BoxDecoration(shape: BoxShape.circle),
                  child: ClipOval(
                    child: Image.network(item.artUri?.toString() ?? '', fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Container(color: Colors.white10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.manrope(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                    Text(item.artist ?? "夜眠音频", 
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11)),
                  ],
                ),
              ),
              StreamBuilder<PlaybackState>(
                stream: context.read<AudioHandler>().playbackState,
                builder: (context, snapshot) {
                  final playing = snapshot.data?.playing ?? false;
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded, color: primaryColor, size: 28),
                        onPressed: () => playing ? context.read<AudioHandler>().pause() : context.read<AudioHandler>().play(),
                      ),
                      IconButton(
                        icon: const Icon(Icons.skip_next_rounded, color: Colors.white70, size: 28),
                        onPressed: () => context.read<AudioHandler>().skipToNext(),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  VideoItem _createVideoItem(MediaItem item) {
    return VideoItem(
      id: item.id,
      title: item.title,
      artist: item.artist ?? "未知作者",
      coverUrl: item.artUri?.toString() ?? "",
      duration: item.duration?.inSeconds ?? 0,
      startTime: item.extras?['startTime'] ?? 0,
      endTime: item.extras?['endTime'] ?? item.duration?.inSeconds ?? 0,
      category: item.extras?['category'],
      addedAt: DateTime.now(),
    );
  }
}
