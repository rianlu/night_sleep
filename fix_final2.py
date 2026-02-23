import re

with open("lib/features/library/presentation/library_screen.dart", "r") as f:
    text = f.read()

# Fix the { { typo
text = re.sub(r"Future<void> _deleteVideo\(VideoItem video,\s*AppPalette palette\)\s*async\s*\{\s*\{", 
               r"Future<void> _deleteVideo(VideoItem video, AppPalette palette) async {", text)

with open("lib/features/library/presentation/library_screen.dart", "w") as f:
    f.write(text)

print("Fixed double brace.")
