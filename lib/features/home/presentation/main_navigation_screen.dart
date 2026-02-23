import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:night_sleep/core/utils/app_preferences.dart';
import 'package:night_sleep/features/home/presentation/home_play_screen.dart';
import 'package:night_sleep/features/home/presentation/widgets/stitch_bottom_nav_bar.dart';
import 'package:night_sleep/features/library/presentation/library_screen.dart';
import 'package:night_sleep/features/library/presentation/add_audio_screen.dart';
import 'package:night_sleep/features/profile/presentation/profile_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen>
    with WidgetsBindingObserver {
  int _currentIndex = 0;
  StreamSubscription? _intentStreamSubscription;
  bool _isHandlingShareIntent = false; // 增加标志位，避免分享意图与剪贴板检测冲突
  String? _lastParsedShareIntent; // 单独跟踪分享意图的最后解析内容，避免库重复发送

  static final GlobalKey<LibraryScreenState> libraryKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // 监听应用在后台时进入的分享意图
    _intentStreamSubscription = ReceiveSharingIntent.instance
        .getMediaStream()
        .listen(
          (List<SharedMediaFile> value) {
            _handleSharedIntent(value);
          },
          onError: (err) {
            debugPrint("getIntentDataStream error: $err");
          },
        );

    // 获取应用从关闭状态被分享意图启动时的初始信息
    ReceiveSharingIntent.instance.getInitialMedia().then((
      List<SharedMediaFile> value,
    ) {
      _handleSharedIntent(value);
      ReceiveSharingIntent.instance.reset(); // 处理后清理初始状态
    });

    // 初始启动时检查一次剪贴板
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkClipboard();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkClipboard();
    }
  }

  void _handleSharedIntent(List<SharedMediaFile> list) {
    if (list.isEmpty) return;
    _isHandlingShareIntent = true;
    for (final file in list) {
      if (file.type == SharedMediaType.text ||
          file.type == SharedMediaType.url) {
        final text = file.path;
        _processTextIfMatched(text, isFromClipboard: false);
      }
    }
    // 在短暂延迟后释放阻塞，给 AppLifecycle 足够的缓冲时间，避免重复执行逻辑
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _isHandlingShareIntent = false;
    });
  }

  Future<void> _checkClipboard() async {
    if (!AppPreferences.instance.autoDetectClipboard) return; // 绑定设置项开关

    // 优先处理分享意图，而非剪贴板（因为 resumed 事件会立即触发）
    await Future.delayed(const Duration(milliseconds: 200));
    if (_isHandlingShareIntent || !mounted) return;

    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      final text = clipboardData?.text;
      if (text != null && text.isNotEmpty) {
        _processTextIfMatched(text, isFromClipboard: true);
      }
    } catch (e) {
      debugPrint("读取剪贴板失败: $e");
    }
  }

  void _processTextIfMatched(String text, {required bool isFromClipboard}) {
    if (text.isEmpty) return;

    // 简单过滤出 B站 链接特征
    if (text.contains('b23.tv') || text.contains('bilibili.com')) {
      if (isFromClipboard) {
        final lastParsed = AppPreferences.instance.lastParsedClipboardText;
        if (lastParsed == text) return; // 避免同一个剪贴板链接反复拦截

        AppPreferences.instance.setLastParsedClipboardText(text); // 持久化记录剪贴板内容
      } else {
        if (_lastParsedShareIntent == text) return; // 避免意图重复到达
        _lastParsedShareIntent = text;
      }

      if (mounted) {
        setState(() => _currentIndex = 1); // 切换到底部栏的库标签页
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddAudioScreen(initialUrl: text),
          ),
        ).then((result) {
          if (result == true && libraryKey.currentState != null) {
            libraryKey.currentState!.loadVideos();
          }
        });
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _intentStreamSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: [
              HomePlayScreen(
                onNavigateToLibrary: () => setState(() => _currentIndex = 1),
              ),
              LibraryScreen(key: libraryKey),
              const ProfileScreen(),
            ],
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: StitchBottomNavBar(
              currentIndex: _currentIndex,
              onTap: (index) => setState(() => _currentIndex = index),
            ),
          ),
        ],
      ),
    );
  }
}
