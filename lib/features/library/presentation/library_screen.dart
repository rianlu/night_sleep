import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:night_sleep/data/datasources/database_helper.dart';
import 'package:night_sleep/data/models/video_item.dart';
import 'package:night_sleep/core/theme/app_palette.dart';
import 'package:night_sleep/core/utils/bilibili_id_utils.dart';
import 'package:night_sleep/features/library/presentation/add_audio_screen.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _loading = true;
  List<VideoItem> _videos = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
    _loadVideos();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadVideos() async {
    List<VideoItem> videos = [];
    try {
      videos = await DatabaseHelper.instance.readAllVideos();
    } catch (_) {
      // In tests or unsupported environments, keep list empty.
    }

    if (!mounted) return;
    setState(() {
      _videos = videos;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<AppPalette>()!;
    final width = MediaQuery.sizeOf(context).width;
    final compact = width <= 411;
    final hPad = compact ? 20.0 : 24.0;
    final coverSize = compact ? 64.0 : 68.0;
    final keyword = _searchController.text.trim().toLowerCase();
    final filtered = keyword.isEmpty
        ? _videos
        : _videos
              .where(
                (v) =>
                    v.title.toLowerCase().contains(keyword) ||
                    v.artist.toLowerCase().contains(keyword) ||
                    v.id.toLowerCase().contains(keyword),
              )
              .toList();

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(hPad, compact ? 18 : 22, hPad, 124),
          children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '本地库',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                            letterSpacing: -0.5,
                            color: palette.titleStrong,
                          ),
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () async {
                      final result = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AddAudioScreen(),
                        ),
                      );
                      if (result == true) {
                        _loadVideos();
                      }
                    },
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.2,
                            ),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.add_rounded,
                        size: 28,
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              TextField(
                controller: _searchController,
                style: TextStyle(fontSize: 16, color: palette.titleStrong),
                decoration: InputDecoration(
                  hintText: '搜索 BV、标题或 UP...',
                  hintStyle: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
                    fontSize: 15,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: palette.titleSecondary,
                    size: 22,
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surface,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: theme.colorScheme.secondary),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: theme.colorScheme.primary),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (_loading)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: CircularProgressIndicator(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                )
              else if (filtered.isEmpty)
                _buildEmpty(theme)
              else
                ...filtered.map((video) => _buildItem(theme, video, coverSize)),
            ],
          ),
        ),
    );
  }

  Widget _buildEmpty(ThemeData theme) {
    final palette = theme.extension<AppPalette>()!;
    if (_videos.isNotEmpty) {
      // 当前是由于搜索过滤导致的空列表
      return Padding(
        padding: const EdgeInsets.only(top: 80),
        child: Column(
          children: [
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: palette.cardSubtle,
                shape: BoxShape.circle,
              ),
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  // 左上角的两个小光斑点缀
                  Positioned(
                    top: 20,
                    left: 10,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: palette.queueActiveBorder,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: palette.queueActiveBorder.withValues(alpha: 0.8),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 40,
                    right: 15,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: palette.queueActiveBorder,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  
                  // 中央的展开的书本大图 (使用 Icon 变体拼凑)
                  Icon(
                    Icons.menu_book_rounded,
                    size: 84,
                    color: palette.queueActiveBorder,
                  ),
                  
                  // 右下角带叉号的搜索圆圈
                  Positioned(
                    bottom: 30,
                    right: 48,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: palette.cardSubtle,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: palette.queueActiveBorder,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.search_off_rounded,
                          color: theme.colorScheme.primary,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text(
              '未找到相关结果',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: palette.titleStrong,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '换个关键词试试，或者去解析新的链接',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: palette.titleMuted,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 32),
            // 清空搜索按钮
            InkWell(
              onTap: () {
                _searchController.clear();
                // 确保键盘收起
                FocusScope.of(context).unfocus();
              },
              borderRadius: BorderRadius.circular(999),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: palette.queueActiveBorder),
                ),
                child: Text(
                  '清空搜索',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // 真正的全空状态
    return Padding(
      padding: const EdgeInsets.only(top: 80),
      child: Column(
        children: [
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: palette.cardSubtle,
              shape: BoxShape.circle,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 底部的方框占位 (专辑外壳透视)
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    border: Border.all(
                      color: palette.queueActiveBorder,
                      width: 8,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                // 中央大胶片圆盘
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: palette.cardElevated,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
                // 右上角叠加的半透明音符图标
                Positioned(
                  top: 52,
                  right: 46,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(alpha: 0.2),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.music_note_rounded,
                      color: theme.colorScheme.onPrimary,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Text(
            '库中空空如也',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: palette.titleStrong,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '复制 B 站视频链接，添加你的第一首助眠音频吧',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: palette.titleMuted,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(ThemeData theme, VideoItem video, double coverSize) {
    final historyText = '从未播放';
    final palette = theme.extension<AppPalette>()!;
    final historyColor = palette.titleSecondary;

    return StreamBuilder<List<MediaItem>>(
      stream: context.read<AudioHandler>().queue,
      builder: (context, snapshot) {
        final queue = snapshot.data ?? [];
        final isInQueue = queue.any((m) => m.id == video.id);

        return GestureDetector(
          onLongPress: () => _showOptions(theme, video),
          behavior: HitTestBehavior.opaque,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: palette.cardSubtle),
              boxShadow: [
                BoxShadow(
                  color: palette.groupShadow,
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
          child: Row(
            children: [
              _cover(
                theme,
                video.coverUrl,
                video.endTime - video.startTime,
                coverSize,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      video.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'UP 主: ${video.artist} • ${video.page == null ? '1 个分段' : 'P${video.page}'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.72,
                        ),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 12,
                          color: historyColor,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            historyText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: historyColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (isInQueue)
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    color: theme.colorScheme.primary,
                    size: 22,
                  ),
                )
              else
                InkWell(
                  onTap: () => _addToQueue(video),
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.add_rounded,
                      color: theme.colorScheme.primary,
                      size: 24,
                    ),
                  ),
                ),
            ],
          ),
        ));
      },
    );
  }

  Future<void> _addToQueue(VideoItem item) async {
    final handler = context.read<AudioHandler>();

    // Check duplication again
    final currentQueue = handler.queue.value;
    if (currentQueue.any((m) => m.id == item.id)) {
      return;
    }

    final mediaItem = MediaItem(
      id: item.id,
      album: 'NightSleep',
      title: item.title,
      artist: item.artist,
      duration: Duration(seconds: item.duration),
      artUri: Uri.tryParse(item.coverUrl),
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

    await handler.addQueueItem(mediaItem);

    if (!mounted) return;
    
    final theme = Theme.of(context);
    final palette = theme.extension<AppPalette>()!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        elevation: 0, // 移除系统默认深黑阴影
        backgroundColor: theme.colorScheme.surface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20), // 加大圆角更现代
          side: BorderSide(
            color: theme.colorScheme.primary.withValues(alpha: 0.15),
            width: 1.5,
          ),
        ),
        margin: const EdgeInsets.only(bottom: 24, left: 24, right: 24),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_rounded, color: theme.colorScheme.primary, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '已加入队列: ${item.title}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: palette.titleStrong, // 标题回归深色
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(milliseconds: 1200),
      ),
    );
  }

  void _showOptions(ThemeData theme, VideoItem video) {
    final palette = theme.extension<AppPalette>()!;

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.scaffoldBackgroundColor, // #FFFBF2 奶糖背景
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 拖拽手柄
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: palette.panelDivider,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 24),
                // 头部：控制柄 + 音频信息
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 封面
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        width: 60,
                        height: 60,
                        child: _cover(theme, video.coverUrl, video.duration, 60, showDuration: false),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // 文本
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            video.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: palette.titleStrong,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            video.artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Divider(
                  height: 1,
                  thickness: 1, // 增加1个像素的高度强调分割线
                  color: palette.panelDivider.withValues(alpha: 0.3), // 变得更加轻微的分割线
                ),
                const SizedBox(height: 24),
                // 查看来源按钮
                InkWell(
                  onTap: () async {
                    Navigator.pop(context); // 单击后立即关闭弹窗
                    try {
                      final bvid = BilibiliIdUtils.extractBvId(video.id);
                      final page = BilibiliIdUtils.extractPageFromItemId(video.id);
                      final pageStr = page != null ? '?p=$page' : '';

                      // 尝试使用 bilibili:// esquema 协议唤起 App 直接到达播放页
                      final appUrlStr = 'bilibili://video/$bvid$pageStr';
                      final appUri = Uri.parse(appUrlStr);
                      // url_launcher 会在找不到App或系统拒绝拉起时返回 false，如果不使用 catch 而是捕获结果：
                      final launched = await launchUrl(appUri);
                      
                      if (!launched) {
                        // 如果无法唤起 app，尝试唤起外部浏览器中的网页
                        final webUrl = Uri.parse('https://www.bilibili.com/video/$bvid$pageStr');
                        if (await canLaunchUrl(webUrl)) {
                          await launchUrl(webUrl, mode: LaunchMode.externalApplication);
                        }
                      }
                    } catch (e) {
                      try {
                        final bvid = BilibiliIdUtils.extractBvId(video.id);
                        final page = BilibiliIdUtils.extractPageFromItemId(video.id);
                        final pageStr = page != null ? '?p=$page' : '';
                        final webUrl = Uri.parse('https://www.bilibili.com/video/$bvid$pageStr');
                        if (await canLaunchUrl(webUrl)) {
                          await launchUrl(webUrl, mode: LaunchMode.externalApplication);
                        }
                      } catch (_) {
                         debugPrint('Error launching url: $e');
                      }
                    }
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.open_in_new_rounded, color: theme.colorScheme.primary, size: 22),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          '查看视频来源',
                          style: TextStyle(
                            color: palette.titleStrong,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // 删除按钮
                InkWell(
                  onTap: () async {
                    Navigator.pop(context); // 单击后立即关闭弹窗
                    await _deleteVideo(video, palette);
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.error.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.delete_outline_rounded, color: theme.colorScheme.error, size: 22),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          '删除此音频',
                          style: TextStyle(
                            color: theme.colorScheme.error, // 使用字体的错误红
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
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

  Future<void> _deleteVideo(VideoItem video, AppPalette palette) async {
    try {
      await DatabaseHelper.instance.delete(video.id);
      _loadVideos(); // 刷新列表
      
      if (!mounted) return; // 提前判断，修复跨异步使用 context 的警告

      // 同步处理播放队列：如果被删除的音频在当前待播放列表中，则将其移出队列
      final handler = context.read<AudioHandler>();
      final queue = handler.queue.value;
      final qIndex = queue.indexWhere((m) => m.id == video.id);
      if (qIndex != -1) {
        handler.removeQueueItemAt(qIndex);
      }
      
      final theme = Theme.of(context);
      final palette = theme.extension<AppPalette>()!;
      final deletedVideo = video;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          elevation: 0, // 移除系统默认深黑阴影
          backgroundColor: theme.colorScheme.surface,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20), // 加大圆角更现代
            side: BorderSide(
              color: theme.colorScheme.primary.withValues(alpha: 0.15),
              width: 1.5,
            ),
          ),
          margin: const EdgeInsets.only(bottom: 24, left: 24, right: 24),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          content: Row(
              children: [
                // 浅绿色对勾图标
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.check_rounded, color: theme.colorScheme.primary, size: 20),
                ),
                const SizedBox(width: 16),
                // 文本
                Expanded(
                  child: Text(
                    '音频已成功删除',
                    style: TextStyle(
                      color: palette.titleStrong, // 极深的文字颜色
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
                // 撤销按钮
                InkWell(
                  onTap: () async {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    await DatabaseHelper.instance.create(deletedVideo); // 恢复该数据
                    _loadVideos(); // 刷新列表
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    child: Text(
                      '撤销',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 4), // 加长停留以便用户撤销
          ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: palette.warningBg,
          content: Text('删除失败: $e', style: TextStyle(color: palette.warningFg)),
        ),
      );
    }
  }

  Widget _cover(ThemeData theme, String? url, int durationSec, double size, {bool showDuration = true}) {
    final palette = theme.extension<AppPalette>()!;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: size,
        height: size,
        color: palette.cardSubtle,
        child: Stack(
          children: [
            Positioned.fill(
              child: (url == null || url.isEmpty)
                  ? Icon(
                      Icons.music_note_rounded,
                      color: theme.colorScheme.primary,
                    )
                  : Image.network(
                      url,
                      fit: BoxFit.cover,
                      errorBuilder: (_, error, stackTrace) => Icon(
                        Icons.music_note_rounded,
                        color: theme.colorScheme.primary,
                      ),
                    ),
            ),
            if (showDuration)
              Positioned(
                right: 4,
                bottom: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: palette.modalBarrier,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _formatDuration(durationSec),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: theme.colorScheme.surface,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(int sec) {
    final safe = sec < 0 ? 0 : sec;
    final h = safe ~/ 3600;
    final m = (safe % 3600) ~/ 60;
    final s = safe % 60;
    if (h > 0) {
      return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}
