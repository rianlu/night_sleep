import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:dio/dio.dart';
import 'package:just_audio/just_audio.dart';
import 'package:night_sleep/data/models/video_item.dart';
import 'package:night_sleep/features/import/data/bilibili_video_audio_service.dart';

class AudioPlayerHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
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
    _player.playbackEventStream.map(_transformEvent).pipe(playbackState);
    _player.positionStream.listen(_checkPlaybackRange);
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        if (_stopAtEndOfTrack) {
          _stopAtEndOfTrack = false; // 重置标志
          stop();
        } else {
          skipToNext();
        }
      }
    });
  }

  Stream<AudioServiceRepeatMode> get repeatModeStream => _player.loopModeStream.map((loopMode) {
    switch (loopMode) {
      case LoopMode.off: return AudioServiceRepeatMode.none;
      case LoopMode.one: return AudioServiceRepeatMode.one;
      case LoopMode.all: return AudioServiceRepeatMode.all;
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

  void _checkPlaybackRange(Duration position) {
    if (_currentItem != null) {
      final startTime = _currentItem!.startTime;
      final endTime = _currentItem!.endTime;
      if (!_player.playing) return;
      if (endTime > startTime && endTime < _currentItem!.duration) {
        final end = Duration(seconds: endTime);
        if (position >= end) {
          if (queue.value.length <= 1) {
            stop();
          } else {
            skipToNext();
          }
        }
      }
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

  void setSleepTimerAtEnd(bool enable) {
    _stopAtEndOfTrack = enable;
  }

  void setFadeOutEnabled(bool enable) {
    _fadeOutEnabled = enable;
  }

  Future<void> _fadeOutAndStop() async {
    if (!_fadeOutEnabled) {
      await stop();
      return;
    }
    const steps = 30; // 3秒内降低音量
    const interval = Duration(milliseconds: 100);
    double initialVolume = _player.volume;
    for (int i = 1; i <= steps; i++) {
      await Future.delayed(interval);
      double newVolume = initialVolume * (1.0 - (i / steps));
      await _player.setVolume(newVolume);
    }
    await stop();
    await _player.setVolume(initialVolume); // 重置音量以便下次播放
  }

  void cancelSleepTimer() {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    _stopAtEndOfTrack = false;
    _sleepTimerDuration = null;
    _sleepTimerEnd = null;
  }

  Duration? get sleepTimerDuration => _sleepTimerDuration;
  DateTime? get sleepTimerEnd => _sleepTimerEnd;

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() async {
    _sleepTimer?.cancel();
    await _player.stop();
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() async {
    if (_player.loopMode == LoopMode.one) {
      // 如果是单曲循环模式，"下一首"通常强制切歌或重播，取决于产品逻辑。
      // 标准行为：Next 按钮在 LoopOne 下也会强制切换到下一首。
    }
    
    if (queue.value.isEmpty) return;
    
    int currentIndex = queue.value.indexWhere((item) => item.id == mediaItem.value?.id);
    if (currentIndex == -1) {
      await _playMediaItem(queue.value.first, forceRestart: true);
      return;
    }

    int nextIndex;
    if (_player.shuffleModeEnabled) {
      // 随机模式逻辑（MVP 阶段暂使用简单索引加一）
       nextIndex = currentIndex + 1;
    } else {
       nextIndex = currentIndex + 1;
    }

    if (nextIndex >= queue.value.length) {
      if (_player.loopMode == LoopMode.all) {
        nextIndex = 0;
      } else {
        return; // 队列结束
      }
    }

    final nextMediaItem = queue.value[nextIndex];
    // 需要 VideoItem 详细属性来播放，但队列只持有 MediaItem。
    // 需要从数据库重新读取或使用 extras 恢复。
    // 优化：AudioPlayerHandler 应该持有一个 List<VideoItem> 或者从缓存读取。
    // 目前使用 extras 来保持一致性并减少数据库库依赖。
    
    await _playMediaItem(nextMediaItem, forceRestart: true);
  }

  @override
  Future<void> skipToPrevious() async {
    if (queue.value.isEmpty) return;
    int currentIndex = queue.value.indexWhere((item) => item.id == mediaItem.value?.id);
    if (currentIndex == -1) return;

    if (_player.position.inSeconds > 3) {
      seek(Duration.zero);
      return;
    }

    int prevIndex = currentIndex - 1;
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
     playbackState.add(playbackState.value); 
  }

  Future<void> _playMediaItem(MediaItem item, {bool forceRestart = false}) async {
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
  }

  // 加载完整播放队列并播放指定索引
  Future<void> loadPlaylist(List<VideoItem> videos, int index) async {
    final mediaItems = videos.map((v) => _toMediaItem(v)).toList();
    queue.add(mediaItems);
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
        'category': item.category,
      }
    );
  }

  
  Future<void> playVideoItem(VideoItem item, {bool forceRestart = false}) async {
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

  Future<void> _playVideoItemInternal(VideoItem item, {bool forceRestart = false}) async {
    _currentItem = item;
    
    // 确保当前项目在队列中。如果队列为空，说明是单独播放。
    if (queue.value.isEmpty) {
        queue.add([_toMediaItem(item)]);
    }

    // 如果已经在播放该 ID 且不是强制重播，则跳过加载，防止重复启动导致的 Loading interrupted 错误
    if (!forceRestart && mediaItem.value?.id == item.id && _player.processingState != ProcessingState.idle) {
      return;
    }

    String? source;
    if (item.filePath != null && item.filePath!.isNotEmpty) {
      source = item.filePath;
    } else if (item.id.startsWith('BV')) {
      try {
        final videoAudioService = BilibiliVideoAudioService();
        String? cid = item.cid;
        
        if (cid == null) {
          final dio = Dio();
          final response = await dio.get('https://api.bilibili.com/x/web-interface/view', queryParameters: {'bvid': item.id});
          if (response.statusCode == 200 && response.data['code'] == 0) {
            cid = response.data['data']['cid']?.toString();
          }
        }

        if (cid != null) {
          final url = await videoAudioService.getVideoAudioUrl(item.id, int.parse(cid));
          if (url != null) source = url;
        }
      } catch (e) {
        // 忽略错误
      }
    }

    source ??= 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3'; 
    
    final itemMedia = _toMediaItem(item);
    mediaItem.add(itemMedia);

    try {
      if (forceRestart) {
        await _player.stop();
      }
      final headers = {
        'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Referer': 'https://www.bilibili.com/video/${item.id}',
      };
      await _player.setAudioSource(AudioSource.uri(Uri.parse(source), headers: headers));
      
      if (item.startTime > 0) {
        await _player.seek(Duration(seconds: item.startTime));
      }
      
      _player.play();
    } catch (e) {
       // 重新抛出到外层 catch
       rethrow;
    }
  }


  @override
  Future<void> removeQueueItemAt(int index) async {
    if (index < 0 || index >= queue.value.length) return;
    
    final newQueue = List<MediaItem>.from(queue.value);
    final removedItem = newQueue.removeAt(index);
    queue.add(newQueue);

    // If we removed the currently playing item, skip to next (or stop if empty)
    if (mediaItem.value?.id == removedItem.id) {
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

  Future<void> clearQueue() async {
    queue.add([]);
    await stop();
  }

  PlaybackState _transformEvent(PlaybackEvent event) {
    return PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        if (_player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.skipToNext,
        MediaControl.stop,
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
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState]!,
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: queue.value.indexWhere((item) => item.id == mediaItem.value?.id),
    );
  }
}
