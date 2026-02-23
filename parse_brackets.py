import re

with open("lib/features/library/presentation/library_screen.dart", "r") as f:
    lines = f.readlines()

def find_mismatch(start_line, end_line):
    text = "".join(lines[start_line:end_line])
    stack = []
    pairs = {')': '(', ']': '[', '}': '{'}
    for i, char in enumerate(text):
        if char in '([{':
            stack.append((char, i))
        elif char in ')]}':
            if not stack:
                print(f"Extra closing {char} at index {i}")
            else:
                top_char, _ = stack.pop()
                if top_char != pairs[char]:
                    print(f"Mismatch! Found {char}, expected closing for {top_char} at index {i}")
    
    if stack:
        print(f"Unclosed opening brackets: {stack}")
    else:
        print("All brackets balanced!")

# Check _showOptions block from builder(context) -> _deleteVideo
print("Testing builder block:")
find_mismatch(668, 862)

