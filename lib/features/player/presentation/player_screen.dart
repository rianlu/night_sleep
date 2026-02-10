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

  const PlayerScreen({
    super.key,
    required this.videoItem,
    required this.heroCoverTag,
    required this.heroTitleTag,
  });

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> with TickerProviderStateMixin {
  late VideoItem _displayItem;
  late final AnimationController _coverRotationController;
  late final AnimationController _dragResetController;
  StreamSubscription<PlaybackState>? _playbackSub;
  bool _isDragging = false;
  double? _dragValue;
  double _dragOffset = 0;
  bool _canDragToDismiss = false;

  @override
  void initState() {
    super.initState();
    _displayItem = widget.videoItem;
    _coverRotationController = AnimationController(vsync: this, duration: const Duration(seconds: 20));
    _dragResetController = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
    
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
    _dragResetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final audioHandler = context.watch<AudioHandler>();

    return StreamBuilder<MediaItem?>(
      stream: audioHandler.mediaItem,
      builder: (context, snapshot) {
        final mediaItem = snapshot.data;
        
        return Scaffold(
          backgroundColor: ProMaxColors.stitchCozyBg,
          extendBodyBehindAppBar: true,
          appBar: _buildAppBar(context),
          body: GestureDetector(
            onVerticalDragStart: (details) {
              _canDragToDismiss = details.localPosition.dy < 160;
            },
            onVerticalDragUpdate: (details) {
              if (!_canDragToDismiss) return;
              if (details.delta.dy <= 0) return;
              setState(() {
                _dragOffset = (_dragOffset + details.delta.dy).clamp(0, 240);
              });
            },
            onVerticalDragEnd: (_) {
              if (!_canDragToDismiss) return;
              if (_dragOffset > 120) {
                Navigator.pop(context);
              } else {
                _animateDragReset();
              }
              _canDragToDismiss = false;
            },
            child: AnimatedBuilder(
              animation: _dragResetController,
              builder: (context, child) {
                final opacity = (1 - (_dragOffset / 300)).clamp(0.0, 1.0);
                return Transform.translate(
                  offset: Offset(0, _dragOffset),
                  child: Opacity(opacity: opacity, child: child),
                );
              },
              child: Stack(
                children: [
                  _buildThemeBackground(),
                  
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          const Spacer(flex: 2),
                          
                          // 封面图与弧形进度条
                          _buildCoverSection(audioHandler),
                          
                          const Spacer(flex: 2),
                          
                          // 歌曲信息
                          _buildTrackInfo(mediaItem),
                          
                          const Spacer(flex: 4),
                          
                          // 主控制器
                          _buildMainControls(audioHandler),
                          
                          const Spacer(flex: 3),
                          
                          // 底部动作面板
                          _buildBottomActionPanel(context, audioHandler),
                          
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    );
  }

  void _animateDragReset() {
    final begin = _dragOffset;
    _dragResetController.reset();
    final animation = Tween<double>(begin: begin, end: 0).animate(_dragResetController);
    animation.addListener(() {
      setState(() {
        _dragOffset = animation.value;
      });
    });
    _dragResetController.forward();
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.expand_more_rounded, size: 32, color: ProMaxColors.stitchCozyTextLight),
        onPressed: () => Navigator.pop(context),
      ),
      centerTitle: true,
      title: Text(
        "正在播放",
        style: TextStyle(
          color: ProMaxColors.stitchCozyTextLight.withValues(alpha: 0.3),
          fontSize: 13,
          fontWeight: FontWeight.bold,
          letterSpacing: 2.5,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.more_horiz_rounded, color: ProMaxColors.stitchCozyTextLight),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildThemeBackground() {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, -0.4),
              radius: 1.5,
              colors: [
                ProMaxColors.stitchCozyCardBg,
                ProMaxColors.stitchCozyBg,
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
                color: ProMaxColors.stitchCozyAccent.withValues(alpha: 0.05),
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

  Widget _buildCoverSection(AudioHandler handler) {
    return StreamBuilder<PlaybackState>(
      stream: handler.playbackState,
      builder: (context, stateSnap) {
        final playing = stateSnap.data?.playing ?? false;
        
        return StreamBuilder<Duration>(
          stream: AudioService.position,
          builder: (context, posSnap) {
            final position = posSnap.data ?? Duration.zero;
            final duration = handler.mediaItem.value?.duration ?? Duration(seconds: _displayItem.duration);
            final totalSeconds = duration.inSeconds > 0 ? duration.inSeconds : 1;
            final startSec = (handler.mediaItem.value?.extras?['startTime'] ?? _displayItem.startTime).clamp(0, totalSeconds);
            var endSec = (handler.mediaItem.value?.extras?['endTime'] ?? _displayItem.endTime).clamp(0, totalSeconds);
            if (endSec <= startSec) {
              endSec = totalSeconds;
            }
            final rangeSeconds = (endSec - startSec).clamp(1, totalSeconds);
            final effectiveSeconds = (_isDragging ? (_dragValue ?? position.inSeconds.toDouble()) : position.inSeconds.toDouble()).clamp(startSec.toDouble(), endSec.toDouble());
            final progress = ((effectiveSeconds - startSec) / rangeSeconds).clamp(0.0, 1.0);

            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      GestureDetector(
                        onPanStart: (details) => _handleArcDrag(details.localPosition, startSec, endSec),
                        onPanUpdate: (details) => _handleArcDrag(details.localPosition, startSec, endSec),
                        onPanEnd: (_) => _commitArcDrag(handler, startSec, endSec),
                        child: SizedBox(
                          width: 360,
                          height: 180,
                          child: CustomPaint(
                            painter: ProgressArcPainter(
                              progress: progress.clamp(0.0, 1.0),
                              color: ProMaxColors.stitchCozyAccent,
                              trackColor: Colors.white.withValues(alpha: 0.08),
                              trackWidth: 2,
                              progressWidth: 3,
                              ornamentColor: Colors.white.withValues(alpha: 0.12),
                              ornamentWidth: 2,
                              ornamentRadiusScale: 1.18,
                            ),
                          ),
                        ),
                      ),

                      Hero(
                        tag: widget.heroCoverTag,
                        child: RotationTransition(
                          turns: _coverRotationController,
                          child: Container(
                            width: 250,
                            height: 250,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  blurRadius: 30,
                                  offset: const Offset(0, 15),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.network(
                                    handler.mediaItem.value?.artUri?.toString() ?? _displayItem.coverUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, e, s) => Container(color: ProMaxColors.stitchCozyCardBg),
                                  ),
                                  Center(
                                    child: Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: ProMaxColors.stitchCozyBg.withValues(alpha: 0.8),
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white12, width: 2),
                                      ),
                                      child: Center(
                                        child: Container(
                                          width: 8, height: 8, 
                                          decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ).animate(target: playing ? 1 : 0, onPlay: (c) => c.repeat(reverse: true))
                           .scale(begin: const Offset(1, 1), end: const Offset(1.02, 1.02), duration: 5.seconds, curve: Curves.easeInOut),
                        ),
                      ),
                      
                      // time labels moved outside arc to match design
                    ],
                  ),
                  SizedBox(
                    width: 320,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDuration(Duration(seconds: (effectiveSeconds - startSec).toInt())),
                            style: GoogleFonts.manrope(color: ProMaxColors.stitchCozyTextMuted, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            _formatDuration(Duration(seconds: rangeSeconds)),
                            style: GoogleFonts.manrope(color: ProMaxColors.stitchCozyTextMuted, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      }
    );
  }

  Widget _buildTrackInfo(MediaItem? item) {
    final category = item?.extras?['category']?.toString();
    final artist = item?.artist ?? _displayItem.artist;
    final badge = (category != null && category.isNotEmpty) ? category : "未分类";
    final subtitle = artist.isNotEmpty ? artist : "未知UP主";
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Hero(
              tag: widget.heroTitleTag,
              child: Text(
                item?.title ?? _displayItem.title,
                style: GoogleFonts.manrope(
                  color: ProMaxColors.stitchCozyTextLight,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ),
        ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1, end: 0),
        const SizedBox(height: 12),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: ProMaxColors.stitchCozyAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: ProMaxColors.stitchCozyAccent.withValues(alpha: 0.2)),
              ),
              child: Text(
                badge,
                style: TextStyle(
                  color: ProMaxColors.stitchCozyAccent,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              subtitle,
              style: TextStyle(
                color: ProMaxColors.stitchCozyTextMuted,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ).animate().fadeIn(duration: 600.ms, delay: 200.ms),
      ],
    );
  }

  void _handleArcDrag(Offset localPos, int startSec, int endSec) {
    const double size = 310;
    final center = const Offset(size / 2, size / 2);
    final dx = localPos.dx - center.dx;
    final dy = localPos.dy - center.dy;
    final r = math.sqrt(dx * dx + dy * dy);
    if (r < 90) return; // avoid jumps when dragging near center

    double angle = math.atan2(dy, dx);
    if (angle < 0) angle += math.pi * 2;
    final progress = _angleToArcProgress(angle);

    final totalSeconds = (endSec - startSec).clamp(1, 24 * 60 * 60);
    setState(() {
      _isDragging = true;
      _dragValue = (startSec + (progress * totalSeconds)).clamp(startSec, endSec).toDouble();
    });
  }

  double _angleToArcProgress(double angle) {
    final start = math.pi * 0.8;
    final sweep = math.pi * 1.4;
    final end = start + sweep;
    final twoPi = math.pi * 2;

    // Arc wraps past 2π, so valid region is [start, 2π) U [0, end-2π]
    final wraps = end > twoPi;
    final inArc = wraps
        ? (angle >= start || angle <= (end - twoPi))
        : (angle >= start && angle <= end);

    double clampedAngle;
    if (inArc) {
      clampedAngle = angle;
      if (wraps && angle <= (end - twoPi)) {
        clampedAngle = angle + twoPi;
      }
    } else {
      // Clamp to nearest endpoint to avoid jumping across the start
      final startDist = _angularDistance(angle, start);
      final endAngle = wraps ? (end - twoPi) : end;
      final endDist = _angularDistance(angle, endAngle);
      clampedAngle = (startDist <= endDist) ? start : end;
    }

    return ((clampedAngle - start) / sweep).clamp(0.0, 1.0);
  }

  double _angularDistance(double a, double b) {
    final diff = (a - b).abs();
    final twoPi = math.pi * 2;
    return diff > math.pi ? twoPi - diff : diff;
  }

  void _commitArcDrag(AudioHandler handler, int startSec, int endSec) {
    if (_dragValue != null) {
      handler.seek(Duration(seconds: _dragValue!.toInt()));
    }
    setState(() {
      _isDragging = false;
      _dragValue = null;
    });
  }

  Widget _buildMainControls(AudioHandler handler) {
    return StreamBuilder<PlaybackState>(
      stream: handler.playbackState,
      builder: (context, snapshot) {
        final playing = snapshot.data?.playing ?? false;
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.skip_previous_rounded, color: ProMaxColors.stitchCozyTextMuted, size: 40),
              onPressed: () => handler.skipToPrevious(),
            ),
            const SizedBox(width: 40),
            GestureDetector(
              onTap: () => playing ? handler.pause() : handler.play(),
              child: Container(
                width: 92,
                height: 92,
                decoration: const BoxDecoration(
                  color: ProMaxColors.stitchCozyAccent,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x66D98D4F),
                      blurRadius: 30,
                      offset: Offset(0, 10),
                    )
                  ],
                ),
                child: Icon(
                  playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  size: 52,
                  color: ProMaxColors.stitchCozyBg,
                ),
              ),
            ),
            const SizedBox(width: 40),
            IconButton(
              icon: const Icon(Icons.skip_next_rounded, color: ProMaxColors.stitchCozyTextMuted, size: 40),
              onPressed: () => handler.skipToNext(),
            ),
          ],
        );
      }
    );
  }

  Widget _buildBottomActionPanel(BuildContext context, AudioHandler handler) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: ProMaxColors.stitchCozyCardBg.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.03)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildModeButton(handler),
          _buildActionIcon(Icons.queue_music_rounded, true, false, () => _showPlaylistSheet(context, audioHandler: handler)),
          _buildSleepButton(handler, () => _showSleepTimerDialog(context, audioHandler: handler)),
        ],
      ),
    );
  }

  Widget _buildActionIcon(IconData icon, bool hasIndicator, bool isActive, VoidCallback onTap) {
    final color = isActive ? ProMaxColors.stitchCozyAccent : ProMaxColors.stitchCozyTextMuted;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            if (hasIndicator) ...[
              const SizedBox(height: 6),
              Container(width: 4, height: 4, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            ] else
              const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildModeButton(AudioHandler handler) {
    if (handler is! AudioPlayerHandler) {
      return _buildActionIcon(Icons.shuffle_rounded, false, false, () {});
    }
    return StreamBuilder<bool>(
      stream: handler.shuffleModeStream,
      initialData: handler.isShuffleEnabled,
      builder: (context, shuffleSnap) {
        return StreamBuilder<AudioServiceRepeatMode>(
          stream: handler.repeatModeStream,
          initialData: AudioServiceRepeatMode.none,
          builder: (context, repeatSnap) {
            final shuffleEnabled = shuffleSnap.data ?? false;
            final repeatMode = repeatSnap.data ?? AudioServiceRepeatMode.none;
            final icon = shuffleEnabled
              ? Icons.shuffle_rounded
              : (repeatMode == AudioServiceRepeatMode.one ? Icons.repeat_one_rounded : Icons.repeat_rounded);
            final active = shuffleEnabled || repeatMode != AudioServiceRepeatMode.none;
            return _buildActionIcon(icon, false, active, () => handler.cyclePlayMode());
          },
        );
      },
    );
  }

  Widget _buildSleepButton(AudioHandler handler, VoidCallback onTap) {
    if (handler is! AudioPlayerHandler) {
      return _buildActionIcon(Icons.nights_stay_rounded, false, false, onTap);
    }

    return StreamBuilder<int>(
      stream: Stream.periodic(const Duration(seconds: 1), (i) => i),
      builder: (context, _) {
        final end = handler.sleepTimerEnd;
        final now = DateTime.now();
        Duration? remaining;
        if (end != null && end.isAfter(now)) {
          remaining = end.difference(now);
        }
        final active = remaining != null;
        return InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.nights_stay_rounded, color: active ? ProMaxColors.stitchCozyAccent : ProMaxColors.stitchCozyTextMuted, size: 22),
                if (active) ...[
                  const SizedBox(width: 6),
                  Text(
                    _formatDuration(remaining!),
                    style: TextStyle(color: ProMaxColors.stitchCozyAccent, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ],
            ),
          ),
        );
      },
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

class ProgressArcPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;
  final double trackWidth;
  final double progressWidth;
  final Color ornamentColor;
  final double ornamentWidth;
  final double ornamentRadiusScale;

  ProgressArcPainter({
    required this.progress,
    required this.color,
    this.trackColor = const Color(0x14FFFFFF),
    this.trackWidth = 2,
    this.progressWidth = 3,
    this.ornamentColor = const Color(0x14FFFFFF),
    this.ornamentWidth = 2,
    this.ornamentRadiusScale = 1.15,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final ornamentRadius = radius * ornamentRadiusScale;

    final ornamentPaint = Paint()
      ..color = ornamentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = ornamentWidth
      ..strokeCap = StrokeCap.round;

    // Decorative arc above the progress track
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: ornamentRadius),
      math.pi * 0.9,
      math.pi * 0.95,
      false,
      ornamentPaint,
    );
    
    final paintBase = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = trackWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi * 0.8, 
      math.pi * 1.4, 
      false,
      paintBase,
    );

    final paintProgress = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = progressWidth
      ..strokeCap = StrokeCap.round;

    final double activeSweep = (math.pi * 1.4) * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi * 0.8,
      activeSweep,
      false,
      paintProgress,
    );

    final double thumbAngle = (math.pi * 0.8) + activeSweep;
    final thumbX = center.dx + radius * math.cos(thumbAngle);
    final thumbY = center.dy + radius * math.sin(thumbAngle);
    
    canvas.drawCircle(Offset(thumbX, thumbY), 6, Paint()..color = color);
    canvas.drawCircle(
      Offset(thumbX, thumbY), 
      12, 
      Paint()..color = color.withValues(alpha: 0.2)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
  }

  @override
  bool shouldRepaint(covariant ProgressArcPainter oldDelegate) => oldDelegate.progress != progress;
}

// --- High-Fidelity Playlist Sheet ---
class _PlaylistSheet extends StatelessWidget {
  final AudioHandler handler;
  const _PlaylistSheet({required this.handler});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Color(0xFF140F0D),
        borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 48,
            height: 6,
            decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(3)),
          ),
          
          // Header section
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 8, 28, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          "播放列表",
                          style: GoogleFonts.manrope(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                        ),
                        const SizedBox(width: 10),
                        StreamBuilder<List<MediaItem>>(
                          stream: handler.queue,
                          builder: (context, snap) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: const Color(0xFF2D241E), borderRadius: BorderRadius.circular(10)),
                            child: Text("${snap.data?.length ?? 0}", style: const TextStyle(color: ProMaxColors.stitchCozyAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text("当前队列", style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 13, fontWeight: FontWeight.w500)),
                  ],
                ),
                TextButton.icon(
                  onPressed: () {
                    if (handler is AudioPlayerHandler) (handler as AudioPlayerHandler).clearQueue();
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.delete_outline_rounded, size: 16),
                  label: const Text("清空列表", style: TextStyle(fontWeight: FontWeight.bold)),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white38,
                    backgroundColor: const Color(0xFF2D241E),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
              ],
            ),
          ),
          
          // Sorting Hint
          Padding(
            padding: const EdgeInsets.only(left: 28, bottom: 18),
            child: Row(
              children: [
                const Icon(Icons.drag_indicator_rounded, color: ProMaxColors.stitchCozyAccent, size: 16),
                const SizedBox(width: 8),
                Text("长按并拖动以排序", style: TextStyle(color: Colors.white.withValues(alpha: 0.25), fontSize: 12, fontWeight: FontWeight.w500)),
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
                          itemCount: queue.length,
                          onReorder: (oldIndex, newIndex) {
                            if (newIndex > oldIndex) newIndex -= 1;
                            if (handler is AudioPlayerHandler) {
                              (handler as AudioPlayerHandler).reorderQueue(oldIndex, newIndex);
                            }
                          },
                          itemBuilder: (context, index) {
                            final item = queue[index];
                            final isPlaying = playingId == item.id;
                            return _buildPlaylistItem(
                              context,
                              item,
                              index,
                              isPlaying,
                              currentPosition: isPlaying ? pos : null,
                              key: ValueKey(item.id),
                            );
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

  Widget _buildPlaylistItem(
    BuildContext context,
    MediaItem item,
    int index,
    bool isPlaying, {
    required Key key,
    Duration? currentPosition,
  }) {
    final String indexStr = (index + 1).toString().padLeft(2, '0');
    
    if (isPlaying) {
      return Container(
        key: key,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              ProMaxColors.stitchCozyAccent.withValues(alpha: 0.2),
              ProMaxColors.stitchCozyAccent.withValues(alpha: 0.05),
            ],
          ),
          border: Border.all(color: ProMaxColors.stitchCozyAccent.withValues(alpha: 0.3), width: 1),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF1A120B),
            borderRadius: BorderRadius.circular(24),
          ),
          child: InkWell(
            onTap: () {
              if (handler is AudioPlayerHandler) {
                (handler as AudioPlayerHandler).skipToQueueIndex(index);
              }
            },
            child: Row(
              children: [
                // Rotating Visualizer / Icon
                Container(
                  width: 52,
                  height: 52,
                  decoration: const BoxDecoration(color: ProMaxColors.stitchCozyAccent, shape: BoxShape.circle),
                  child: const Icon(Icons.graphic_eq_rounded, color: Color(0xFF140F0D), size: 22),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.manrope(color: ProMaxColors.stitchCozyAccent, fontSize: 16, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.play_arrow_rounded, color: ProMaxColors.stitchCozyAccent, size: 14),
                          const SizedBox(width: 4),
                          const Text("播放中", style: TextStyle(color: ProMaxColors.stitchCozyAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                          const Spacer(),
                          Text("${_formatDurationStr(currentPosition)} / ${_formatDurationStr(item.duration)}", 
                            style: TextStyle(color: ProMaxColors.stitchCozyAccent.withValues(alpha: 0.8), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5)
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white30, size: 22),
                  onPressed: () {
                    if (handler is AudioPlayerHandler) {
                      (handler as AudioPlayerHandler).removeQueueItemById(item.id);
                    }
                  },
                ),
                const SizedBox(width: 4),
                const Icon(Icons.drag_handle_rounded, color: ProMaxColors.stitchCozyAccent, size: 24),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      key: key,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: InkWell(
        onTap: () {
          if (handler is AudioPlayerHandler) {
            (handler as AudioPlayerHandler).skipToQueueIndex(index);
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF1A120B),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF1D1612),
                  shape: BoxShape.circle,
                  border: Border.all(color: ProMaxColors.stitchCozyAccent.withValues(alpha: 0.2), width: 1),
                ),
                child: Center(child: Text(indexStr, style: const TextStyle(color: Colors.white38, fontWeight: FontWeight.w900, fontSize: 13))),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.manrope(color: Colors.white.withValues(alpha: 0.8), fontSize: 15, fontWeight: FontWeight.w700)
                    ),
                    const SizedBox(height: 2),
                    Text(item.artist ?? "未知作者", style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(_formatDurationStr(item.duration), style: const TextStyle(color: Colors.white10, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(width: 20),
              IconButton(
                icon: Icon(Icons.close_rounded, color: Colors.white.withValues(alpha: 0.25), size: 22),
                onPressed: () {
                  if (handler is AudioPlayerHandler) {
                    (handler as AudioPlayerHandler).removeQueueItemById(item.id);
                  }
                },
              ),
              const SizedBox(width: 4),
              const Icon(Icons.drag_handle_rounded, color: ProMaxColors.stitchCozyAccent, size: 24),
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

// --- High-Fidelity Sleep Timer Sheet ---
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
  bool _stopAtEnd = false;

  @override
  void initState() {
    super.initState();
    if (widget.handler is AudioPlayerHandler) {
      final h = widget.handler as AudioPlayerHandler;
      _fadeOut = h.fadeOutEnabled;
      _stopAtEnd = h.stopAtEndEnabled;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
      decoration: const BoxDecoration(
        color: Color(0xFF140F0D),
        borderRadius: BorderRadius.vertical(top: Radius.circular(44)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 48, height: 6, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(3))),
          const SizedBox(height: 22),
          
          const Text("睡眠定时", style: TextStyle(color: Colors.white38, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.nights_stay_rounded, color: Color(0xFFEE8C2B), size: 30),
              const SizedBox(width: 10),
              Text(
                "${_selectedMinutes}分钟后停止",
                style: GoogleFonts.manrope(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.8,
            children: [
              _buildPresetBtn("不启用", 0),
              _buildPresetBtn("15分钟", 15),
              _buildPresetBtn("30分钟", 30),
              _buildPresetBtn("60分钟", 60),
              _buildPresetBtn("90分钟", 90),
              _buildEditBtn(),
            ],
          ),
          
          const SizedBox(height: 28),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("自定义", style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 13, fontWeight: FontWeight.bold)),
              Text("${_customValue.toInt()} min", style: const TextStyle(color: ProMaxColors.stitchCozyAccent, fontSize: 13, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              activeTrackColor: ProMaxColors.stitchCozyAccent,
              inactiveTrackColor: Colors.white10,
              thumbColor: ProMaxColors.stitchCozyAccent,
              overlayColor: ProMaxColors.stitchCozyAccent.withValues(alpha: 0.1),
            ),
            child: Slider(
              value: _customValue,
              min: 0, max: 120,
              onChanged: (v) => setState(() {
                _customValue = v;
                _selectedMinutes = v.toInt();
              }),
            ),
          ),
          const SizedBox(height: 8),
          Row(
             mainAxisAlignment: MainAxisAlignment.spaceBetween,
             children: [
               Text("0", style: TextStyle(color: Colors.white10, fontSize: 10)),
               Text("120", style: TextStyle(color: Colors.white10, fontSize: 10)),
             ],
          ),
          
          const SizedBox(height: 24),
          
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF1A120B),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Column(
              children: [
                _buildToggleRow(Icons.volume_down_rounded, "声音渐弱停止", "结束前最后1分钟音量渐隐", _fadeOut, (v) {
                  setState(() => _fadeOut = v);
                }),
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
                _buildToggleRow(Icons.nights_stay_rounded, "播放到本曲结束停止", "", _stopAtEnd, (v) {
                  setState(() => _stopAtEnd = v);
                }),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          SizedBox(
            width: double.infinity,
            height: 64,
            child: ElevatedButton(
              onPressed: () {
                if (widget.handler is AudioPlayerHandler) {
                   final h = widget.handler as AudioPlayerHandler;
                   h.setFadeOutEnabled(_fadeOut);
                   h.setSleepTimerAtEnd(_stopAtEnd);
                   if (_selectedMinutes > 0) {
                     h.setSleepTimer(Duration(minutes: _selectedMinutes));
                   } else {
                     h.cancelSleepTimer();
                   }
                }
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: ProMaxColors.stitchCozyAccent,
                foregroundColor: const Color(0xFF140F0D),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                elevation: 12,
                shadowColor: ProMaxColors.stitchCozyAccent.withValues(alpha: 0.4),
              ),
              child: const Text("确 定", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 4)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetBtn(String label, int mins) {
    bool isSelected = _selectedMinutes == mins;
    return GestureDetector(
      onTap: () => setState(() {
        _selectedMinutes = mins;
        _customValue = mins.toDouble();
      }),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? ProMaxColors.stitchCozyAccent : const Color(0xFF1D1612),
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected ? [
            BoxShadow(color: ProMaxColors.stitchCozyAccent.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))
          ] : null,
        ),
        child: Center(
          child: Text(label, style: TextStyle(
            color: isSelected ? const Color(0xFF140F0D) : Colors.white.withValues(alpha: 0.4), 
            fontWeight: FontWeight.bold, fontSize: 14)
          ),
        ),
      ),
    );
  }

  Widget _buildEditBtn() {
    return Container(
      decoration: BoxDecoration(color: const Color(0xFF1D1612), borderRadius: BorderRadius.circular(20)),
      child: const Icon(Icons.edit_note_rounded, color: Colors.white24, size: 28),
    );
  }

  Widget _buildToggleRow(IconData icon, String title, String sub, bool val, ValueChanged<bool> onChanged) {
    return Row(
      children: [
        Container(
          width: 40, height: 40,
          decoration: const BoxDecoration(color: Color(0xFF2D241E), shape: BoxShape.circle),
          child: Icon(icon, color: ProMaxColors.stitchCozyAccent, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
              if (sub.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(sub, style: TextStyle(color: Colors.white.withValues(alpha: 0.25), fontSize: 11)),
              ],
            ],
          ),
        ),
        Switch(
          value: val, 
          onChanged: onChanged,
          activeThumbColor: Colors.white,
          activeTrackColor: ProMaxColors.stitchCozyAccent,
          inactiveTrackColor: Colors.white10,
        ),
      ],
    );
  }
}
