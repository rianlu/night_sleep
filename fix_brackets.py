with open("lib/features/library/presentation/library_screen.dart", "r") as f:
    content = f.read()

# I will cleanly re-write the exact end block of _showOptions
corrected_block = """                        Text(
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
        ),
      ),
    );
  }

  Future<void> _deleteVideo(VideoItem video, AppPalette palette) async {"""

import re
# We just replace from "删除此音频" down to _deleteVideo
pattern = re.compile(r"Text\(\s*'删除此音频',.*?Future<void> _deleteVideo\(VideoItem video, AppPalette palette\) async \{", re.DOTALL)
new_content = re.sub(pattern, corrected_block.strip() + " {", content)

with open("lib/features/library/presentation/library_screen.dart", "w") as f:
    f.write(new_content)

print("Done replacing.")
