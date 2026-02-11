import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:just_audio/just_audio.dart';
import 'package:night_sleep/core/theme/promax_colors.dart';
import 'package:night_sleep/data/datasources/database_helper.dart';
import 'package:night_sleep/data/models/category_item.dart';
import 'package:night_sleep/data/models/video_item.dart';
import 'package:night_sleep/features/import/data/bilibili_video_audio_service.dart';
import 'package:night_sleep/features/import/presentation/category_management_screen.dart';

class AudioParserScreen extends StatefulWidget {
  final VideoItem video;
  final bool isEditing;
  const AudioParserScreen({super.key, required this.video, this.isEditing = false});

  @override
  State<AudioParserScreen> createState() => _AudioParserScreenState();
}

class _AudioParserScreenState extends State<AudioParserScreen> {
  late RangeValues _range;
  String? _selectedCategory = "默认";
  List<CategoryItem> _categories = [];
  bool _isCategoriesLoading = true;
  bool _isSaving = false;
  bool _showSuccess = false;
  bool _isPreviewing = false;
  Timer? _previewTimer;
  late final AudioPlayer _previewPlayer;

  DateTime? _lastFeedbackTime;

  @override
  void initState() {
    super.initState();
    _previewPlayer = AudioPlayer();
    _range = RangeValues(
      widget.video.startTime.toDouble(),
      widget.video.endTime.toDouble(),
    );
    _loadCategories();
  }

  @override
  void dispose() {
    _previewTimer?.cancel();
    _previewPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    final categories = await DatabaseHelper.instance.readAllCategories();
    if (mounted) {
      setState(() {
        _categories = categories;
        _isCategoriesLoading = false;
        if (_categories.isNotEmpty && (_selectedCategory == null || !_categories.any((c) => c.name == _selectedCategory))) {
          _selectedCategory = _categories.first.name;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final isCompact = height < 760;
    final confirmSize = 80.0;
    final confirmBottom = isCompact ? 20.0 : 32.0;
    final confirmSpacer = confirmSize + confirmBottom + (isCompact ? 12.0 : 16.0);

    return Scaffold(
      backgroundColor: ProMaxColors.stitchCozyBg,
      body: Stack(
        children: [
          // Main Content
          Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: _buildFluidArea(isCompact: isCompact),
              ),
              _buildControlPanel(isCompact: isCompact, confirmSpacer: confirmSpacer),
            ],
          ),

          // Action Button
          if (!_showSuccess)
            Positioned(
              bottom: confirmBottom,
              left: 0,
              right: 0,
              child: Center(
                child: _buildConfirmButton(),
              ),
            ),

          // Success Overlay
          if (_showSuccess) _buildSuccessOverlay(),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 28),
              onPressed: () => Navigator.pop(context),
            ),
            const Text(
              "音频解析",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _range = RangeValues(0, widget.video.duration.toDouble());
                });
              },
              child: const Text(
                "重置",
                style: TextStyle(color: ProMaxColors.stitchCozyTextMuted, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFluidArea({required bool isCompact}) {
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: isCompact ? 16 : 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FluidRippleAnimation(
                coverUrl: widget.video.coverUrl,
                size: isCompact ? 280 : 340, // Increased from 220/260
                coverSize: isCompact ? 200 : 250, // Increased from 164/192
                badgePadding: isCompact ? 8 : 10,
                badgeIconSize: isCompact ? 20 : 24,
              ),
              SizedBox(height: isCompact ? 24 : 40), // Increased spacing slightly for better separation
              _buildTimeDisplay(isCompact: isCompact),
              SizedBox(height: isCompact ? 8 : 12),
              const Text(
                "拖动滑块截取片段",
                style: TextStyle(
                  color: ProMaxColors.stitchCozyTextMuted,
                  fontSize: 14, // Slightly larger
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeDisplay({required bool isCompact}) {
    final timeFont = isCompact ? 40.0 : 48.0; // Increased from 34/42
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _formatDuration(Duration(seconds: _range.start.toInt())),
          style: TextStyle(color: Colors.white, fontSize: timeFont, fontWeight: FontWeight.bold, letterSpacing: -1),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: isCompact ? 8 : 12),
          child: Text("-", style: TextStyle(color: Colors.white24, fontSize: isCompact ? 26 : 32, fontWeight: FontWeight.w300)),
        ),
        Text(
          _formatDuration(Duration(seconds: _range.end.toInt())),
          style: TextStyle(color: ProMaxColors.stitchCozyAccent, fontSize: timeFont, fontWeight: FontWeight.bold, letterSpacing: -1),
        ),
      ],
    );
  }

  Widget _buildControlPanel({required bool isCompact, required double confirmSpacer}) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: isCompact ? 8 : 16), // Reduced vertical padding
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildCategorySelection(isCompact: isCompact),
          SizedBox(height: isCompact ? 12 : 20), // Reduced spacing
          _buildRangeSliderArea(),
          SizedBox(height: isCompact ? 16 : 24), // Reduced spacing
          _buildPreviewButton(),
          SizedBox(height: confirmSpacer), 
        ],
      ),
    );
  }

  Widget _buildCategorySelection({required bool isCompact}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: isCompact ? 2 : 4), // Reduced padding
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("选择分类", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13)), // Slightly smaller label
              Text("滑动查看", style: TextStyle(color: ProMaxColors.stitchCozyAccent.withValues(alpha: 0.6), fontSize: 11)),
            ],
          ),
        ),
        SizedBox(
          height: isCompact ? 68 : 80, // Reduced height for list
          child: _isCategoriesLoading
            ? const Center(child: CircularProgressIndicator(color: ProMaxColors.stitchCozyAccent))
            : ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length + 1,
                separatorBuilder: (context, index) => const SizedBox(width: 10), // Tighter spacing
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _buildAddCategoryButton(isCompact: isCompact);
                  }
                  final cat = _categories[index - 1].name;
                  final isSelected = _selectedCategory == cat;
                  return _buildCategoryItem(cat, isSelected, isCompact: isCompact);
                },
              ),
        ),
      ],
    );
  }

  Widget _buildAddCategoryButton({required bool isCompact}) {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CategoryManagementScreen()),
        );
        _loadCategories();
      },
      child: Container(
        width: 44, // Smaller button
        height: 44,
        margin: EdgeInsets.symmetric(vertical: isCompact ? 10 : 16), // Reduced margin
        decoration: BoxDecoration(
          color: ProMaxColors.stitchCozyAccent.withValues(alpha: 0.1),
          shape: BoxShape.circle,
          border: Border.all(color: ProMaxColors.stitchCozyAccent.withValues(alpha: 0.5)),
        ),
        child: const Icon(Icons.add_rounded, color: ProMaxColors.stitchCozyAccent, size: 22),
      ),
    );
  }

  Widget _buildCategoryItem(String name, bool isSelected, {required bool isCompact}) {
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = name),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10), // Tighter padding
        margin: EdgeInsets.symmetric(vertical: isCompact ? 10 : 16), // Reduced margin
        decoration: BoxDecoration(
          color: isSelected 
              ? ProMaxColors.stitchCozyAccent.withValues(alpha: 0.1) 
              : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(24),
          border: isSelected 
              ? Border.all(color: ProMaxColors.stitchCozyAccent) 
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          name,
          style: TextStyle(
            color: isSelected ? ProMaxColors.stitchCozyAccent : Colors.white60,
            fontWeight: isSelected ? FontWeight.w900 : FontWeight.normal,
            fontSize: 13, // Slightly smaller text
          ),
        ),
      ),
    );
  }

  Widget _buildRangeSliderArea() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
               Text("START", style: TextStyle(color: ProMaxColors.stitchCozyTextMuted, fontSize: 10, fontFamily: "monospace")),
               Text("END", style: TextStyle(color: ProMaxColors.stitchCozyTextMuted, fontSize: 10, fontFamily: "monospace")),
            ],
          ),
          const SizedBox(height: 8),
          _WaveformRangeSlider(
            values: _range,
            max: widget.video.duration.toDouble(),
            onChanged: (val) {
               final now = DateTime.now();
               if (_lastFeedbackTime == null || now.difference(_lastFeedbackTime!) > const Duration(milliseconds: 40)) {
                 HapticFeedback.selectionClick();
                 SystemSound.play(SystemSoundType.click);
                 _lastFeedbackTime = now;
               }
               setState(() => _range = val);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewButton() {
    return GestureDetector(
      onTap: _togglePreview,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF3E3228), // Brownish dark from design
          borderRadius: BorderRadius.circular(32),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isPreviewing ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded,
              color: ProMaxColors.stitchCozyAccent,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(_isPreviewing ? "暂停试听" : "试听片段", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmButton() {
    return GestureDetector(
      onTap: _isSaving ? null : () async {
        setState(() => _isSaving = true);
        try {
          final newVideo = widget.video.copyWith(
            startTime: _range.start.toInt(),
            endTime: _range.end.toInt(),
            category: _selectedCategory,
          );
          if (widget.isEditing) {
            final updated = await DatabaseHelper.instance.update(newVideo);
            if (updated == 0) {
              await DatabaseHelper.instance.create(newVideo);
            }
          } else {
            await DatabaseHelper.instance.create(newVideo);
          }
          
          if (mounted) {
            setState(() {
              _isSaving = false;
              _showSuccess = true;
            });
            
            Future.delayed(1500.ms, () {
              if (mounted) {
                Navigator.pop(context, true);
              }
            });
          }
        } catch (e) {
          if (mounted) {
            setState(() => _isSaving = false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("保存失败，请重试")),
            );
          }
        }
      },
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: ProMaxColors.stitchCozyAccent,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: ProMaxColors.stitchCozyAccent.withValues(alpha: 0.4),
              blurRadius: 30,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF140F0D).withValues(alpha: 0.15), width: 1.5),
              ),
            ),
            _isSaving 
              ? const CircularProgressIndicator(color: Color(0xFF140F0D), strokeWidth: 3)
              : const Icon(Icons.check_rounded, color: Color(0xFF140F0D), size: 40),
          ],
        ),
      ).animate(onPlay: (controller) => controller.repeat())
       .scale(begin: const Offset(0.95, 0.95), end: const Offset(1.05, 1.05), duration: 2.seconds, curve: Curves.easeInOut)
       .then()
       .scale(begin: const Offset(1.05, 1.05), end: const Offset(0.95, 0.95), duration: 2.seconds, curve: Curves.easeInOut),
    );
  }

  Widget _buildSuccessOverlay() {
    return Container(
      color: ProMaxColors.stitchCozyBg.withValues(alpha: 0.9),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: ProMaxColors.stitchCozyAccent,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded, color: Color(0xFF140F0D), size: 48),
          ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),
          const SizedBox(height: 24),
          const Text(
            "保存成功",
            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),
          const SizedBox(height: 8),
          const Text(
             "已添加到你的助眠库",
             style: TextStyle(color: Colors.white38, fontSize: 14),
          ).animate().fadeIn(delay: 400.ms),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _togglePreview() async {
    if (_isPreviewing) {
      _previewTimer?.cancel();
      await _previewPlayer.pause();
      if (mounted) {
        setState(() => _isPreviewing = false);
      }
      return;
    }

    _previewTimer?.cancel();
    final start = _range.start.toInt();
    final end = _range.end.toInt();
    final previewDuration = (end - start).clamp(1, widget.video.duration).toInt();
    final previewItem = widget.video.copyWith(
      startTime: start,
      endTime: end,
    );

    setState(() => _isPreviewing = true);
    try {
      final source = await _resolvePreviewSource(previewItem);
      if (source == null) {
        throw Exception('no audio source');
      }

      final headers = {
        'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Referer': 'https://www.bilibili.com/video/${previewItem.id}',
      };

      if (previewItem.filePath != null && previewItem.filePath!.isNotEmpty) {
        await _previewPlayer.setAudioSource(AudioSource.uri(Uri.file(source)));
      } else {
        await _previewPlayer.setAudioSource(AudioSource.uri(Uri.parse(source), headers: headers));
      }
      await _previewPlayer.seek(Duration(seconds: previewItem.startTime));
      await _previewPlayer.play();

      _previewTimer = Timer(Duration(seconds: previewDuration), () async {
        await _previewPlayer.pause();
        if (mounted) {
          setState(() => _isPreviewing = false);
        }
      });
    } catch (_) {
      if (mounted) {
        setState(() => _isPreviewing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("试听失败，请检查网络或音频源")),
        );
      }
    }
  }

  Future<String?> _resolvePreviewSource(VideoItem item) async {
    if (item.filePath != null && item.filePath!.isNotEmpty) {
      return item.filePath;
    }

    if (item.id.startsWith('BV')) {
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
          return await videoAudioService.getVideoAudioUrl(item.id, int.parse(cid));
        }
      } catch (_) {
        return null;
      }
    }

    return null;
  }
}

class _WaveformRangeSlider extends StatelessWidget {
  final RangeValues values;
  final double max;
  final ValueChanged<RangeValues> onChanged;

  const _WaveformRangeSlider({
    required this.values,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final startX = (values.start / (max > 0 ? max : 1)) * width;
        final endX = (values.end / (max > 0 ? max : 1)) * width;

        return Container(
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Waveform background
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(32, (index) {
                      final h = (index % 4 == 0) ? 32.0 : (index % 2 == 0) ? 16.0 : 8.0;
                      return Container(
                        width: 2,
                        height: h,
                        decoration: BoxDecoration(
                           color: Colors.white.withValues(alpha: 0.1),
                           borderRadius: BorderRadius.circular(1),
                        ),
                      );
                    }),
                  ),
                ),
              ),

              // Selection highlight
              Positioned(
                left: startX,
                width: (endX - startX).clamp(0, width),
                top: 0,
                bottom: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: ProMaxColors.stitchCozyAccent.withValues(alpha: 0.15),
                    border: Border.symmetric(
                      vertical: BorderSide(color: ProMaxColors.stitchCozyAccent.withValues(alpha: 0.5), width: 1),
                    ),
                  ),
                ),
              ),

              // Start Handle
              Positioned(
                left: (startX - 16).clamp(-16.0, width - 16),
                top: 16,
                child: _buildHandle(true),
              ),

              // End Handle
              Positioned(
                left: (endX - 16).clamp(-16.0, width - 16),
                top: 16,
                child: _buildHandle(false),
              ),

              // Invisible Slider
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 80,
                  thumbShape: SliderComponentShape.noThumb,
                  overlayShape: SliderComponentShape.noOverlay,
                  activeTrackColor: Colors.transparent,
                  inactiveTrackColor: Colors.transparent,
                  rangeThumbShape: _TransparentRangeThumbShape(),
                ),
                child: RangeSlider(
                  values: values,
                  min: 0,
                  max: max > 0 ? max : 1,
                  onChanged: onChanged,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHandle(bool isStart) {
    return Container(
      width: 32,
      height: 48,
      decoration: BoxDecoration(
        color: ProMaxColors.stitchCozyAccent,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: ProMaxColors.stitchCozyAccent.withValues(alpha: 0.6),
            blurRadius: 24,
            spreadRadius: 2,
            offset: const Offset(0, 0),
          ),
          BoxShadow(
            color: ProMaxColors.stitchCozyAccent,
            blurRadius: 8,
            offset: const Offset(0, 0),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(width: 2, height: 16, decoration: BoxDecoration(color: const Color(0xFF140F0D).withValues(alpha: 0.3), borderRadius: BorderRadius.circular(1))),
          const SizedBox(width: 2),
          Container(width: 2, height: 16, decoration: BoxDecoration(color: const Color(0xFF140F0D).withValues(alpha: 0.3), borderRadius: BorderRadius.circular(1))),
        ],
      ),
    );
  }
}

class _TransparentRangeThumbShape extends RangeSliderThumbShape {
  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => const Size(1, 1);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    bool isDiscrete = false,
    bool isEnabled = false,
    bool? isOnTop,
    required SliderThemeData sliderTheme,
    TextDirection textDirection = TextDirection.ltr,
    Thumb thumb = Thumb.start,
    bool isPressed = false,
  }) {
    // Do nothing (transparent)
  }
}

class FluidRippleAnimation extends StatelessWidget {
  final String coverUrl;
  final double size;
  final double coverSize;
  final double badgePadding;
  final double badgeIconSize;
  const FluidRippleAnimation({
    super.key,
    required this.coverUrl,
    this.size = 260,
    this.coverSize = 192,
    this.badgePadding = 8,
    this.badgeIconSize = 20,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Ripples
          _buildRipple(1.0).animate(onPlay: (c) => c.repeat()).scale(begin: const Offset(0.8, 0.8), end: const Offset(1.5, 1.5), duration: 3.seconds).fadeOut(duration: 3.seconds),
          _buildRipple(0.5).animate(onPlay: (c) => c.repeat()).scale(begin: const Offset(0.8, 0.8), end: const Offset(1.5, 1.5), duration: 3.seconds, delay: 1.seconds).fadeOut(duration: 3.seconds),
          
          // Core Cover
          Container(
            width: coverSize,
            height: coverSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: ProMaxColors.stitchCozyCardBg, width: 4),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 40, offset: const Offset(0, 20)),
              ],
              image: DecorationImage(
                image: NetworkImage(coverUrl),
                fit: BoxFit.cover,
              ),
            ),
          ).animate(onPlay: (c) => c.repeat())
           .shimmer(duration: 3.seconds, color: Colors.white10),

          // Icon Badge
          Positioned(
            bottom: 20,
            right: 20,
            child: Container(
              padding: EdgeInsets.all(badgePadding),
              decoration: const BoxDecoration(
                color: ProMaxColors.stitchCozyAccent,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.graphic_eq_rounded, color: const Color(0xFF140F0D), size: badgeIconSize),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRipple(double opacity) {
    return Container(
      width: size - 4,
      height: size - 4,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: ProMaxColors.stitchCozyAccent.withValues(alpha: 0.2)),
      ),
    );
  }
}
