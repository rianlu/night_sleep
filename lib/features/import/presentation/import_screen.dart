import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:night_sleep/core/theme/promax_colors.dart';
import 'package:night_sleep/features/import/data/bilibili_import_service.dart';
import 'package:night_sleep/features/import/presentation/audio_parser_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ImportScreen extends StatefulWidget {
  final String? initialText;
  const ImportScreen({super.key, this.initialText});

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  late final TextEditingController _controller;
  final BilibiliImportService _importService = BilibiliImportService();
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
    if (widget.initialText != null && widget.initialText!.isNotEmpty) {
      // 自动开始导入分享的内容
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _import();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _import() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // 解析短链接或普通链接
      final resolvedId = await _importService.resolveShortLink(text);
      
      if (resolvedId == null) {
        throw "无法识别 BV 号，请检查链接";
      }

      final video = await _importService.fetchVideoInfo(resolvedId);
      
      if (video != null) {
         if (mounted) {
           final result = await Navigator.push<bool>(
             context,
             MaterialPageRoute(builder: (context) => AudioParserScreen(video: video)),
           );
           if (result == true && mounted) {
             Navigator.pop(context, true);
           }
         }
      } else {
        throw "获取视频信息失败，请重试";
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ProMaxColors.stitchCozyBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: ProMaxColors.stitchCozyTextMuted),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "解析新内容",
          style: GoogleFonts.manrope(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          // Using a subtle gradient for "Cozy" theme if needed, or just solid bg
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              ProMaxColors.stitchCozyBg,
              Color(0xFF0F0B09), // Even darker bottom
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 32),
                
                // Header section
                Text(
                  "粘贴 B 站链接",
                  style: GoogleFonts.manrope(
                    color: ProMaxColors.stitchCozyAccent,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ).animate().fadeIn(duration: 600.ms).slideX(begin: -0.1, end: 0),
                const SizedBox(height: 12),
                Text(
                  "复制您想收听的视频或音频链接，我们将为您提取纯净的音频内容。",
                  style: const TextStyle(
                    color: ProMaxColors.stitchCozyTextMuted,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ).animate().fadeIn(duration: 600.ms, delay: 100.ms).slideX(begin: -0.1, end: 0),
                
                const SizedBox(height: 40),
                
                // Input area
                Expanded(
                  child: _buildInputSection(),
                ),
                
                if (_error != null) _buildErrorText(),
                
                const SizedBox(height: 24),

                _buildInfoSection(),

                const Spacer(),
                
                // Actions
                _buildParseButton(),
                
                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputSection() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: ProMaxColors.stitchCozyCardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _error != null ? Colors.redAccent.withValues(alpha: 0.5) : ProMaxColors.stitchCozyAccent.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: TextField(
              controller: _controller,
              maxLines: null,
              expands: true,
              style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.5),
              decoration: InputDecoration(
                hintText: "https://www.bilibili.com/video/...",
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.15)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.only(bottom: 60), // Space for paste button
              ),
            ),
          ),
          Positioned(
            bottom: 16,
            right: 16,
            child: _buildPasteButton(),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms, delay: 200.ms).scale(begin: const Offset(0.95, 0.95));
  }

  Widget _buildPasteButton() {
    return GestureDetector(
      onTap: () async {
        final data = await Clipboard.getData(Clipboard.kTextPlain);
        if (data?.text != null) {
          _controller.text = data!.text!;
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: ProMaxColors.stitchCozyAccent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.content_paste_rounded, color: Color(0xFF140F0D), size: 16),
            SizedBox(width: 8),
            Text(
              "一键粘贴",
              style: TextStyle(
                color: Color(0xFF140F0D),
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParseButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _import,
        style: ElevatedButton.styleFrom(
          backgroundColor: ProMaxColors.stitchCozyAccent,
          foregroundColor: const Color(0xFF140F0D), // Black text on Gold
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          elevation: 0,
        ),
        child: _isLoading 
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: Color(0xFF140F0D),
                strokeWidth: 2.5,
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.flash_on_rounded, size: 20),
                const SizedBox(width: 8),
                Text(
                  "开始解析",
                  style: GoogleFonts.manrope(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
      ),
    ).animate().fadeIn(duration: 600.ms, delay: 300.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildErrorText() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Center(
        child: Text(
          _error!,
          style: const TextStyle(color: Colors.redAccent, fontSize: 13),
          textAlign: TextAlign.center,
        ),
      ),
    ).animate().shake();
  }

  Widget _buildInfoSection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_rounded, color: ProMaxColors.stitchCozyAccent.withValues(alpha: 0.7), size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            "支持解析视频、电台等多种格式。\n解析过程可能需要几秒钟，请耐心等待。",
            style: TextStyle(
              color: ProMaxColors.stitchCozyTextMuted.withValues(alpha: 0.6),
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 400.ms);
  }
}
