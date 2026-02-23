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
                line_no = text[:i].count('\n') + 1
                return f"Extra closing {char} at line {line_no}"
            else:
                top_char, pos = stack.pop()
                if top_char != pairs[char]:
                    line_no = text[:i].count('\n') + 1
                    open_line = text[:pos].count('\n') + 1
                    return f"Mismatch! Found {char} at line {line_no}, expected closing for {top_char} (opened at line {open_line})"
    
    if stack:
        for c, p in stack:
            line_no = text[:p].count('\n') + 1
            return f"Unclosed opening bracket: {c} at line {line_no}"
    return "All brackets balanced!"

print(check_brackets("".join(lines)))

