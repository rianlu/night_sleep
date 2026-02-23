import re

with open("lib/features/library/presentation/library_screen.dart", "r") as f:
    lines = f.readlines()

def check_brackets(text):
    stack = []
    pairs = {')': '(', ']': '[', '}': '{'}
    for i, char in enumerate(text):
        if char in '([{':
            stack.append((char, i))
        elif char in ')]}':
            if not stack:
                print(f"Extra closing {char} at index {i}")
            else:
                top_char, pos = stack.pop()
                if top_char != pairs[char]:
                    print(f"Mismatch! Found {char}, expected closing for {top_char} (opened at {pos}) at index {i}")
    
    if stack:
        for c, p in stack:
            line_sub = text[:p].count('\n') + 1
            print(f"Unclosed opening bracket: {c} at line roughly {line_sub}")
    else:
        print("All brackets balanced!")

content = "".join(lines)
start = content.find("void _showOptions")
end = content.find("Future<void> _deleteVideo")
check_brackets(content[start:end])

