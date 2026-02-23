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
  String? _lastParsedContent; // 记录上一次解析的链接，避免重复弹窗

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
    for (final file in list) {
      if (file.type == SharedMediaType.text ||
          file.type == SharedMediaType.url) {
        final text = file.path;
        _processTextIfMatched(text);
      }
    }
  }

  Future<void> _checkClipboard() async {
    if (!AppPreferences.instance.autoDetectClipboard) return; // 绑定设置项开关

    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      final text = clipboardData?.text;
      if (text != null && text.isNotEmpty) {
        _processTextIfMatched(text);
      }
    } catch (e) {
      debugPrint("读取剪贴板失败: $e");
    }
  }

  void _processTextIfMatched(String text) {
    if (text.isEmpty) return;

    // 简单过滤出 B站 链接特征
    if (text.contains('b23.tv') || text.contains('bilibili.com')) {
      if (_lastParsedContent == text) return; // 避免同一个链接反复拦截
      _lastParsedContent = text; // 记录

      if (mounted) {
        setState(() => _currentIndex = 1); // 切换到底部栏的库标签页
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddAudioScreen(initialUrl: text),
          ),
        );
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
              const LibraryScreen(),
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
