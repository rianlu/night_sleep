import re

with open('lib/features/library/presentation/library_screen.dart', 'r') as f:
    lines = f.readlines()

def check_brackets(start, end):
    text = "".join(lines[start:end])
    print(f"Checking lines {start+1} to {end}:")
    counts = {'(': 0, ')': 0, '[': 0, ']': 0, '{': 0, '}': 0}
    for char in text:
        if char in counts:
            counts[char] += 1
    print(f"  ( : {counts['(']}  ) : {counts[')']}  Diff: {counts['('] - counts[')']}")
    print(f"  [ : {counts['[']}  ] : {counts[']']}  Diff: {counts['['] - counts[']']}")
    print(f"  {{ : {counts['{']}  }} : {counts['}']}  Diff: {counts['{'] - counts['}']}\n")

print("Checking _addToQueue (SnackBar):")
check_brackets(560, 660)

print("Checking _showOptions (BottomSheet):")
check_brackets(661, 880)

