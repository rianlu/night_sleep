with open("lib/features/library/presentation/library_screen.dart", "r") as f:
    content = f.read()

import re

# Safely replace the mangled try catch block for the url launcher which caused the bracket skew
# This targets lines ~760-795
old_pattern = re.compile(
    r"try\s*\{.*?final\s+bvid\s*=\s*BilibiliIdUtils\.extractBvId\(video\.id\);.*?catch\s*\(\_\)\s*\{\s*debugPrint\('Error launching url:\s*\$e'\);\s*\}\s*\}",
    re.DOTALL
)

corrected_block = """try {
                      final bvid = BilibiliIdUtils.extractBvId(video.id);
                      final page = BilibiliIdUtils.extractPageFromItemId(video.id);
                      final pageStr = page != null ? '?p=$page' : '';

                      // 尝试使用 bilibili:// esquema 协议唤起 App 直接到达播放页
                      final appUrlStr = 'bilibili://video/$bvid$pageStr';
                      final appUri = Uri.parse(appUrlStr);
                      final launched = await launchUrl(appUri);
                      
                      if (!launched) {
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
                    }"""

new_content = re.sub(old_pattern, corrected_block, content)

with open("lib/features/library/presentation/library_screen.dart", "w") as f:
    f.write(new_content)

print("URL Launcher try/catch block fixed.")
