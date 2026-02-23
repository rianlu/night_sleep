import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:night_sleep/core/theme/app_palette.dart';
import 'package:night_sleep/core/theme/glass_style.dart';
import 'package:night_sleep/features/player/data/audio_player_handler.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';

class HomePlayScreen extends StatefulWidget {
  final VoidCallback? onNavigateToLibrary;

  const HomePlayScreen({super.key, this.onNavigateToLibrary});

  @override
  State<HomePlayScreen> createState() => _HomePlayScreenState();
}

class _HomePlayScreenState extends State<HomePlayScreen> {
  final List<double> _speedOptions = const [0.75, 1.0, 1.25, 1.5];
  final List<int> _timerOptions = const [0, 15, 30, 45, 60];

  bool _expanded = false;
  double? _dragProgress; // 添加此变量用于平滑拖动

  AppPalette _palette(ThemeData theme) => theme.extension<AppPalette>()!;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final handler = context.read<AudioHandler>();
    final width = MediaQuery.sizeOf(context).width;
    final compact = width <= AppConstants.compactBreakpoint;
    final hPad = compact ? 20.0 : 24.0;
    final topPad = compact ? 18.0 : 22.0;

    return Scaffold(
      body: SafeArea(
        child: StreamBuilder<List<MediaItem>>(
          stream: handler.queue,
          initialData: handler.queue.value,
          builder: (context, queueSnap) {
            final activeQueue = _buildDisplayQueue(queueSnap.data ?? []);

            return ListView(
              padding: EdgeInsets.fromLTRB(hPad, topPad, hPad, 124),
              children: [
                _buildHeader(theme),
                const SizedBox(height: 20),
                _buildPlayerCard(theme, handler, activeQueue),
                const SizedBox(height: 24),
                _buildQueueHeader(theme, handler, activeQueue),
                const SizedBox(height: 16),
                if (activeQueue.isEmpty)
                  _buildEmptyQueue(theme)
                else
                  Column(
                    children: List.generate(
                      activeQueue.length > 3 ? 3 : activeQueue.length,
                      (index) {
                        final item = activeQueue[index];
                        return Padding(
                          key: ValueKey(item.id),
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _buildQueueItem(
                            theme,
                            handler,
                            activeQueue,
                            index,
                            item,
                            isModal: false,
                          ),
                        );
                      },
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    final palette = _palette(theme);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '今晚播放',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: palette.titleStrong,
            fontSize: 24,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerCard(
    ThemeData theme,
    AudioHandler handler,
    List<_QueueItemViewModel> queue,
  ) {
    final palette = _palette(theme);
    return StreamBuilder<MediaItem?>(
      stream: handler.mediaItem,
      initialData: handler.mediaItem.value,
      builder: (context, mediaSnap) {
        final media = mediaSnap.data;
        final currentVm = media != null
            ? _fromMediaItem(media)
            : (queue.isNotEmpty ? queue.first : null);

        return Container(
          decoration: BoxDecoration(
            color: palette.groupBg,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: palette.cardBorderSoft),
            boxShadow: [
              BoxShadow(
                color: palette.cardShadow,
                blurRadius: 30,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 20, 18, 8),
                child: Column(
                  children: [
                    _buildCurrentInfo(theme, currentVm),
                    const SizedBox(height: 16),
                    _buildProgress(theme, handler, media, currentVm),
                    const SizedBox(height: 18),
                    _buildPlaybackRow(theme, handler, media, queue, currentVm),
                  ],
                ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 400),
                curve: Curves.fastOutSlowIn,
                alignment: Alignment.topCenter,
                child: _expanded
                    ? _buildExpandedPanel(theme, handler)
                    : const SizedBox(width: double.infinity, height: 0),
              ),
              InkWell(
                onTap: () => setState(() => _expanded = !_expanded),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(32),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 2, 0, 10),
                  child: Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: palette.iconMuted,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCurrentInfo(ThemeData theme, _QueueItemViewModel? item) {
    final palette = _palette(theme);
    if (item == null) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 柔和的空状态封面, 大小与原 _cover 实际占据的 86px 对齐
          Container(
            width: 86,
            height: 86,
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: palette.cardBorderSoft.withValues(alpha: 0.5),
              ),
            ),
            child: Center(
              child: Icon(
                Icons.nights_stay_rounded,
                color: palette.titleMuted.withValues(alpha: 0.8), // 柔和的橙色月亮
                size: 36,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '今晚想听点什么？',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: palette.titleStrong,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '尚未播放音频',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: palette.titleMuted,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '选择一个曲目开始',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: palette.titleSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _cover(theme, item.coverUrl, 80),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: palette.titleStrong,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.artist,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    '选段: ${_format(item.start)} - ${_format(item.end)}',
                    style: TextStyle(
                      color: palette.titleMuted,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProgress(
    ThemeData theme,
    AudioHandler handler,
    MediaItem? media,
    _QueueItemViewModel? currentVm,
  ) {
    final palette = _palette(theme);
    if (media == null || currentVm == null) {
      return Column(
        children: [
          SizedBox(
            height: 20,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  '-:-',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: palette.titleSecondary.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                Text(
                  '-:-',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: palette.titleSecondary.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 20, // 强制给高度，防止布局抖动
            alignment: Alignment.center,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 6.0,
                width: double.infinity,
                color: palette.cardBorderSoft.withValues(alpha: 0.4),
              ),
            ),
          ),
        ],
      );
    }

    final totalRangeSec = (currentVm.end - currentVm.start).clamp(
      1,
      currentVm.duration,
    );

    return StreamBuilder<Duration>(
      stream: AudioService.position,
      initialData: handler.playbackState.value.position,
      builder: (context, posSnap) {
        final sec = posSnap.data?.inSeconds ?? currentVm.start;
        final withinRange = (sec - currentVm.start).clamp(0, totalRangeSec);
        final progress = withinRange / totalRangeSec;

        // 拖动过程中优先显示本地拖动计算的时间进度
        final displayProgress = _dragProgress ?? progress;
        final displaySec = _dragProgress != null
            ? (_dragProgress! * totalRangeSec).round() + currentVm.start
            : sec;

        return Column(
          children: [
            SizedBox(
              height: 20,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    _format(displaySec - currentVm.start),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: palette.queueMuted,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '-${_format(currentVm.end - displaySec)}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: palette.queueMuted,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 20, // 强制高度包裹，防止滑块自带边距导致布局突变
              child: TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                tween: Tween<double>(
                  begin: 6.0,
                  end: _dragProgress != null ? 10.0 : 6.0,
                ),
                builder: (context, trackHeight, child) {
                  return SliderTheme(
                    data: SliderThemeData(
                      trackHeight: trackHeight,
                      activeTrackColor: theme.colorScheme.primary,
                      inactiveTrackColor: theme.colorScheme.primary.withValues(
                        alpha: 0.15,
                      ),
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 0,
                        disabledThumbRadius: 0,
                      ),
                      overlayShape: SliderComponentShape.noOverlay,
                      trackShape: const RoundedRectSliderTrackShape(),
                    ),
                    child: child!,
                  );
                },
                child: Slider(
                  value: displayProgress,
                  onChangeStart: (val) {
                    setState(() => _dragProgress = val);
                  },
                  onChanged: (val) {
                    setState(() => _dragProgress = val);
                  },
                  onChangeEnd: (val) {
                    final targetSec =
                        (val * totalRangeSec).round() + currentVm.start;
                    handler.seek(Duration(seconds: targetSec));
                    // 稍微延时再放开控制权，避免 Stream 还没反馈位置而导致指针闪回
                    Future.delayed(const Duration(milliseconds: 300), () {
                      if (mounted) setState(() => _dragProgress = null);
                    });
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPlaybackRow(
    ThemeData theme,
    AudioHandler handler,
    MediaItem? media,
    List<_QueueItemViewModel> queue,
    _QueueItemViewModel? currentVm,
  ) {
    final palette = _palette(theme);
    return StreamBuilder<PlaybackState>(
      stream: handler.playbackState,
      initialData: handler.playbackState.value,
      builder: (context, stateSnap) {
        final playing = stateSnap.data?.playing ?? false;
        final speed = stateSnap.data?.speed ?? 1.0;
        final leftPill = InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.circular(999),
          child: _pill(theme, '${_formatSpeed(speed)}x', width: 52, height: 32),
        );
        final rightPill = StreamBuilder<DateTime?>(
          stream: Stream<DateTime?>.periodic(const Duration(seconds: 1), (_) {
            final typed = handler is AudioPlayerHandler ? handler : null;
            return typed?.sleepTimerEnd;
          }),
          builder: (context, timerSnap) {
            final timerEnd = timerSnap.data;
            final remain = _remaining(timerEnd);
            // 这里如果是空状态（media == null），右侧统一显示为“关闭”
            final text = (media == null) ? '关闭' : (remain ?? '定时');
            return InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              borderRadius: BorderRadius.circular(999),
              child: _pill(theme, text, width: 52, height: 32),
            );
          },
        );
        final isDisabled = queue.isEmpty || media == null;

        final controls = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: isDisabled ? null : () => handler.skipToPrevious(),
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: Icon(
                  Icons.skip_previous_rounded,
                  color: isDisabled
                      ? palette.titleSecondary.withValues(alpha: 0.4)
                      : theme.colorScheme.primary.withValues(alpha: 0.78),
                  size: 32,
                ),
              ),
            ),
            const SizedBox(width: 4),
            InkWell(
              onTap: queue.isEmpty
                  ? null // 队列为空时彻底失效，不允许尝试加载
                  : () async {
                      if (media == null) {
                        try {
                          await _startQueueAt(handler, queue, 0);
                        } catch (e) {
                          // Ignore
                        }
                        return;
                      }
                      if (playing) {
                        await handler.pause();
                      } else {
                        await handler.play();
                      }
                    },
              borderRadius: BorderRadius.circular(999),
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  // 加载中的半空状态也是浅色没有阴影
                  color: isDisabled
                      ? theme.colorScheme.primary.withValues(alpha: 0.4)
                      : theme.colorScheme.primary,
                  shape: BoxShape.circle,
                  boxShadow: isDisabled
                      ? []
                      : [
                          BoxShadow(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.3,
                            ),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                ),
                child: Icon(
                  playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  size: 38,
                  color: theme.colorScheme.onPrimary,
                ),
              ),
            ),
            const SizedBox(width: 4),
            InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: isDisabled ? null : () => handler.skipToNext(),
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: Icon(
                  Icons.skip_next_rounded,
                  color: isDisabled
                      ? palette.titleSecondary.withValues(alpha: 0.4)
                      : theme.colorScheme.primary.withValues(alpha: 0.78),
                  size: 32,
                ),
              ),
            ),
          ],
        );

        return Row(
          children: [
            SizedBox(
              width: 64,
              child: Align(alignment: Alignment.centerLeft, child: leftPill),
            ),
            Expanded(
              child: Center(
                child: FittedBox(fit: BoxFit.scaleDown, child: controls),
              ),
            ),
            SizedBox(
              width: 64,
              child: Align(alignment: Alignment.centerRight, child: rightPill),
            ),
          ],
        );
      },
    );
  }

  Widget _buildExpandedPanel(ThemeData theme, AudioHandler handler) {
    final palette = _palette(theme);
    final typed = handler is AudioPlayerHandler ? handler : null;
    if (typed == null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
        child: Text(
          '当前环境不支持高级播放控制',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.56),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: palette.panelDivider)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.speed, color: palette.titleMuted, size: 12),
              const SizedBox(width: 8),
              Text(
                '播放倍速',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: palette.titleStrong,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: StreamBuilder<PlaybackState>(
              stream: handler.playbackState,
              initialData: handler.playbackState.value,
              builder: (context, stateSnap) {
                final speed = stateSnap.data?.speed ?? 1.0;
                return Row(
                  children: _speedOptions.map((value) {
                    final selected = (speed - value).abs() < 0.001;
                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: _chip(
                        theme,
                        label: '${value}x',
                        selected: selected,
                        onTap: () => typed.setPlaybackSpeed(value),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.bedtime_outlined, color: palette.titleMuted, size: 12),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '睡眠定时',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: palette.titleStrong,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _timerOptions.map((minute) {
                final selected = _isTimerSelected(
                  typed.sleepTimerDuration,
                  minute,
                );
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: _chip(
                    theme,
                    label: minute == 0 ? '关闭' : '$minute分',
                    selected: selected,
                    onTap: () async {
                      if (minute == 0) {
                        typed.cancelSleepTimer();
                        setState(() {});
                        return;
                      }
                      await typed.setSleepTimer(Duration(minutes: minute));
                      if (mounted) setState(() {});
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildQueueHeader(
    ThemeData theme,
    AudioHandler handler,
    List<_QueueItemViewModel> queue,
  ) {
    final palette = _palette(theme);
    return Row(
      children: [
        Text(
          '待播放',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: palette.titleStrong,
            fontSize: 14,
          ),
        ),
        if (queue.isNotEmpty) ...[
          const Spacer(),
          InkWell(
            onTap: () => _showQueueModal(context, theme, handler),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '全部',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.queue_music_rounded,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _showQueueModal(
    BuildContext context,
    ThemeData theme,
    AudioHandler handler,
  ) {
    final Set<String> dismissedIds = {};
    // 追踪正在执行收缩动画的 ID
    final Set<String> removingIds = {};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: _palette(theme).modalBarrier,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return StreamBuilder<List<MediaItem>>(
            stream: handler.queue,
            initialData: handler.queue.value,
            builder: (context, snapshot) {
              final rawQueue = _buildDisplayQueue(snapshot.data ?? []);
              final queue = rawQueue
                  .where((item) => !dismissedIds.contains(item.id))
                  .toList();

              return ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(32),
                ),
                child: BackdropFilter(
                  filter: GlassStyle.blurFilter(
                    theme.brightness,
                    level: GlassLevel.sheet,
                  ),
                  child: Container(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.sizeOf(context).height * 0.85,
                    ),
                    decoration: BoxDecoration(
                      color: theme.scaffoldBackgroundColor.withValues(
                        alpha: GlassStyle.opacity(
                          theme.brightness,
                          level: GlassLevel.sheet,
                        ),
                      ),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(32),
                      ),
                      border: Border(top: GlassStyle.border(theme.brightness)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 12),
                        Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: _palette(
                              theme,
                            ).sheetHandle.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Row(
                            children: [
                              Text(
                                '播放队列',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _palette(theme).titleStrong,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '(${queue.length})',
                                style: TextStyle(
                                  color: _palette(theme).titleSecondary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              const Spacer(),
                              TextButton(
                                onPressed: queue.isEmpty
                                    ? null
                                    : () async {
                                        if (handler is AudioPlayerHandler) {
                                          await handler.clearQueue();
                                        }
                                      },
                                child: Text(
                                  '清空全部',
                                  style: TextStyle(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Flexible(
                          child: Theme(
                            data: theme.copyWith(
                              canvasColor: Colors.transparent,
                            ),
                            child: ReorderableListView.builder(
                              shrinkWrap: true,
                              proxyDecorator: (child, index, animation) {
                                return AnimatedBuilder(
                                  animation: animation,
                                  builder: (context, _) {
                                    final double animValue = Curves.easeInOut
                                        .transform(animation.value);
                                    final double scale =
                                        1.0 + (0.02 * animValue);
                                    return Transform.scale(
                                      scale: scale,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: theme.colorScheme.primary
                                                  .withValues(
                                                    alpha: 0.15 * animValue,
                                                  ),
                                              blurRadius: 15 * animValue,
                                              spreadRadius: 1 * animValue,
                                              offset: Offset(0, 8 * animValue),
                                            ),
                                          ],
                                        ),
                                        child: child,
                                      ),
                                    );
                                  },
                                );
                              },
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                              itemCount: queue.length,
                              buildDefaultDragHandles: false,
                              onReorder: (oldIndex, newIndex) {
                                if (newIndex > oldIndex) {
                                  newIndex -= 1;
                                }
                                if (handler is AudioPlayerHandler) {
                                  handler.reorderQueue(oldIndex, newIndex);
                                }
                              },
                              itemBuilder: (context, index) {
                                final item = queue[index];

                                // 使用 AnimatedSize 实现平滑的收缩动画
                                return AnimatedSize(
                                  key: ValueKey('anim_size_${item.id}'),
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                  child: removingIds.contains(item.id)
                                      ? const SizedBox(width: double.infinity)
                                      : AnimatedOpacity(
                                          duration: const Duration(
                                            milliseconds: 200,
                                          ),
                                          opacity: removingIds.contains(item.id)
                                              ? 0
                                              : 1,
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: 10,
                                            ),
                                            child: _buildQueueItem(
                                              theme,
                                              handler,
                                              queue,
                                              index,
                                              item,
                                              isModal: true,
                                              onRemove: () {
                                                // 触发收缩动画
                                                setModalState(
                                                  () =>
                                                      removingIds.add(item.id),
                                                );
                                                // 动画结束后正式移除数据
                                                Future.delayed(
                                                  const Duration(
                                                    milliseconds: 300,
                                                  ),
                                                  () {
                                                    dismissedIds.add(item.id);
                                                    final h =
                                                        handler
                                                            is AudioPlayerHandler
                                                        ? handler
                                                        : null;
                                                    h?.removeQueueItemById(
                                                      item.id,
                                                    );
                                                    if (context.mounted) {
                                                      setModalState(() {});
                                                    }
                                                  },
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                );
                              },
                            ),
                          ),
                        ),
                        if (queue.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 0, bottom: 32),
                            child: Center(
                              child: Text(
                                'END OF QUEUE',
                                style: TextStyle(
                                  letterSpacing: 4,
                                  color: _palette(theme).titleSecondary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          )
                        else
                          const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyQueue(ThemeData theme) {
    final palette = _palette(theme);
    return Padding(
      padding: const EdgeInsets.only(top: 40, bottom: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Moon Icon
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: palette.cardElevated,
              shape: BoxShape.circle,
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.2),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.04),
                  blurRadius: 10,
                  spreadRadius: 2,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.dark_mode_outlined,
              size: 48,
              color: theme.colorScheme.primary.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 24),
          // Title
          Text(
            '队列空空如也',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
              color: palette.titleStrong,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          // Subtitle
          Text(
            '去本地库添加一些助眠音频吧',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: palette.titleSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 32),
          // Action Button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onNavigateToLibrary,
              borderRadius: BorderRadius.circular(100),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.add_rounded,
                        size: 16,
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '去添加',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQueueItem(
    ThemeData theme,
    AudioHandler handler,
    List<_QueueItemViewModel> queue,
    int index,
    _QueueItemViewModel item, {
    required bool isModal,
    VoidCallback? onRemove,
  }) {
    final palette = _palette(theme);
    return StreamBuilder<MediaItem?>(
      stream: handler.mediaItem,
      initialData: handler.mediaItem.value,
      builder: (context, mediaSnap) {
        final playingId = mediaSnap.data?.id;
        final active = playingId == item.id;

        final content = Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _startQueueAt(handler, queue, index),
            borderRadius: BorderRadius.circular(isModal ? 20 : 24),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isModal ? 12 : 16,
                vertical: isModal ? 10 : 14,
              ),
              decoration: BoxDecoration(
                color: isModal
                    ? (active ? palette.cardElevated : palette.groupBg)
                    : (active ? palette.queueActiveBg : Colors.transparent),
                borderRadius: BorderRadius.circular(isModal ? 20 : 24),
                border: Border.all(
                  color: active
                      ? theme.colorScheme.primary.withValues(alpha: 0.28)
                      : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  if (isModal) ...[
                    ReorderableDragStartListener(
                      index: index,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(
                          Icons.drag_indicator_rounded,
                          color: palette.queueMutedSoft,
                          size: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  _cover(theme, item.coverUrl, isModal ? 52 : 52),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: active
                                ? theme.colorScheme.primary
                                : palette.titleStrong.withValues(alpha: 0.8),
                            fontSize: isModal ? 15 : 16,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${item.artist} · ${_format(item.start)}-${_format(item.end)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: palette.queueMuted,
                            fontSize: isModal ? 12 : 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (active)
                    StreamBuilder<PlaybackState>(
                      stream: handler.playbackState,
                      builder: (context, snapshot) {
                        final playing = snapshot.data?.playing ?? false;
                        return _AnimatedEqualizer(
                          color: theme.colorScheme.primary,
                          size: 24,
                          isPlaying: playing,
                        );
                      },
                    )
                  else if (isModal)
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: onRemove,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          Icons.close_rounded,
                          size: 20,
                          color: palette.queueMutedSoft.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );

        return content;
      },
    );
  }

  Future<void> _startQueueAt(
    AudioHandler handler,
    List<_QueueItemViewModel> queue,
    int index,
  ) async {
    if (handler is AudioPlayerHandler) {
      final target = queue[index];
      final currentId = handler.mediaItem.value?.id;
      if (currentId == target.id) {
        final isPlaying = handler.playbackState.value.playing;
        if (!isPlaying) {
          await handler.play();
        }
        return;
      }

      await handler.skipToQueueItemById(target.id, forceRestart: true);
      await handler.play();
    }
  }

  List<_QueueItemViewModel> _buildDisplayQueue(List<MediaItem> mediaQueue) {
    return mediaQueue.map(_fromMediaItem).toList();
  }

  _QueueItemViewModel _fromMediaItem(MediaItem item) {
    final duration = item.duration?.inSeconds ?? 0;
    final start = (item.extras?['startTime'] as int?) ?? 0;
    final end = ((item.extras?['endTime'] as int?) ?? duration).clamp(
      0,
      duration,
    );

    return _QueueItemViewModel(
      id: item.id,
      title: item.title,
      artist: item.artist ?? '未知来源',
      coverUrl: item.artUri?.toString() ?? '',
      duration: duration,
      start: start,
      end: end,
    );
  }

  Widget _cover(ThemeData theme, String? url, double size) {
    final palette = _palette(theme);
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: palette.cardSubtle,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.cardBorderSoft),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: size,
          height: size,
          color: theme.colorScheme.secondary,
          child: (url == null || url.isEmpty)
              ? Icon(Icons.music_note_rounded, color: theme.colorScheme.primary)
              : Image.network(
                  url,
                  fit: BoxFit.cover,
                  errorBuilder: (_, error, stackTrace) => Icon(
                    Icons.music_note_rounded,
                    color: theme.colorScheme.primary,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _pill(
    ThemeData theme,
    String label, {
    double? width,
    double height = 32,
    double minWidth = 52,
  }) {
    final palette = _palette(theme);
    return Container(
      width: width,
      constraints: width == null
          ? BoxConstraints(minWidth: minWidth, minHeight: height)
          : BoxConstraints.tightFor(height: height),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: palette.pillBg,
        border: Border.all(color: palette.pillBorder),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: palette.pillText,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _chip(
    ThemeData theme, {
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final palette = _palette(theme);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? theme.colorScheme.primary : palette.pillBg,
          borderRadius: BorderRadius.circular(12),
          border: selected ? null : Border.all(color: palette.pillBorder),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? theme.colorScheme.onPrimary : palette.pillText,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  String _format(int seconds) {
    final safe = seconds < 0 ? 0 : seconds;
    final m = (safe ~/ 60).toString().padLeft(2, '0');
    final s = (safe % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String _formatSpeed(double speed) {
    return speed.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
  }

  String? _remaining(DateTime? end) {
    if (end == null) return null;
    final diff = end.difference(DateTime.now());
    if (diff.isNegative) return null;
    final h = diff.inHours;
    final m = diff.inMinutes % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
    }
    final s = diff.inSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  bool _isTimerSelected(Duration? current, int minute) {
    if (minute == 0) return current == null;
    return current?.inMinutes == minute;
  }
}

class _QueueItemViewModel {
  const _QueueItemViewModel({
    required this.id,
    required this.title,
    required this.artist,
    required this.coverUrl,
    required this.duration,
    required this.start,
    required this.end,
  });

  final String id;
  final String title;
  final String artist;
  final String coverUrl;
  final int duration;
  final int start;
  final int end;
}

/// 正在播放时显示的动态音频均衡器指示条
class _AnimatedEqualizer extends StatefulWidget {
  const _AnimatedEqualizer({
    required this.color,
    required this.size,
    required this.isPlaying,
  });

  final Color color;
  final double size;
  final bool isPlaying;

  @override
  State<_AnimatedEqualizer> createState() => _AnimatedEqualizerState();
}

class _AnimatedEqualizerState extends State<_AnimatedEqualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  static const _pi = 3.14159265;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    if (widget.isPlaying) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant _AnimatedEqualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _barHeight(int index) {
    // 三根线条不同的相位偏移 + 不同的频率，产生自然交错
    const phases = [0.0, 0.4, 0.8];
    const speeds = [1.0, 1.4, 0.9];
    final t = (_controller.value * speeds[index] + phases[index]) % 1.0;
    final sin = _sinApprox(t * 2 * _pi);
    return 0.3 + 0.7 * (0.5 + 0.5 * sin); // 在 30%~100% 之间波动
  }

  /// Bhaskara I 正弦近似，避免引入 dart:math
  double _sinApprox(double x) {
    x = x % (2 * _pi);
    if (x < 0) x += 2 * _pi;
    if (x > _pi) return -_sinApprox(x - _pi);
    return 16 * x * (_pi - x) / (5 * _pi * _pi - 4 * x * (_pi - x));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(3, (i) {
              return Container(
                width: widget.size * 0.16,
                height: widget.size * 0.75 * _barHeight(i),
                margin: EdgeInsets.symmetric(horizontal: widget.size * 0.025),
                decoration: BoxDecoration(
                  color: widget.color,
                  borderRadius: BorderRadius.circular(widget.size * 0.06),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}
