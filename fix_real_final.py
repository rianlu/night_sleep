import re
with open("lib/features/library/presentation/library_screen.dart", "r") as f:
    text = f.read()

# Replace the specific syntax typo:
text = text.replace("Future<void> _deleteVideo(VideoItem video, AppPalette palette) async { {", "Future<void> _deleteVideo(VideoItem video, AppPalette palette) async {")

# Ensure all 3 closing brackets at the end of _showOptions exist right before _deleteVideo
pattern = re.compile(r"\)\s*;\s*\}\s*,\s*\)\s*;\s*\}\s*Future<void> _deleteVideo")
if not pattern.search(text):
    # Bruteforce inject the correct ending
    bad_pattern = re.compile(r"(\s+)\],\n\s+\),\n\s+\),\n\s+\),\n\s+\]\n\s+\)\n\s+\)\n\s+\)\n\s+\)\n\s+\}\n\s+\Future<void> _deleteVideo", re.MULTILINE | re.DOTALL)
    text = re.sub(
        r"(\s+)\]\,\n\s+\)\,\n\s+\)\,\n\s+\)\,\n\s+\]\,\n\s+\)\,\n\s+\)\,\n\s+\)\,\n\s+\)\,\n\s+\}\n\s+Future<void> _deleteVideo",
        r"\n              ],\n            ),\n          ),\n        ),\n      ),\n    );\n  }\n\n  Future<void> _deleteVideo",
        text
    )

with open("lib/features/library/presentation/library_screen.dart", "w") as f:
    f.write(text)
