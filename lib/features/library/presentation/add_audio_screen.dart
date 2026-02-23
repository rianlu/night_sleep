import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:night_sleep/core/theme/app_palette.dart';
import 'package:night_sleep/data/datasources/database_helper.dart';
import 'package:night_sleep/data/models/video_item.dart';
import 'package:night_sleep/features/import/data/bilibili_import_service.dart';

class AddAudioScreen extends StatefulWidget {
  final String? initialUrl;

  const AddAudioScreen({super.key, this.initialUrl});

  @override
  State<AddAudioScreen> createState() => _AddAudioScreenState();
}

class _AddAudioScreenState extends State<AddAudioScreen> {
  final TextEditingController _linkController = TextEditingController();
  final BilibiliImportService _service = BilibiliImportService();

  bool _parsing = false;
  bool _saving = false;
  String? _error;
  String? _hint;
  VideoItem? _video;
  RangeValues _range = const RangeValues(0, 1);

  @override
  void initState() {
    super.initState();
    if (widget.initialUrl != null && widget.initialUrl!.isNotEmpty) {
      _linkController.text = widget.initialUrl!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _parse();
      });
    }
    _linkController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _linkController.dispose();
    super.dispose();
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text == null) return;
    _linkController.text = data!.text!.trim();
  }

  Future<void> _parse() async {
    final raw = _linkController.text.trim();
    if (raw.isEmpty) return;

    setState(() {
      _parsing = true;
      _error = null;
      _hint = null;
    });

    try {
      final link = await _service.resolveLink(raw);
      if (link == null) {
        throw '无法识别链接中的 BV 号';
      }
      final video = await _service.fetchVideoInfo(link.bvId, page: link.page);
      if (video == null) {
        throw '解析失败，请稍后重试';
      }

      setState(() {
        _video = video;
        _range = RangeValues(0, video.duration.toDouble());
        _hint = '准备就绪\n点击保存，将音频添加至您的本地库。';
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _parsing = false;
        });
      }
    }
  }

  Future<void> _save() async {
    if (_video == null) return;

    final start = _range.start.round().clamp(0, _video!.duration);
    final end = _range.end.round().clamp(start + 1, _video!.duration);

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final item = VideoItem(
        id: _video!.id,
        title: _video!.title,
        artist: _video!.artist,
        coverUrl: _video!.coverUrl,
        duration: _video!.duration,
        startTime: start,
        endTime: end,
        filePath: _video!.filePath,
        cid: _video!.cid,
        page: _video!.page,
        category: _video!.category ?? '默认',
        addedAt: DateTime.now(),
      );

      await DatabaseHelper.instance.create(item);
      if (!mounted) return;
      setState(() {
        _hint = '保存成功\n音频已成功添加至本地库。';
      });
      Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        _error = '保存失败: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<AppPalette>()!;
    final width = MediaQuery.sizeOf(context).width;
    final compact = width <= 411;
    final hPad = compact ? 20.0 : 24.0;
    final duration = _video?.duration ?? 1;
    final start = _range.start.round();
    final end = _range.end.round();
    final tooLong = _video != null && end > _video!.duration;

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 90, // 控制左侧返回组件的总分配宽度，避免文字被挤压换行
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
            height: 1,
            thickness: 1,
            color: theme.colorScheme.primary.withValues(alpha: 0.15),
          ),
        ),
        leading: Padding(
          padding: const EdgeInsets.only(left: 6), // 缩小左侧留白，让按钮贴近屏幕边缘
          child: InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(24),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start, // 关键：从居中改为靠左对齐
              children: [
                Icon(
                  Icons.chevron_left_rounded,
                  size: 32, // 稍微放大图标，使其与18号文字更均衡
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 2), // 极小间距，让文字紧贴图标
                Text(
                  '返回',
                  style: TextStyle(
                    fontSize: 18,
                    color: theme.colorScheme.primary,
                    height: 1.2, // 微调行高，修正垂直居中对齐感
                  ),
                ),
              ],
            ),
          ),
        ),
        title: Text(
          '解析音频',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 22,
            letterSpacing: -0.5,
            color: palette.titleStrong,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(hPad, compact ? 18 : 22, hPad, 24),
        children: [
          Text(
            '解析链接',
            style: theme.textTheme.titleSmall?.copyWith(
              color: palette.titleSecondary,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: palette.groupBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.4),
                width: 1.5,
              ),
            ),
            child: TextField(
              controller: _linkController,
              minLines: 1,
              maxLines: 2,
              style: TextStyle(fontSize: 16, color: palette.titleStrong),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: '在此粘贴视频链接',
                hintStyle: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.25),
                  fontSize: 16,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                suffixIcon: _linkController.text.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _linkController.clear();
                          setState(() {
                            _error = null;
                            _hint = null;
                            _video = null;
                          });
                        },
                        icon: Icon(
                          Icons.close_rounded,
                          color: theme.colorScheme.primary,
                          size: 24,
                        ),
                      )
                    : IconButton(
                        onPressed: _paste,
                        icon: Icon(
                          Icons.content_paste_outlined,
                          color: theme.colorScheme.primary,
                          size: 24,
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 56,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              onPressed: (_parsing || _linkController.text.trim().isEmpty)
                  ? null
                  : _parse,
              child: _parsing
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: theme.colorScheme.onPrimary,
                      ),
                    )
                  : Text(_video != null ? '重新解析' : '开始解析'),
            ),
          ),
          const SizedBox(height: 22),
          // Placeholder UI when not parsing and no video loaded yet
          if (_video == null && !_parsing && _error == null)
            Padding(
              padding: const EdgeInsets.only(top: 80),
              child: Column(
                children: [
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.link_rounded,
                      size: 64,
                      color: theme.colorScheme.primary.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    '复制 B 站视频链接即可开始解析',
                    style: TextStyle(
                      color: palette.titleMuted,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          if (_video != null) _buildResultCard(theme, _video!),
          if (_video != null) const SizedBox(height: 26),
          if (_video != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '播放区间',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: palette.titleSecondary,
                    fontSize: 12,
                    letterSpacing: 1.5,
                  ),
                ),
                Text(
                  '自定义保存时段',
                  style: TextStyle(color: palette.titleSecondary, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _timeBox(theme, '开始时间', _format(start), false)),
                const SizedBox(width: 12),
                Expanded(child: _timeBox(theme, '结束时间', _format(end), true)),
              ],
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: SliderTheme(
                data: theme.sliderTheme.copyWith(
                  rangeThumbShape: _HollowRangeSliderThumbShape(
                    borderColor: theme.colorScheme.primary,
                  ),
                  activeTrackColor: theme.colorScheme.primary,
                  inactiveTrackColor: theme.colorScheme.primary.withValues(alpha: 0.15),
                  trackHeight: 6,
                  overlayShape: SliderComponentShape.noOverlay,
                ),
                child: Column(
                  children: [
                    RangeSlider(
                      min: 0,
                      max: duration.toDouble(),
                      values: _range,
                      onChanged: (v) {
                        setState(() {
                          _range = v;
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _format(0),
                          style: TextStyle(
                            color: palette.titleSecondary,
                            fontSize: 11,
                            fontFamily: 'monospace',
                          ),
                        ),
                        Text(
                          _format(duration),
                          style: TextStyle(
                            color: palette.titleSecondary,
                            fontSize: 11,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (tooLong)
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: _statusBox(theme, '结束时间不能超过总时长 (${_format(duration)})', isError: true),
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: _statusBox(theme, _error!, isError: true),
            ),
          if (_video != null) ...[
            const SizedBox(height: 20),
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  elevation: 4,
                  shadowColor: theme.colorScheme.primary.withValues(alpha: 0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                child: _saving
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: theme.colorScheme.onPrimary,
                        ),
                      )
                    : const Text('保存到本地库'),
              ),
            ),
            const SizedBox(height: 20),
            if (!tooLong && _error == null && _hint != null)
              _statusBox(theme, _hint!, isError: false),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  Widget _buildResultCard(ThemeData theme, VideoItem item) {
    final palette = theme.extension<AppPalette>()!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.groupBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.primary,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.08),
            blurRadius: 10,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 96,
              height: 96,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: item.coverUrl.isEmpty
                        ? Container(
                            color: palette.cardSubtle,
                            child: Icon(
                              Icons.music_note_rounded,
                              color: theme.colorScheme.primary,
                            ),
                          )
                        : Image.network(item.coverUrl, fit: BoxFit.cover),
                  ),
                  Positioned(
                    right: 6,
                    bottom: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: palette.modalBarrier,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _format(item.duration),
                        style: TextStyle(
                          color: theme.scaffoldBackgroundColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: palette.titleStrong,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.person_rounded,
                      size: 14,
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.72,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        item.artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.72,
                          ),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_rounded,
                        size: 14,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '解析成功',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _timeBox(ThemeData theme, String label, String value, bool highlight) {
    final palette = theme.extension<AppPalette>()!;
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: palette.titleSecondary,
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: palette.groupBg,
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.3),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              value,
              style: TextStyle(
                color: highlight
                    ? theme.colorScheme.primary
                    : palette.titleStrong,
                fontWeight: highlight ? FontWeight.bold : FontWeight.w600,
                fontSize: 18,
                fontFamily: 'monospace',
                letterSpacing: 1,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _statusBox(ThemeData theme, String text, {required bool isError}) {
    final palette = theme.extension<AppPalette>()!;
    final bg = isError ? palette.warningBg : theme.colorScheme.primary.withValues(alpha: 0.08);
    final fg = isError ? palette.warningFg : theme.colorScheme.primary;
    final borderColor = isError
        ? palette.warningBorder.withValues(alpha: 0.5)
        : theme.colorScheme.primary.withValues(alpha: 0.15);
    
    final parts = text.split('\n');
    final title = parts.first;
    final subtitle = parts.length > 1 ? parts.last : null;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 20,
        vertical: subtitle != null ? 16 : 14,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor,
        ),
      ),
      child: Row(
        crossAxisAlignment: subtitle != null
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          Padding(
            padding: EdgeInsets.only(top: subtitle != null ? 2 : 0),
            child: Icon(
              isError
                  ? Icons.warning_rounded
                  : Icons.check_circle_rounded,
              color: fg,
              size: subtitle != null ? 24 : 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: fg,
                    fontWeight: subtitle != null ? FontWeight.bold : FontWeight.w600,
                    fontSize: subtitle != null ? 16 : 14,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: fg.withValues(alpha: 0.8),
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _format(int sec) {
    final safe = sec < 0 ? 0 : sec;
    final h = safe ~/ 3600;
    final m = (safe % 3600) ~/ 60;
    final s = safe % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

class _HollowRangeSliderThumbShape extends RangeSliderThumbShape {
  final double radius;
  final Color borderColor;
  final double borderWidth;

  const _HollowRangeSliderThumbShape({
    this.radius = 12.0,
    required this.borderColor,
    this.borderWidth = 3.0,
  });

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => Size.fromRadius(radius);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    bool isDiscrete = false,
    bool isEnabled = false,
    bool? isOnTop,
    TextDirection? textDirection,
    required SliderThemeData sliderTheme,
    Thumb? thumb,
    bool? isPressed,
  }) {
    final canvas = context.canvas;
    
    // Draw white background 
    final bgPaint = Paint()..color = sliderTheme.thumbColor ?? borderColor..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, bgPaint);
    
    // Draw border
    final borderPaint = Paint()
      ..color = borderColor
      ..strokeWidth = borderWidth
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius, borderPaint);
  }
}
