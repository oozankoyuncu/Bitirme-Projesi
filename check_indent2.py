with open('scripts/festival_day_panel.gd', 'r') as f:
    lines = f.readlines()

for i, line in enumerate(lines):
    indent = len(line) - len(line.lstrip())
    if indent > 0 and line[0] == ' ':
        print(f"Space indent on line {i+1}: {repr(line)}")
