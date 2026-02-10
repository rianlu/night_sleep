import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:night_sleep/core/theme/promax_colors.dart';
import 'package:night_sleep/data/datasources/database_helper.dart';
import 'package:night_sleep/data/models/category_item.dart';
import 'package:night_sleep/data/models/video_item.dart';
import 'package:night_sleep/features/import/presentation/import_screen.dart';
import 'package:night_sleep/features/import/presentation/audio_parser_screen.dart';
import 'package:night_sleep/features/import/presentation/audio_parser_screen.dart';
import 'package:night_sleep/features/player/presentation/player_screen.dart';
import 'package:audio_service/audio_service.dart';
import 'package:night_sleep/features/player/data/audio_player_handler.dart';
import 'package:night_sleep/features/import/presentation/category_management_screen.dart';
import 'package:provider/provider.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart'; 
import 'package:flutter_animate/flutter_animate.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<VideoItem> _videos = [];
  bool _isLoading = true;
  late StreamSubscription _intentDataStreamSubscription;
  final ScrollController _scrollController = ScrollController();

  // Stitch Categories
  // Stitch Categories
  List<CategoryItem> _realCategories = [];
  int _selectedCategoryIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadVideos();
    _initReceiveSharingIntent();
  }

  @override
  void dispose() {
    _intentDataStreamSubscription.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initReceiveSharingIntent() async {
    _intentDataStreamSubscription = ReceiveSharingIntent.instance.getMediaStream().listen((List<SharedMediaFile> value) {
      if (value.isNotEmpty && value.first.type == SharedMediaType.text) {
        _navigateToImport(value.first.path);
      }
    }, onError: (err) {
      // print("getIntentDataStream error: $err");
    });

    ReceiveSharingIntent.instance.getInitialMedia().then((List<SharedMediaFile> value) {
      if (value.isNotEmpty && value.first.type == SharedMediaType.text) {
        _navigateToImport(value.first.path);
      }
    });
  }

  void _navigateToImport(String sharedText) {
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ImportScreen(initialText: sharedText)),
    ).then((result) {
      if (result == true) {
        _loadVideos();
      }
    });
  }

  Future<void> _loadVideos() async {
    setState(() => _isLoading = true);
    
    // Load dynamic categories
    final cats = await DatabaseHelper.instance.readAllCategories();
    
    if (_selectedCategoryIndex >= cats.length) {
      _selectedCategoryIndex = 0;
    }

    List<VideoItem> videos;
    final categoryName = cats.isNotEmpty ? cats[_selectedCategoryIndex].name : "默认";
    if (categoryName == "默认") {
      videos = await DatabaseHelper.instance.readAllVideos();
    } else {
      videos = await DatabaseHelper.instance.readVideosByCategory(categoryName);
    }
    
    setState(() {
      _realCategories = cats;
      _videos = videos;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ProMaxColors.stitchCozyBg,
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              _buildSliverAppBar(),
              _buildCategoryList(),
              _isLoading 
                  ? const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: ProMaxColors.stitchCozyPrimary)))
                  : _videos.isEmpty 
                      ? SliverFillRemaining(child: _buildEmptyState())
                      : _buildVideoList(),
              const SliverToBoxAdapter(child: SizedBox(height: 180)), // Space for global MiniPlayer and Nav
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      backgroundColor: ProMaxColors.stitchCozyBg.withValues(alpha: 0.95),
      surfaceTintColor: Colors.transparent,
      floating: true,
      pinned: true,
      expandedHeight: 100, // Reduced height as we put title in flexibleSpace or bottom
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.transparent),
          ),
        ),
        titlePadding: const EdgeInsets.only(left: 24, bottom: 16),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "晚上好",
              style: GoogleFonts.manrope(
                fontSize: 10,
                color: ProMaxColors.stitchCozyAccent.withValues(alpha: 0.8),
                fontWeight: FontWeight.w500,
                letterSpacing: 1.2,
              ),
            ),
            Text(
              "我的眠单",
              style: GoogleFonts.manrope(
                fontSize: 20,
                color: ProMaxColors.stitchCozyTextLight,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 24.0, top: 16),
          child: Row(
            children: [
              TextButton(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CategoryManagementScreen()),
                  );
                  _loadVideos(); // Refresh categories and list
                },
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.05),
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: const Text("管理", style: TextStyle(color: ProMaxColors.stitchCozyTextMuted, fontSize: 13, fontWeight: FontWeight.w500)),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: ProMaxColors.stitchCozyAccent.withValues(alpha: 0.2), blurRadius: 10, spreadRadius: 2),
                  ]
                ),
                child: IconButton(
                  icon: const Icon(Icons.add_rounded, size: 22),
                  style: IconButton.styleFrom(
                    backgroundColor: ProMaxColors.stitchCozyAccent,
                    foregroundColor: ProMaxColors.stitchCozyBg,
                  ),
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ImportScreen()),
                    );
                    if (result == true) {
                      _loadVideos();
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryList() {
    final displayCategories = _realCategories.map((c) => c.name).toList();
    return SliverToBoxAdapter(
      child: Container(
        height: 50,
        margin: const EdgeInsets.only(bottom: 16),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          itemCount: displayCategories.length,
          itemBuilder: (context, index) {
            final isSelected = index == _selectedCategoryIndex;
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: ActionChip(
                label: Text(displayCategories[index]),
                labelStyle: TextStyle(
                  color: isSelected ? ProMaxColors.stitchCozyBg : ProMaxColors.stitchCozyTextMuted,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 13,
                ),
                backgroundColor: isSelected ? ProMaxColors.stitchCozyAccent : ProMaxColors.stitchCozyCardBg,
                shape: const StadiumBorder(side: BorderSide(color: Colors.transparent)),
                onPressed: () {
                  setState(() => _selectedCategoryIndex = index);
                  _loadVideos();
                },
                side: !isSelected ? BorderSide(color: Colors.white.withValues(alpha: 0.05)) : BorderSide.none,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildVideoList() {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final video = _videos[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: _buildStitchVideoCard(video),
          ).animate().fadeIn(duration: 400.ms, delay: (50 * index).ms).slideX(begin: 0.1, end: 0);
        },
        childCount: _videos.length,
      ),
    );
  }

  Widget _buildStitchVideoCard(VideoItem video) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ProMaxColors.stitchCozyCardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: StreamBuilder<MediaItem?>(
        stream: context.read<AudioHandler>().mediaItem,
        builder: (context, snapshot) {
          final isPlaying = snapshot.data?.id == video.id;
          
           return InkWell(
           onTap: () {
               final handler = context.read<AudioHandler>();
               if (handler is AudioPlayerHandler) {
                  final currentId = handler.mediaItem.value?.id;
                  if (currentId != video.id) {
                    handler.loadPlaylist(_videos, _videos.indexOf(video));
                  }
               }
               Navigator.push(
                 context,
                 PageRouteBuilder(
                   transitionDuration: const Duration(milliseconds: 420),
                   pageBuilder: (_, __, ___) => PlayerScreen(
                     videoItem: video,
                     heroCoverTag: 'list-cover-${video.id}',
                     heroTitleTag: 'list-title-${video.id}',
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
            onLongPress: () => _showSleepListActions(video),
            borderRadius: BorderRadius.circular(16),
            child: Row(
              children: [
                // Thumbnail
                 Hero(
                   tag: 'list-cover-${video.id}',
                   child: Container(
                     width: 64,
                     height: 64,
                     decoration: BoxDecoration(
                       borderRadius: BorderRadius.circular(16),
                       image: DecorationImage(
                         image: NetworkImage(video.coverUrl),
                         fit: BoxFit.cover,
                       ),
                       boxShadow: [
                         BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 4)),
                       ],
                     ),
                     child: isPlaying ? Container(
                       color: Colors.black45,
                       child: const Icon(Icons.equalizer_rounded, color: Colors.white, size: 24),
                     ) : null,
                   ),
                 ),
                 
                 const SizedBox(width: 16),
                 
                 // Info
                 Expanded(
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Hero(
                         tag: 'list-title-${video.id}',
                         child: Text(
                           video.title,
                           maxLines: 1,
                           overflow: TextOverflow.ellipsis,
                           style: GoogleFonts.manrope(
                             fontSize: 15,
                             fontWeight: FontWeight.w600,
                             color: isPlaying ? ProMaxColors.stitchCozyAccent : ProMaxColors.stitchCozyTextLight,
                           ),
                         ),
                       ),
                       const SizedBox(height: 6),
                       Row(
                         children: [
                           Container(
                             padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                             decoration: BoxDecoration(
                               color: ProMaxColors.stitchCozyAccent.withValues(alpha: 0.1),
                               borderRadius: BorderRadius.circular(4),
                             ),
                             child: Text(
                               video.category ?? "未分类",
                               style: TextStyle(color: ProMaxColors.stitchCozyAccent.withValues(alpha: 0.9), fontSize: 10, fontWeight: FontWeight.bold),
                             ),
                           ),
                           const SizedBox(width: 8),
                           Text(
                             _formatDuration(video.duration),
                             style: const TextStyle(color: ProMaxColors.stitchCozyTextMuted, fontSize: 11),
                           ),
                         ],
                       ),
                     ],
                   ),
                 ),
                 
                 // Play Button
                 Container(
                   width: 40,
                   height: 40,
                   decoration: BoxDecoration(
                     shape: BoxShape.circle,
                     color: ProMaxColors.stitchCozyAccent.withValues(alpha: 0.1),
                   ),
                   child: Icon(
                     isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                     color: ProMaxColors.stitchCozyAccent,
                     size: 22,
                   ),
                 ),
              ],
            ),
          );
        }
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.nights_stay_outlined, size: 80, color: ProMaxColors.stitchCozyTextMuted.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text(
            '好梦等待中...',
            style: GoogleFonts.manrope(
              fontSize: 18,
              color: ProMaxColors.stitchCozyTextMuted,
              fontWeight: FontWeight.w300,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('添加内容'),
            style: ElevatedButton.styleFrom(
              backgroundColor: ProMaxColors.stitchCozyAccent,
              foregroundColor: ProMaxColors.stitchCozyBg,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () {
               _navigateToImport("");
            },
          ),
        ],
      ),
    );
  }

  void _showSleepListActions(VideoItem video) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          decoration: const BoxDecoration(
            color: Color(0xFF140F0D),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 48, height: 6, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(3))),
              const SizedBox(height: 16),
              Text(
                video.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.manrope(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.tune_rounded, color: ProMaxColors.stitchCozyAccent),
                title: const Text("编辑播放区间", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                onTap: () async {
                  Navigator.pop(context);
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => AudioParserScreen(video: video, isEditing: true)),
                  );
                  if (result == true) {
                    _loadVideos();
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                title: const Text("删除", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600)),
                onTap: () async {
                  Navigator.pop(context);
                  _confirmDelete(video);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _confirmDelete(VideoItem video) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF140F0D),
        title: const Text("删除音频", style: TextStyle(color: Colors.white)),
        content: Text("确定删除 \"${video.title}\" 吗？", style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("取消", style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final deletedVideo = video;
              setState(() => _videos.removeWhere((v) => v.id == video.id));
              await DatabaseHelper.instance.delete(video.id);
              final handler = context.read<AudioHandler>();
              if (handler is AudioPlayerHandler) {
                await handler.removeQueueItemById(video.id);
              }
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('已删除 ${video.title}'),
                  action: SnackBarAction(
                    label: '撤销',
                    textColor: ProMaxColors.stitchCozyAccent,
                    onPressed: () async {
                      await DatabaseHelper.instance.create(deletedVideo);
                      _loadVideos();
                    },
                  ),
                ));
              }
            },
            child: const Text("删除", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    if (seconds == 0) return "--:--";
    final d = Duration(seconds: seconds);
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}
