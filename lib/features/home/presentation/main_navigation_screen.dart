import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
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
          
          // 全局迷你播放器（仅在首页显示）
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
        ],
      ),
    );
  }

  Future<void> _checkClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text != null && text != _lastClipboardText) {
      // Regex for BV ID and b23.tv short link
      final bvRegex = RegExp(r'BV[a-zA-Z0-9]{10}');
      final b23Regex = RegExp(r'b23\.tv/[a-zA-Z0-9]+');

      if (text.contains("bilibili.com") || bvRegex.hasMatch(text) || b23Regex.hasMatch(text)) {
        setState(() {
          _lastClipboardText = text;
        });
        
        // Use Future.delayed to ensure context is ready and frame is settled
        if (mounted) {
           Future.delayed(const Duration(milliseconds: 300), () {
             if (mounted) _showClipboardBottomSheet(text);
           });
        }
      }
    }
  }

  void _showClipboardBottomSheet(String link) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Color(0xFF140F0D), // 深咖啡色 / 接近黑色
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            border: Border(top: BorderSide(color: Colors.white10, width: 1)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, 
                height: 4, 
                decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(2))
              ),
              const SizedBox(height: 24),
              
              // 图标环
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF2C2018),
                  border: Border.all(color: ProMaxColors.stitchCozyAccent.withValues(alpha: 0.3)),
                ),
                child: const Icon(Icons.link_rounded, color: ProMaxColors.stitchCozyAccent, size: 32),
              ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
              
              const SizedBox(height: 20),
              
              Text(
                "检测到 B 站链接",
                style: GoogleFonts.manrope(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "是否立即解析剪贴板中的视频内容？",
                style: TextStyle(color: ProMaxColors.stitchCozyTextMuted, fontSize: 14),
              ),
              
              const SizedBox(height: 24),
              
              // 链接预览卡片
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFB7299).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text("Bilibili", style: TextStyle(color: Color(0xFFFB7299), fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        link,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // 解析按钮
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Close sheet
                    _onParseLink(link);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ProMaxColors.stitchCozyAccent, // Gold
                    foregroundColor: const Color(0xFF140F0D), // Black text
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                       Icon(Icons.play_arrow_rounded, size: 24),
                       SizedBox(width: 8),
                       Text("立即解析", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // 取消按钮
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("取消", style: TextStyle(color: ProMaxColors.stitchCozyTextMuted)),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _onParseLink(String link) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ImportScreen(initialText: link)),
    );
  }
  Widget _buildFloatingMiniPlayer() {
    return StreamBuilder<MediaItem?>(
      stream: context.watch<AudioHandler>().mediaItem,
      builder: (context, snapshot) {
        final mediaItem = snapshot.data;
        if (mediaItem == null) return const SizedBox.shrink();

        return Positioned(
          bottom: 110, // 位于底部导航栏上方
          left: 20,
          right: 20,
          child: GestureDetector(
            onTap: () {
              // 使用 mediaItem 信息打开播放器页面
              // 我们将从 extras 重构 VideoItem，或者仅构建 PlayerScreen 所需的部分信息
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
                    // 进度条背景
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
                                  style: TextStyle(color: ProMaxColors.stitchCozyTextMuted, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1),
                                ),
                                Hero(
                                  tag: 'mini-title-${mediaItem.id}',
                                  child: Text(
                                    mediaItem.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: ProMaxColors.stitchCozyTextLight, fontSize: 13, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.skip_next_rounded, size: 26),
                                color: ProMaxColors.stitchCozyTextLight.withValues(alpha: 0.7),
                                onPressed: () => context.read<AudioHandler>().skipToNext(),
                              ),
                              StreamBuilder<PlaybackState>(
                                stream: context.read<AudioHandler>().playbackState,
                                builder: (context, pSnapshot) {
                                  final playing = pSnapshot.data?.playing ?? false;
                                  return Container(
                                    decoration: const BoxDecoration(shape: BoxShape.circle, color: ProMaxColors.stitchCozyAccent),
                                    child: IconButton(
                                      icon: Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded, color: ProMaxColors.stitchCozyBg, size: 22),
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
