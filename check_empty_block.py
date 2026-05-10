with open('scripts/festival_day_panel.gd', 'r') as f:
    lines = f.readlines()

for i in range(len(lines) - 1):
    line = lines[i].rstrip()
    if line.endswith(':'):
        next_line = lines[i+1]
        indent1 = len(lines[i]) - len(lines[i].lstrip('\t'))
        indent2 = len(next_line) - len(next_line.lstrip('\t'))
        if indent2 <= indent1 and next_line.strip() != "":
            print(f"Empty block after line {i+1}: {line}")
