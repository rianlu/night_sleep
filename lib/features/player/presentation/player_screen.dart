import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:night_sleep/core/theme/promax_colors.dart';
import 'package:night_sleep/data/models/video_item.dart';
import 'package:night_sleep/features/player/data/audio_player_handler.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

class PlayerScreen extends StatefulWidget {
  final VideoItem videoItem;
  final String heroCoverTag;
  final String heroTitleTag;
  final VoidCallback? onClose;
  final ValueChanged<double>? onDragUpdate;
  final ValueChanged<double>? onDragEnd;

  const PlayerScreen({
    super.key,
    required this.videoItem,
    required this.heroCoverTag,
    required this.heroTitleTag,
    this.onClose,
    this.onDragUpdate,
    this.onDragEnd,
  });

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> with TickerProviderStateMixin {
  late VideoItem _displayItem;
  late final AnimationController _coverRotationController;
  late final AnimationController _breathingController;
  StreamSubscription<PlaybackState>? _playbackSub;

  // Slider State
  bool _isDraggingSlider = false;
  double? _sliderValue;

  @override
  void initState() {
    super.initState();
    _displayItem = widget.videoItem;
    _coverRotationController = AnimationController(vsync: this, duration: const Duration(seconds: 20));
    _breathingController = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat(reverse: true);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final handler = context.read<AudioHandler>();
      if (handler is AudioPlayerHandler) {
        if (handler.mediaItem.value?.id != _displayItem.id) {
          handler.playVideoItem(_displayItem);
        }
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _playbackSub?.cancel();
    final handler = context.read<AudioHandler>();
    _playbackSub = handler.playbackState.listen((state) {
      if (state.playing) {
        if (!_coverRotationController.isAnimating) {
          _coverRotationController.repeat();
        }
      } else {
        _coverRotationController.stop();
      }
    });
  }

  @override
  void dispose() {
    _playbackSub?.cancel();
    _coverRotationController.dispose();
    _breathingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final audioHandler = context.watch<AudioHandler>();
    const primaryColor = ProMaxColors.stitchPrimary;

    return StreamBuilder<MediaItem?>(
      stream: audioHandler.mediaItem,
      builder: (context, snapshot) {
        final mediaItem = snapshot.data;
        
        return Scaffold(
          backgroundColor: ProMaxColors.stitchBackground,
          body: GestureDetector(
            onVerticalDragUpdate: (details) {
              widget.onDragUpdate?.call(details.delta.dy);
            },
            onVerticalDragEnd: (details) {
              widget.onDragEnd?.call(details.primaryVelocity ?? 0);
            },
            child: Stack(
              children: [
                _buildThemeBackground(primaryColor),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.expand_more_rounded, size: 32, color: ProMaxColors.stitchTextLight),
                              onPressed: () {
                                if (widget.onClose != null) {
                                  widget.onClose!();
                                } else {
                                  Navigator.pop(context);
                                }
                              },
                            ),
                            Text(
                              "正在播放",
                              style: TextStyle(
                                color: ProMaxColors.stitchTextLight.withValues(alpha: 0.8),
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(width: 48),
                          ],
                        ),
                        const Spacer(flex: 2),
                        _buildVinylCover(audioHandler, primaryColor),
                        const Spacer(flex: 1), 
                        _buildTrackInfo(mediaItem, primaryColor),
                        const SizedBox(height: 32),
                        _buildProgressBar(audioHandler, primaryColor),
                        const Spacer(flex: 2),
                        _buildMainControls(audioHandler, primaryColor),
                        const Spacer(flex: 2),
                        _buildBottomPillBar(context, audioHandler, primaryColor),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildThemeBackground(Color primaryColor) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, -0.4),
              radius: 1.5,
              colors: [
                ProMaxColors.stitchCardBg,
                ProMaxColors.stitchBackground,
              ],
            ),
          ),
        ),
        Positioned(
          top: 100,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primaryColor.withValues(alpha: 0.05),
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
              begin: const Offset(0.8, 0.8),
              end: const Offset(1.2, 1.2),
              duration: 10.seconds,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVinylCover(AudioHandler handler, Color primaryColor) {
    return StreamBuilder<PlaybackState>(
      stream: handler.playbackState,
      builder: (context, stateSnap) {
        return AnimatedBuilder(
          animation: _breathingController,
          builder: (context, child) {
            double spread = 10 + (20 * _breathingController.value);
            Color shadowColor = primaryColor.withValues(alpha: 0.15 + (0.1 * _breathingController.value));
            
            return Hero(
              tag: widget.heroCoverTag,
              child: RotationTransition(
                turns: _coverRotationController,
                child: Container(
                  width: 290, height: 290,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 40,
                        offset: const Offset(0, 20),
                      ),
                      BoxShadow(
                        color: shadowColor,
                        blurRadius: spread,
                        spreadRadius: 0,
                      )
                    ],
                  ),
                  child: ClipOval(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          handler.mediaItem.value?.artUri?.toString() ?? _displayItem.coverUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, e, s) => Container(color: ProMaxColors.stitchCardBg),
                        ),
                        Center(
                          child: Container(
                            width: 50, height: 50,
                            decoration: BoxDecoration(
                              color: const Color(0xFF140F0D).withValues(alpha: 0.85),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white10, width: 1),
                            ),
                            child: Center(
                              child: Container(
                                width: 12, height: 12,
                                decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      }
    );
  }

  Widget _buildTrackInfo(MediaItem? item, Color primaryColor) {
    final title = item?.title ?? _displayItem.title;
    final artist = item?.artist ?? _displayItem.artist;
    final category = item?.extras?['category']?.toString();
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
         Hero(
            tag: widget.heroTitleTag,
            child: SizedBox(
               width: double.infinity,
               child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.manrope(color: ProMaxColors.stitchTextLight, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                  maxLines: 2, overflow: TextOverflow.ellipsis,
               ),
            ),
         ).animate().fadeIn(duration: 800.ms).moveY(begin: 10, end: 0),
         
         const SizedBox(height: 10),
         
         Row(
           mainAxisAlignment: MainAxisAlignment.center,
           children: [
             if (category != null && category.isNotEmpty)
               Container(
                 padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                 margin: const EdgeInsets.only(right: 8),
                 decoration: BoxDecoration(
                   color: primaryColor.withValues(alpha: 0.1),
                   borderRadius: BorderRadius.circular(12),
                   border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
                 ),
                 child: Text(
                   category,
                   style: TextStyle(color: primaryColor, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                 ),
               ),
               
             Text(
                 "$artist · 夜眠系列", 
                 style: const TextStyle(color: ProMaxColors.stitchTextMuted, fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.5),
             ).animate().fadeIn(delay: 200.ms, duration: 800.ms),
           ],
         )
      ],
    );
  }

  Widget _buildProgressBar(AudioHandler handler, Color primaryColor) {
    return StreamBuilder<Duration>(
      stream: AudioService.position,
      initialData: handler.playbackState.value.position,
      builder: (context, posSnap) {
        final position = posSnap.data ?? Duration.zero;
        final duration = handler.mediaItem.value?.duration ?? Duration(seconds: _displayItem.duration);
        final totalSeconds = duration.inSeconds > 0 ? duration.inSeconds : 1;
        
        final startSec = (handler.mediaItem.value?.extras?['startTime'] ?? _displayItem.startTime).clamp(0, totalSeconds);
        var endSec = (handler.mediaItem.value?.extras?['endTime'] ?? _displayItem.endTime).clamp(0, totalSeconds);
        if (endSec <= startSec) endSec = totalSeconds;
        
        final rangeSeconds = (endSec - startSec).clamp(1, totalSeconds);
        final effectiveSeconds = (_isDraggingSlider ? (_sliderValue ?? position.inSeconds.toDouble()) : position.inSeconds.toDouble()).clamp(startSec.toDouble(), endSec.toDouble());
        final progress = ((effectiveSeconds - startSec) / rangeSeconds).clamp(0.0, 1.0);
        
        return Column(
          children: [
            SizedBox(
              height: 20,
              child: SliderTheme(
                data: SliderThemeData(
                  trackHeight: 4,
                  activeTrackColor: primaryColor,
                  inactiveTrackColor: Colors.white.withValues(alpha: 0.1),
                  thumbColor: primaryColor,
                  thumbShape: GlowingSliderThumbShape(color: primaryColor), 
                  overlayColor: primaryColor.withValues(alpha: 0.2),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                  trackShape: const RoundedRectSliderTrackShape(),
                ),
                child: Slider(
                  value: progress,
                  onChanged: (v) {
                    setState(() {
                      _isDraggingSlider = true;
                      _sliderValue = startSec + (v * rangeSeconds);
                    });
                  },
                  onChangeEnd: (v) {
                     final targetSec = startSec + (v * rangeSeconds);
                     handler.seek(Duration(seconds: targetSec.toInt()));
                     setState(() {
                       _isDraggingSlider = false;
                       _sliderValue = null;
                     });
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDuration(Duration(seconds: (effectiveSeconds - startSec).toInt())),
                    style: GoogleFonts.manrope(color: primaryColor.withValues(alpha: 0.7), fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5),
                  ),
                  Text(
                    _formatDuration(Duration(seconds: rangeSeconds)),
                    style: GoogleFonts.manrope(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5),
                  ),
                ],
              ),
            ),
          ],
        );
      }
    );
  }

  Widget _buildMainControls(AudioHandler handler, Color primaryColor) {
    return StreamBuilder<PlaybackState>(
      stream: handler.playbackState,
      builder: (context, snapshot) {
        final playing = snapshot.data?.playing ?? false;
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.skip_previous_rounded, color: ProMaxColors.stitchTextLight, size: 40),
              onPressed: () => handler.skipToPrevious(),
            ),
            const SizedBox(width: 40),
            GestureDetector(
              onTap: () => playing ? handler.pause() : handler.play(),
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: primaryColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.4),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    )
                  ],
                ),
                child: Icon(
                  playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  size: 40,
                  color: const Color(0xFF140F0D),
                ),
              ),
            ),
            const SizedBox(width: 40),
            IconButton(
              icon: const Icon(Icons.skip_next_rounded, color: ProMaxColors.stitchTextLight, size: 40),
              onPressed: () => handler.skipToNext(),
            ),
          ],
        );
      }
    );
  }

  Widget _buildBottomPillBar(BuildContext context, AudioHandler handler, Color primaryColor) {
    return Container(
      height: 64,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF130E0C),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
           if (handler is AudioPlayerHandler)
             StreamBuilder<bool>(
               stream: (handler as AudioPlayerHandler).shuffleModeStream,
               initialData: (handler as AudioPlayerHandler).isShuffleEnabled,
               builder: (context, shuffleSnap) {
                 return StreamBuilder<AudioServiceRepeatMode>(
                   stream: (handler as AudioPlayerHandler).repeatModeStream,
                   initialData: AudioServiceRepeatMode.none,
                   builder: (context, repeatSnap) {
                     final shuffle = shuffleSnap.data ?? false;
                     final repeat = repeatSnap.data ?? AudioServiceRepeatMode.none;
                     
                     IconData icon = Icons.repeat_rounded;
                     bool isActive = false;
                     
                     if (shuffle) {
                        icon = Icons.shuffle_rounded;
                        isActive = true;
                     } else if (repeat == AudioServiceRepeatMode.one) {
                        icon = Icons.repeat_one_rounded;
                        isActive = true;
                     } else if (repeat == AudioServiceRepeatMode.all) {
                        icon = Icons.repeat_rounded;
                        isActive = true;
                     }
                     
                     final color = isActive ? primaryColor : ProMaxColors.stitchTextLight;
                     
                     return IconButton(
                       icon: Icon(icon, color: color),
                       onPressed: () => (handler as AudioPlayerHandler).cyclePlayMode(),
                     );
                   }
                 );
               }
             )
           else
              IconButton(icon: const Icon(Icons.repeat_rounded, color: Colors.white30), onPressed: () {}),
           
           IconButton(
             icon: const Icon(Icons.queue_music_rounded, color: ProMaxColors.stitchTextLight), 
             onPressed: () => _showPlaylistSheet(context, audioHandler: handler),
           ),
           
           StreamBuilder<int>(
             stream: Stream.periodic(const Duration(seconds: 1), (i) => i),
             builder: (context, _) {
                String? timerText;
                bool active = false;
                if (handler is AudioPlayerHandler) {
                   final end = handler.sleepTimerEnd;
                   final now = DateTime.now();
                   if (end != null && end.isAfter(now)) {
                      active = true;
                      final d = end.difference(now);
                      timerText = "${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}";
                   }
                }
                
                if (active && timerText != null) {
                   return GestureDetector(
                     onTap: () => _showSleepTimerDialog(context, audioHandler: handler),
                     child: Container(
                       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                       decoration: BoxDecoration(
                         color: primaryColor.withValues(alpha: 0.1),
                         borderRadius: BorderRadius.circular(16),
                         border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
                       ),
                       child: Text(
                         timerText, 
                         style: TextStyle(color: primaryColor, fontSize: 13, fontWeight: FontWeight.bold)
                       ),
                     ),
                   );
                }
                
                return IconButton(
                   icon: const Icon(Icons.nights_stay_rounded, color: ProMaxColors.stitchTextLight), 
                   onPressed: () => _showSleepTimerDialog(context, audioHandler: handler),
                );
             }
           ),
        ],
      ),
    );
  }

  void _showPlaylistSheet(BuildContext context, {required AudioHandler audioHandler}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _PlaylistSheet(handler: audioHandler),
    );
  }

  void _showSleepTimerDialog(BuildContext context, {required AudioHandler audioHandler}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _SleepTimerSheet(handler: audioHandler),
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

class GlowingSliderThumbShape extends SliderComponentShape {
  final double enabledThumbRadius;
  final Color color;

  const GlowingSliderThumbShape({
    this.enabledThumbRadius = 8.0,
    required this.color,
  });

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size.fromRadius(enabledThumbRadius);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final Canvas canvas = context.canvas;
    
    final Paint glowPaint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(center, enabledThumbRadius + 4, glowPaint);
    
    final Paint thumbPaint = Paint()..color = color;
    canvas.drawCircle(center, enabledThumbRadius, thumbPaint);
    
    final Paint innerDocPaint = Paint()..color = const Color(0xFF140F0D);
    canvas.drawCircle(center, enabledThumbRadius * 0.4, innerDocPaint);
  }
}

class _PlaylistSheet extends StatelessWidget {
  final AudioHandler handler;
  const _PlaylistSheet({required this.handler});

  @override
  Widget build(BuildContext context) {
    const primaryColor = ProMaxColors.stitchPrimary;
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: ProMaxColors.stitchBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 48, height: 6,
            decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(3)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text("播放列表", style: GoogleFonts.manrope(color: ProMaxColors.stitchTextLight, fontSize: 22, fontWeight: FontWeight.w900)),
                const SizedBox(width: 8),
                StreamBuilder<List<MediaItem>>(
                  stream: handler.queue,
                  builder: (context, snap) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: const Color(0xFF2D241E), borderRadius: BorderRadius.circular(12)),
                    child: Text("${snap.data?.length ?? 0}", style: const TextStyle(color: primaryColor, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {
                    if (handler is AudioPlayerHandler) (handler as AudioPlayerHandler).clearQueue();
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.delete_outline_rounded, size: 14),
                  label: const Text("清空列表", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  style: TextButton.styleFrom(
                    foregroundColor: ProMaxColors.stitchTextMuted,
                    backgroundColor: const Color(0xFF2D241E),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 16),
            child: Row(
              children: [
                Text("当前队列", style: TextStyle(color: ProMaxColors.stitchTextLight.withValues(alpha: 0.4), fontSize: 12, fontWeight: FontWeight.w500)),
                const SizedBox(width: 12),
                const Icon(Icons.drag_indicator_rounded, color: primaryColor, size: 12),
                const SizedBox(width: 4),
                Text("长按并拖动以排序", style: TextStyle(color: ProMaxColors.stitchTextLight.withValues(alpha: 0.25), fontSize: 10, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<MediaItem>>(
              stream: handler.queue,
              builder: (context, snapshot) {
                final queue = snapshot.data ?? [];
                return StreamBuilder<MediaItem?>(
                  stream: handler.mediaItem,
                  builder: (context, mediaSnap) {
                    final playingId = mediaSnap.data?.id;
                    return StreamBuilder<Duration>(
                      stream: AudioService.position,
                      builder: (context, posSnap) {
                        final pos = posSnap.data ?? Duration.zero;
                        return ReorderableListView.builder(
                          padding: const EdgeInsets.only(bottom: 40),
                          itemCount: queue.length,
                          onReorder: (oldIndex, newIndex) {
                            if (newIndex > oldIndex) newIndex -= 1;
                            if (handler is AudioPlayerHandler) (handler as AudioPlayerHandler).reorderQueue(oldIndex, newIndex);
                          },
                          itemBuilder: (context, index) {
                            final item = queue[index];
                            final isPlaying = playingId == item.id;
                            return _buildPlaylistItem(context, item, index, isPlaying, currentPosition: isPlaying ? pos : null, key: ValueKey(item.id), primaryColor: primaryColor);
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaylistItem(BuildContext context, MediaItem item, int index, bool isPlaying, {required Key key, Duration? currentPosition, required Color primaryColor}) {
    final String indexStr = (index + 1).toString().padLeft(2, '0');
    
    if (isPlaying) {
      return Container(
        key: key,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF2D241E),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: primaryColor.withValues(alpha: 0.6), width: 1),
          boxShadow: [
             BoxShadow(color: primaryColor.withValues(alpha: 0.15), blurRadius: 12, offset: const Offset(0, 4)),
          ]
        ),
        child: InkWell(
          onTap: () { if (handler is AudioPlayerHandler) (handler as AudioPlayerHandler).skipToQueueIndex(index); },
          borderRadius: BorderRadius.circular(32),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            child: Row(
              children: [
                Container(
                  width: 50, height: 50,
                  decoration: BoxDecoration(color: primaryColor, shape: BoxShape.circle),
                  child: const Icon(Icons.graphic_eq_rounded, color: Color(0xFF140F0D), size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.manrope(color: primaryColor, fontSize: 15, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.play_arrow_rounded, color: primaryColor, size: 12),
                          const SizedBox(width: 4),
                          Text("播放中", style: TextStyle(color: primaryColor, fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
                Text("${_formatDurationStr(currentPosition)} / ${_formatDurationStr(item.duration)}", 
                  style: TextStyle(color: primaryColor.withValues(alpha: 0.9), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                const SizedBox(width: 10),
                IconButton(
                  icon: Icon(Icons.close_rounded, color: primaryColor.withValues(alpha: 0.5), size: 20),
                  onPressed: () { if (handler is AudioPlayerHandler) (handler as AudioPlayerHandler).removeQueueItemById(item.id); },
                  padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 12),
                Icon(Icons.drag_handle_rounded, color: primaryColor, size: 20),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      key: key,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1815),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withValues(alpha: 0.03)),
      ),
      child: InkWell(
        onTap: () { if (handler is AudioPlayerHandler) (handler as AudioPlayerHandler).skipToQueueIndex(index); },
        borderRadius: BorderRadius.circular(32),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          child: Row(
            children: [
               Container(
                  width: 46, height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFF28201C),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                  ),
                  child: Center(child: Text(indexStr, style: const TextStyle(color: Color(0xFFE6B874), fontWeight: FontWeight.bold, fontSize: 13))),
               ),
               const SizedBox(width: 12),
               Expanded(
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                       style: GoogleFonts.manrope(color: Colors.white.withValues(alpha: 0.9), fontSize: 14, fontWeight: FontWeight.w600)),
                     const SizedBox(height: 2),
                     Text(item.artist ?? "未知作者", style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 11)),
                   ],
                 ),
               ),
               Text(_formatDurationStr(item.duration), style: const TextStyle(color: Colors.white24, fontSize: 11, fontWeight: FontWeight.bold)),
               const SizedBox(width: 10),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white24, size: 20),
                  onPressed: () { if (handler is AudioPlayerHandler) (handler as AudioPlayerHandler).removeQueueItemById(item.id); },
                  padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.drag_handle_rounded, color: Colors.white24, size: 20),
                const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDurationStr(Duration? d) {
    if (d == null) return "--:--";
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

class _SleepTimerSheet extends StatefulWidget {
  final AudioHandler handler;
  const _SleepTimerSheet({required this.handler});

  @override
  State<_SleepTimerSheet> createState() => _SleepTimerSheetState();
}

class _SleepTimerSheetState extends State<_SleepTimerSheet> {
  int _selectedMinutes = 30;
  double _customValue = 30;
  bool _fadeOut = true;
  bool _isCustomMode = false;

  @override
  void initState() {
    super.initState();
    if (widget.handler is AudioPlayerHandler) {
      final h = widget.handler as AudioPlayerHandler;
      _fadeOut = h.fadeOutEnabled;
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = ProMaxColors.stitchPrimary;
    
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
      decoration: const BoxDecoration(color: ProMaxColors.stitchBackground, borderRadius: BorderRadius.vertical(top: Radius.circular(44))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 48, height: 6, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(3)),
          ),
          const SizedBox(height: 22),
          const Text("睡眠定时", style: TextStyle(color: Colors.white38, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.nights_stay_rounded, color: primaryColor, size: 30),
              const SizedBox(width: 10),
              Text("${_isCustomMode ? _customValue.toInt() : _selectedMinutes}分钟后停止", style: GoogleFonts.manrope(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 24),
          GridView.count(
            shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 2.2,
            children: [
              _buildPresetBtn("不启用", 0, primaryColor),
              _buildPresetBtn("15分钟", 15, primaryColor),
              _buildPresetBtn("30分钟", 30, primaryColor),
              _buildPresetBtn("60分钟", 60, primaryColor),
              _buildPresetBtn("90分钟", 90, primaryColor),
              _buildCustomBtn(primaryColor),
            ],
          ),
          const SizedBox(height: 28),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text("自定义", style: TextStyle(color: _isCustomMode ? primaryColor : Colors.white.withValues(alpha: 0.3), fontSize: 13, fontWeight: FontWeight.bold)),
            Text("${_customValue.toInt()} min", style: TextStyle(color: _isCustomMode ? primaryColor : Colors.white.withValues(alpha: 0.3), fontSize: 13, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 4, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
              activeTrackColor: _isCustomMode ? primaryColor : Colors.white10, 
              inactiveTrackColor: Colors.white10, 
              thumbColor: _isCustomMode ? primaryColor : Colors.white24,
              overlayColor: primaryColor.withValues(alpha: 0.1),
            ),
            child: Slider(
              value: _customValue, min: 0, max: 120,
              onChanged: (v) => setState(() { 
                _isCustomMode = true; 
                _customValue = v; 
                _selectedMinutes = v.toInt(); 
              }),
            ),
          ),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
             Text("0", style: TextStyle(color: Colors.white10, fontSize: 10)),
             Text("120", style: TextStyle(color: Colors.white10, fontSize: 10)),
          ]),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(color: const Color(0xFF1A120B), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withValues(alpha: 0.05))),
            child: Column(children: [
                _buildToggleRow(Icons.volume_down_rounded, "声音渐弱停止", "结束前最后1分钟音量渐隐", _fadeOut, (v) => setState(() => _fadeOut = v), primaryColor),
            ]),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity, height: 54,
            child: ElevatedButton(
              onPressed: () {
                if (widget.handler is AudioPlayerHandler) {
                   final h = widget.handler as AudioPlayerHandler;
                   h.setFadeOutEnabled(_fadeOut);
                   final mins = _isCustomMode ? _customValue.toInt() : _selectedMinutes;
                   if (mins > 0) h.setSleepTimer(Duration(minutes: mins)); else h.cancelSleepTimer();
                }
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor, foregroundColor: const Color(0xFF140F0D),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(27)),
                elevation: 0, 
              ),
              child: const Text("确 定", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 2)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetBtn(String label, int mins, Color primaryColor) {
    bool isSelected = !_isCustomMode && _selectedMinutes == mins;
    return GestureDetector(
      onTap: () => setState(() { 
        _isCustomMode = false; 
        _selectedMinutes = mins; 
      }),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : ProMaxColors.stitchCardBg, borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected ? [BoxShadow(color: primaryColor.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))] : null,
        ),
        child: Center(child: Text(label, style: TextStyle(color: isSelected ? const Color(0xFF140F0D) : Colors.white.withValues(alpha: 0.4), fontWeight: FontWeight.bold, fontSize: 13))),
      ),
    );
  }

  Widget _buildCustomBtn(Color primaryColor) {
    bool isSelected = _isCustomMode;
    return GestureDetector(
      onTap: () => setState(() { 
        _isCustomMode = true; 
        _selectedMinutes = _customValue.toInt();
      }),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : ProMaxColors.stitchCardBg, 
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected ? [BoxShadow(color: primaryColor.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))] : null,
        ),
        child: Icon(Icons.edit_rounded, color: isSelected ? const Color(0xFF140F0D) : Colors.white24, size: 24),
      ),
    );
  }

  Widget _buildToggleRow(IconData icon, String title, String sub, bool val, ValueChanged<bool> onChanged, Color primaryColor) {
    return Row(
      children: [
        Container(
          width: 40, height: 40, decoration: const BoxDecoration(color: ProMaxColors.stitchCardBg, shape: BoxShape.circle),
          child: Icon(icon, color: primaryColor, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
              if (sub.isNotEmpty) ...[const SizedBox(height: 2), Text(sub, style: TextStyle(color: Colors.white.withValues(alpha: 0.25), fontSize: 11))],
          ]),
        ),
        Switch(value: val, onChanged: onChanged, activeThumbColor: Colors.white, activeTrackColor: primaryColor, inactiveTrackColor: Colors.white10),
      ],
    );
  }
}
