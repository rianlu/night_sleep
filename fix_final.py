import re

with open("lib/features/library/presentation/library_screen.dart", "r") as f:
    content = f.read()

# I am replacing the broken exact end of _showOptions
old_str = """
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _deleteVideo(VideoItem video, AppPalette palette) async {
"""

new_str = """
            ),
          ),
        );
      },
    );
  }

  Future<void> _deleteVideo(VideoItem video, AppPalette palette) async {
"""

if old_str in content:
    content = content.replace(old_str, new_str, 1)
    with open("lib/features/library/presentation/library_screen.dart", "w") as f:
        f.write(content)
    print("Fix applied via exact string replacement.")
else:
    print("String not found! Doing fallback regex.")
    # Fallback to precise regex insertion
    pattern = re.compile(r"(\s+)\),\n\s+\),\n\s+\),\n\s+\),\n\s+\);\n\s+\}\n\n\s+Future<void> _deleteVideo")
    
    new_tail = r"\1),\n\1),\n      );\n    },\n  );\n}\n\n  Future<void> _deleteVideo"
    content = re.sub(pattern, new_tail, content)
    with open("lib/features/library/presentation/library_screen.dart", "w") as f:
        f.write(content)
    print("Fix applied via regex.")

