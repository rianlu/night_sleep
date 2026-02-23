import 'dart:async';
import 'dart:math' as math;
import 'package:audio_service/audio_service.dart';
import 'package:dio/dio.dart';
import 'package:just_audio/just_audio.dart';
import 'package:night_sleep/core/utils/bilibili_id_utils.dart';
import 'package:night_sleep/core/utils/app_preferences.dart';
import 'package:night_sleep/data/models/video_item.dart';
import 'package:night_sleep/features/import/data/bilibili_video_audio_service.dart';

class AudioPlayerHandler extends BaseAudioHandler
    with QueueHandler, SeekHandler {
  final _player = AudioPlayer();
  Timer? _sleepTimer;
  bool _fadeOutEnabled = true;
  bool _stopAtEndOfTrack = false;
  Duration? _sleepTimerDuration;
  DateTime? _sleepTimerEnd;
  VideoItem? _currentItem;
  bool _isTaskRunning = false;
  Completer<void>? _currentPlayTask;

  AudioPlayerHandler() {
    // 必须初始化初始值，否则 UI 在 StreamBuilder 的 initialData 中访问 .value 会崩溃
    // 这解决了你发现的“已导入音频看不到”的问题，因为 UI 崩溃导致了界面显示异常
    queue.add([]);
    mediaItem.add(null);
    playbackState.add(
      PlaybackState(
        controls: [
          MediaControl.play,
          MediaControl.skipToNext,
          MediaControl.skipToPrevious,
          MediaControl.stop,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.skipToNext,
          MediaAction.skipToPrevious,
        },
        playing: false,
        updatePosition: Duration.zero,
        processingState: AudioProcessingState.idle,
      ),
    );

    _player.playbackEventStream.map(_transformEvent).listen(playbackState.add);
    _player.positionStream.listen((pos) {
      _checkPlaybackRange(pos);
      _checkPreFadeOut(pos);
    });
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        if (_stopAtEndOfTrack) {
          _stopAtEndOfTrack = false; // 重置标志
          pause();
          seek(Duration(seconds: _currentItem?.startTime ?? 0));
        } else {
          skipToNext();
        }
      }
    });

    unawaited(_restoreQueueFromPrefs());
  }

  Stream<AudioServiceRepeatMode> get repeatModeStream =>
      _player.loopModeStream.map((loopMode) {
        switch (loopMode) {
          case LoopMode.off:
            return AudioServiceRepeatMode.none;
          case LoopMode.one:
            return AudioServiceRepeatMode.one;
          case LoopMode.all:
            return AudioServiceRepeatMode.all;
        }
      });

  Stream<bool> get shuffleModeStream => _player.shuffleModeEnabledStream;
  bool get isShuffleEnabled => _player.shuffleModeEnabled;
  bool get fadeOutEnabled => _fadeOutEnabled;
  bool get stopAtEndEnabled => _stopAtEndOfTrack;

  Future<void> toggleShuffle() async {
    await _player.setShuffleModeEnabled(!_player.shuffleModeEnabled);
  }

  Future<void> cycleRepeatMode() async {
    final current = _player.loopMode;
    if (current == LoopMode.off) {
      await _player.setLoopMode(LoopMode.all);
    } else if (current == LoopMode.all) {
      await _player.setLoopMode(LoopMode.one);
    } else {
      await _player.setLoopMode(LoopMode.off);
    }
    playbackState.add(playbackState.value);
  }

  Future<void> cyclePlayMode() async {
    if (_player.shuffleModeEnabled) {
      await _player.setShuffleModeEnabled(false);
      await _player.setLoopMode(LoopMode.all);
      playbackState.add(playbackState.value);
      return;
    }

    if (_player.loopMode == LoopMode.off) {
      await _player.setShuffleModeEnabled(true);
      await _player.setLoopMode(LoopMode.off);
    } else if (_player.loopMode == LoopMode.all) {
      await _player.setLoopMode(LoopMode.one);
    } else {
      await _player.setLoopMode(LoopMode.off);
    }
    playbackState.add(playbackState.value);
  }

  Future<void> setPlaybackSpeed(double speed) async {
    await _player.setSpeed(speed);
    if (playbackState.hasValue) {
      playbackState.add(playbackState.value.copyWith(speed: speed));
    }
  }

  void _checkPlaybackRange(Duration position) {
    if (_currentItem != null) {
      final startTime = _currentItem!.startTime;
      final endTime = _currentItem!.endTime;
      if (!_player.playing) return;
      if (endTime > startTime && endTime < _currentItem!.duration) {
        final end = Duration(seconds: endTime);
        if (position >= end) {
          if (_stopAtEndOfTrack) {
            _stopAtEndOfTrack = false;
            pause();
            seek(Duration(seconds: startTime));
          } else if (_player.loopMode == LoopMode.one) {
            // 单曲循环：回到设定的开始时间
            seek(Duration(seconds: startTime));
          } else if (queue.value.length <= 1) {
            pause();
            seek(Duration(seconds: startTime));
          } else {
            skipToNext();
          }
        }
      }
    }
  }

  bool _isPreFadingOut = false;

  void _checkPreFadeOut(Duration position) {
    if (!_fadeOutEnabled || !_player.playing || _player.duration == null) {
      return;
    }

    Duration endTime = _player.duration!;
    if (_currentItem != null &&
        _currentItem!.endTime > _currentItem!.startTime &&
        _currentItem!.endTime < _currentItem!.duration) {
      endTime = Duration(seconds: _currentItem!.endTime);
    }

    final timeLeft = endTime - position;
    // 如果播放剩余时间不到 2 秒且未淡出，则触发淡出
    if (timeLeft <= const Duration(milliseconds: 2000) &&
        timeLeft > Duration.zero) {
      if (!_isPreFadingOut) {
        _isPreFadingOut = true;
        _fadeVolumeTo(0.0, 2000);
      }
    } else if (timeLeft > const Duration(milliseconds: 2500)) {
      _isPreFadingOut = false;
    }
  }

  Future<void> setSleepTimer(Duration duration) async {
    _sleepTimer?.cancel();
    _sleepTimerDuration = duration;
    _sleepTimerEnd = DateTime.now().add(duration);
    _sleepTimer = Timer(duration, () {
      _fadeOutAndStop();
    });
  }

  void setFadeOutEnabled(bool enable) {
    _fadeOutEnabled = enable;
  }

  int _fadeGeneration = 0;

  Future<void> _fadeVolumeTo(double targetVolume, int durationMs) async {
    final gen = ++_fadeGeneration;
    final startVolume = _player.volume;
    final diff = targetVolume - startVolume;
    if (diff == 0) return;

    const steps = 30;
    final stepDuration = Duration(milliseconds: durationMs ~/ steps);

    for (int i = 1; i <= steps; i++) {
      if (_fadeGeneration != gen) return; // 被新的渐变或操作打断
      await Future.delayed(stepDuration);
      if (_fadeGeneration != gen) return;
      await _player.setVolume(startVolume + diff * (i / steps));
    }
    await _player.setVolume(targetVolume);
  }

  Future<void> _fadeOutAndStop() async {
    if (!_fadeOutEnabled) {
      await stop();
      return;
    }
    await _fadeVolumeTo(0.0, 5000); // 5 seconds fade out for sleep timer
    if (_player.volume <= 0.05) {
      await stop();
    }
  }

  void cancelSleepTimer() {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    _sleepTimerDuration = null;
    _sleepTimerEnd = null;
  }

  Duration? get sleepTimerDuration => _sleepTimerDuration;
  DateTime? get sleepTimerEnd => _sleepTimerEnd;

  @override
  Future<void> play() async {
    _fadeGeneration++;
    if (_player.volume < 0.01) await _player.setVolume(1.0);
    return _player.play();
  }

  @override
  Future<void> pause() async {
    _fadeGeneration++;
    return _player.pause();
  }

  @override
  Future<void> stop() async {
    _sleepTimer?.cancel();
    _fadeGeneration++;
    await _player.stop();
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() async {
    if (queue.value.isEmpty) return;

    if (_player.loopMode == LoopMode.one) {
      // 强制重起当前曲目
      final current = mediaItem.value;
      if (current != null) {
        await _playMediaItem(current, forceRestart: true);
        return;
      }
    }

    int currentIndex = (queue.hasValue && mediaItem.hasValue)
        ? queue.value.indexWhere((item) => item.id == mediaItem.value?.id)
        : -1;
    if (currentIndex == -1) {
      if (queue.hasValue && queue.value.isNotEmpty) {
        await _playMediaItem(queue.value.first, forceRestart: true);
      }
      return;
    }

    int nextIndex;
    if (_player.shuffleModeEnabled && queue.value.length > 1) {
      // 实现真正的随机逻辑
      final random = math.Random();
      nextIndex = currentIndex;
      while (nextIndex == currentIndex) {
        nextIndex = random.nextInt(queue.value.length);
      }
    } else {
      nextIndex = currentIndex + 1;
    }

    if (nextIndex >= queue.value.length) {
      if (_player.loopMode == LoopMode.all) {
        nextIndex = 0;
      } else {
        await pause();
        await seek(Duration(seconds: _currentItem?.startTime ?? 0));
        return; // 队列结束，停止播放并重置进度
      }
    }

    final nextMediaItem = queue.value[nextIndex];
    await _playMediaItem(nextMediaItem, forceRestart: true);
  }

  @override
  Future<void> skipToPrevious() async {
    if (queue.value.isEmpty) return;

    if (_player.loopMode == LoopMode.one) {
      final current = mediaItem.value;
      if (current != null) {
        await _playMediaItem(current, forceRestart: true);
        return;
      }
    }

    int currentIndex = (queue.hasValue && mediaItem.hasValue)
        ? queue.value.indexWhere((item) => item.id == mediaItem.value?.id)
        : -1;
    if (currentIndex == -1) return;

    int prevIndex;
    if (_player.shuffleModeEnabled && queue.value.length > 1) {
      final random = math.Random();
      prevIndex = currentIndex;
      while (prevIndex == currentIndex) {
        prevIndex = random.nextInt(queue.value.length);
      }
    } else {
      prevIndex = currentIndex - 1;
    }

    if (prevIndex < 0) {
      if (_player.loopMode == LoopMode.all) {
        prevIndex = queue.value.length - 1;
      } else {
        return;
      }
    }

    final prevMediaItem = queue.value[prevIndex];
    await _playMediaItem(prevMediaItem, forceRestart: true);
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    switch (repeatMode) {
      case AudioServiceRepeatMode.none:
        await _player.setLoopMode(LoopMode.off);
        break;
      case AudioServiceRepeatMode.one:
        await _player.setLoopMode(LoopMode.one);
        break;
      case AudioServiceRepeatMode.group:
      case AudioServiceRepeatMode.all:
        await _player.setLoopMode(LoopMode.all);
        break;
    }
    // 更新状态以反映循环模式。
    // AudioService 在 PlaybackState 中不默认广播 repeatMode，通常在 just_audio_background 中处理。
    // 我们在此通过 playbackState.add 通知监听者。
    // 注意：AudioService 配合 just_audio 时，循环模式通常需要手动同步广播状态。
    // 我们在此通过通知 playbackState 变化来确保 UI 能够监听并更新模式图标。

    super.setRepeatMode(repeatMode);

    // 有效广播状态变更
    if (playbackState.hasValue) {
      playbackState.add(playbackState.value);
    }
  }

  Future<void> _playMediaItem(
    MediaItem item, {
    bool forceRestart = false,
  }) async {
    // 从 MediaItem 的 extras 中恢复 VideoItem
    final videoItem = VideoItem(
      id: item.id,
      title: item.title,
      artist: item.artist ?? '',
      coverUrl: item.artUri.toString(),
      duration: item.duration?.inSeconds ?? 0,
      endTime: item.extras?['endTime'] ?? item.duration?.inSeconds ?? 0,
      startTime: item.extras?['startTime'] ?? 0,
      skipEnd: item.extras?['skipEnd'] ?? 0,
      filePath: item.extras?['filePath'],
      cid: item.extras?['cid'],
      page: item.extras?['page'],
      category: item.extras?['category'],
      addedAt: DateTime.now(), // 播放时不重要
    );
    await playVideoItem(videoItem, forceRestart: forceRestart);
  }

  // 跳过到队列中的指定索引
  Future<void> skipToQueueIndex(int index) async {
    if (index < 0 || index >= queue.value.length) return;
    final item = queue.value[index];
    await _playMediaItem(item, forceRestart: true);
  }

  Future<void> skipToQueueItemById(
    String id, {
    bool forceRestart = true,
  }) async {
    final index = queue.value.indexWhere((item) => item.id == id);
    if (index < 0) return;
    final item = queue.value[index];
    await _playMediaItem(item, forceRestart: forceRestart);
  }

  Future<void> removeQueueItemById(String id) async {
    final index = queue.value.indexWhere((item) => item.id == id);
    if (index == -1) return;
    await removeQueueItemAt(index);
  }

  void reorderQueue(int oldIndex, int newIndex) {
    final list = List<MediaItem>.from(queue.value);
    if (oldIndex < 0 || oldIndex >= list.length) return;
    if (newIndex < 0 || newIndex >= list.length) return;
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    queue.add(list);
    unawaited(_persistQueue());
  }

  // 加载完整播放队列并播放指定索引
  Future<void> loadPlaylist(List<VideoItem> videos, int index) async {
    final mediaItems = videos.map((v) => _toMediaItem(v)).toList();
    queue.add(mediaItems);
    await _persistQueue();
    // 从列表点击进入时，通常希望强制开始播放（即使是当前 ID）
    await playVideoItem(videos[index], forceRestart: true);
  }

  MediaItem _toMediaItem(VideoItem item) {
    return MediaItem(
      id: item.id,
      album: "NightSleep",
      title: item.title,
      artist: item.artist,
      duration: Duration(seconds: item.duration),
      artUri: Uri.parse(item.coverUrl),
      extras: {
        'startTime': item.startTime,
        'endTime': item.endTime,
        'filePath': item.filePath,
        'skipEnd': item.skipEnd,
        'cid': item.cid,
        'page': item.page,
        'category': item.category,
      },
    );
  }

  Future<void> playVideoItem(
    VideoItem item, {
    bool forceRestart = false,
  }) async {
    // 使用简单的锁机制防止并发加载导致的 Loading interrupted
    while (_isTaskRunning) {
      await _currentPlayTask?.future;
    }

    _isTaskRunning = true;
    _currentPlayTask = Completer<void>();

    try {
      await _playVideoItemInternal(item, forceRestart: forceRestart);
    } catch (e) {
      // 捕获所有异常，防止崩溃
    } finally {
      _isTaskRunning = false;
      _currentPlayTask?.complete();
    }
  }

  Future<void> _playVideoItemInternal(
    VideoItem item, {
    bool forceRestart = false,
  }) async {
    _currentItem = item;

    _fadeGeneration++;
    // 强制重置音量，防止之前的渐隐导致静音
    if (_player.volume < 0.01) await _player.setVolume(1.0);

    // 确保当前项目在队列中。如果队列为空，说明是单独播放。
    if (queue.value.isEmpty) {
      queue.add([_toMediaItem(item)]);
      await _persistQueue();
    }

    // 如果已经在播放该 ID 且不是强制重播，则跳过加载，防止重复启动导致的 Loading interrupted 错误
    final itemMedia = _toMediaItem(item);
    final startPos = Duration(seconds: item.startTime);
    final currentMediaId = mediaItem.hasValue ? mediaItem.value?.id : null;

    // 如果已经在播放该 ID 且不是强制重播，则跳过加载，防止重复启动导致的 Loading interrupted 错误
    if (!forceRestart &&
        currentMediaId == item.id &&
        _player.processingState != ProcessingState.idle) {
      return;
    }

    // 1. 如果是强制重播/切歌，先停掉旧曲目，防止旧进度事件继续产生
    if (forceRestart) {
      await _player.stop();
    }

    // 2. 手动广播一个新的位置状态，确保 UI 在重绘前拿到的进度是正确的
    // 这能解决你发现的“进度条跳动”问题
    if (playbackState.hasValue) {
      playbackState.add(playbackState.value.copyWith(updatePosition: startPos));
    } else {
      // 如果没有初始值，广播一个基本的就绪状态
      playbackState.add(
        PlaybackState(
          controls: [
            MediaControl.skipToPrevious,
            MediaControl.play,
            MediaControl.skipToNext,
            MediaControl.stop,
          ],
          systemActions: const {
            MediaAction.seek,
            MediaAction.skipToNext,
            MediaAction.skipToPrevious,
          },
          playing: false,
          updatePosition: startPos,
          processingState: AudioProcessingState.loading,
        ),
      );
    }

    // 3. 更新 MediaItem 触发 UI 重绘
    mediaItem.add(itemMedia);

    String? source;
    if (item.filePath != null && item.filePath!.isNotEmpty) {
      source = item.filePath;
    } else if (item.id.startsWith('BV')) {
      try {
        final bvid = BilibiliIdUtils.extractBvId(item.id);
        final videoAudioService = BilibiliVideoAudioService();
        String? cid = item.cid;

        if (cid == null) {
          final dio = Dio();
          final response = await dio.get(
            'https://api.bilibili.com/x/web-interface/view',
            queryParameters: {'bvid': bvid},
          );
          if (response.statusCode == 200 && response.data['code'] == 0) {
            cid = response.data['data']['cid']?.toString();
          }
        }

        if (cid != null) {
          final url = await videoAudioService.getVideoAudioUrl(
            bvid,
            int.parse(cid),
          );
          if (url != null) source = url;
        }
      } catch (e) {
        // 忽略错误
      }
    }

    source ??= 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3';

    try {
      final bvid = item.id.startsWith('BV')
          ? BilibiliIdUtils.extractBvId(item.id)
          : item.id;
      final headers = {
        'User-Agent':
            'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Referer': 'https://www.bilibili.com/video/$bvid',
      };
      await _player.setAudioSource(
        AudioSource.uri(Uri.parse(source), headers: headers),
      );

      if (item.startTime > 0) {
        await _player.seek(Duration(seconds: item.startTime));
      }

      if (_fadeOutEnabled) {
        await _player.setVolume(0.0);
        _player.play();
        _fadeVolumeTo(1.0, 2500); // 新歌 2.5 秒淡入
      } else {
        if (_player.volume < 0.01) await _player.setVolume(1.0);
        _player.play();
      }
    } catch (e) {
      // 重新抛出到外层 catch
      rethrow;
    }
  }

  @override
  Future<void> addQueueItem(MediaItem mediaItem) async {
    final list = List<MediaItem>.from(queue.value)..add(mediaItem);
    queue.add(list);
    await _persistQueue();
  }

  @override
  Future<void> addQueueItems(List<MediaItem> mediaItems) async {
    if (mediaItems.isEmpty) return;
    final list = List<MediaItem>.from(queue.value)..addAll(mediaItems);
    queue.add(list);
    await _persistQueue();
  }

  @override
  Future<void> removeQueueItemAt(int index) async {
    if (!queue.hasValue || index < 0 || index >= queue.value.length) return;

    final newQueue = List<MediaItem>.from(queue.value);
    final removedItem = newQueue.removeAt(index);
    queue.add(newQueue);
    await _persistQueue();

    // If we removed the currently playing item, skip to next (or stop if empty)
    final currentId = mediaItem.hasValue ? mediaItem.value?.id : null;
    if (currentId == removedItem.id) {
      if (newQueue.isEmpty) {
        await stop();
      } else {
        // If we removed the last item which was playing, play the new last item or stop?
        // Usually if index is now out of bounds, we play index-1?
        // But simpler: just play the item at the same index (which is the next one)
        if (index >= newQueue.length) {
          await skipToQueueIndex(0); // Loop back or play first? Or stop.
          // Let's just stop for safety if it was the last one.
          if (newQueue.isNotEmpty) {
            await skipToQueueIndex(0);
          } else {
            await stop();
          }
        } else {
          await skipToQueueIndex(index);
        }
      }
    }
  }

  Future<void> updateQueueItem(VideoItem item) async {
    if (!queue.hasValue) return;
    final index = queue.value.indexWhere((m) => m.id == item.id);
    if (index == -1) return;

    final newItem = _toMediaItem(item);
    final newQueue = List<MediaItem>.from(queue.value);
    newQueue[index] = newItem;
    queue.add(newQueue);
    await _persistQueue();

    // If the updated item is currently playing, update mediaItem and _currentItem
    final currentId = mediaItem.hasValue ? mediaItem.value?.id : null;
    if (currentId == item.id) {
      mediaItem.add(newItem);
      _currentItem = item; // Update internal current item for range checks
    }
  }

  Future<void> clearQueue() async {
    queue.add([]);
    await _persistQueue();
    await stop();
  }

  Future<void> _restoreQueueFromPrefs() async {
    final saved = AppPreferences.instance.playbackQueue;
    if (saved.isEmpty) return;

    final restored = <MediaItem>[];
    for (final row in saved) {
      final item = _mediaItemFromMap(row);
      if (item != null) restored.add(item);
    }
    if (restored.isNotEmpty) {
      queue.add(restored);
    }
  }

  Future<void> _persistQueue() async {
    final data = queue.value.map(_mediaItemToMap).toList();
    await AppPreferences.instance.setPlaybackQueue(data);
  }

  Map<String, dynamic> _mediaItemToMap(MediaItem item) {
    return {
      'id': item.id,
      'album': item.album,
      'title': item.title,
      'artist': item.artist,
      'duration': item.duration?.inSeconds,
      'artUri': item.artUri?.toString(),
      'extras': item.extras ?? const <String, dynamic>{},
    };
  }

  MediaItem? _mediaItemFromMap(Map<String, dynamic> row) {
    final id = row['id'];
    final title = row['title'];
    if (id is! String || id.isEmpty || title is! String || title.isEmpty) {
      return null;
    }

    final dynamic extrasRaw = row['extras'];
    final extras = extrasRaw is Map
        ? extrasRaw.map((k, v) => MapEntry(k.toString(), v))
        : <String, dynamic>{};

    final durationSec = row['duration'];
    final artUriRaw = row['artUri'];
    Uri? artUri;
    if (artUriRaw is String && artUriRaw.isNotEmpty) {
      try {
        artUri = Uri.parse(artUriRaw);
      } catch (_) {
        artUri = null;
      }
    }

    return MediaItem(
      id: id,
      album: row['album'] as String?,
      title: title,
      artist: row['artist'] as String?,
      duration: durationSec is int ? Duration(seconds: durationSec) : null,
      artUri: artUri,
      extras: extras,
    );
  }

  PlaybackState _transformEvent(PlaybackEvent event) {
    return PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        if (_player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
        MediaAction.skipToNext,
        MediaAction.skipToPrevious,
        MediaAction.setRepeatMode,
      },
      androidCompactActionIndices: const [0, 1, 2],
      processingState:
          {
            ProcessingState.idle: AudioProcessingState.idle,
            ProcessingState.loading: AudioProcessingState.loading,
            ProcessingState.buffering: AudioProcessingState.buffering,
            ProcessingState.ready: AudioProcessingState.ready,
            ProcessingState.completed: AudioProcessingState.completed,
          }[_player.processingState] ??
          AudioProcessingState.idle,
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: queue.hasValue
          ? queue.value.indexWhere(
              (item) =>
                  item.id == (mediaItem.hasValue ? mediaItem.value?.id : null),
            )
          : -1,
    );
  }
}
