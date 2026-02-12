import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:night_sleep/core/theme/promax_colors.dart';

import 'package:night_sleep/data/models/video_item.dart';

class ClipboardPopup extends StatelessWidget {
  final String content;
  final VideoItem? video;
  final VoidCallback onParse;
  final VoidCallback onDismiss;

  const ClipboardPopup({
    super.key,
    required this.content,
    this.video,
    required this.onParse,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final previewTitle = video?.title ?? "正在获取视频信息...";
    final previewUrl = video != null ? content : "链接解析中...";
    final isLoading = video == null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: ProMaxColors.stitchBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          // Drag Handle
          Center(
            child: Container(
              width: 48,
              height: 4,
              decoration: BoxDecoration(
                color: ProMaxColors.stitchDivider.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 32),
          
          // Header Icon
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ProMaxColors.stitchPrimary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: ProMaxColors.stitchPrimary.withValues(alpha: 0.2)),
            ),
            child: const Icon(Icons.link_rounded, color: ProMaxColors.stitchPrimary, size: 24),
          ),
          const SizedBox(height: 24),
          
          // Title
          Text(
            "检测到 B 站链接",
            style: GoogleFonts.manrope(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          // Subtitle (Rich Text)
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: GoogleFonts.manrope(color: Colors.white70, fontSize: 15, height: 1.5),
              children: [
                const TextSpan(text: "已为您解析"),
                const TextSpan(
                  text: " 剪贴板 ",
                  style: TextStyle(color: ProMaxColors.stitchPrimary, fontWeight: FontWeight.bold),
                ),
                const TextSpan(text: "中的视频内容"),
              ],
            ),
          ),
          const SizedBox(height: 32),
          
          // Preview Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ProMaxColors.stitchCardBg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Row(
              children: [
                // Thumbnail Mockup
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: Colors.black26,
                        image: video != null ? DecorationImage(
                          image: NetworkImage(video!.coverUrl),
                          fit: BoxFit.cover,
                        ) : null,
                      ),
                      child: isLoading ? const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: ProMaxColors.stitchPrimary),
                        ),
                      ) : null,
                    ),
                    if (!isLoading)
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20),
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        previewTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: ProMaxColors.stitchPrimary.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: ProMaxColors.stitchPrimary.withValues(alpha: 0.4)),
                            ),
                            child: const Text(
                              "Bilibili",
                              style: TextStyle(color: ProMaxColors.stitchPrimary, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              previewUrl,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          
          // Action Buttons
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton.icon(
              onPressed: onParse,
              icon: const Icon(Icons.check_circle_rounded),
              label: const Text("确认添加", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: ProMaxColors.stitchPrimary,
                foregroundColor: const Color(0xFF140F0D),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: onDismiss,
            child: const Text(
              "取消",
              style: TextStyle(color: ProMaxColors.stitchTextMuted, fontSize: 15),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
