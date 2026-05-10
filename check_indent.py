with open('scripts/festival_day_panel.gd', 'r') as f:
    lines = f.readlines()

for i, line in enumerate(lines):
    if ' \t' in line or '\t ' in line:
        print(f"Mixed tabs and spaces on line {i+1}: {repr(line)}")
