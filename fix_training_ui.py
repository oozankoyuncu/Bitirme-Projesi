import re

with open('Game.tscn', 'r') as f:
    content = f.read()

# Increase ProgramsColumn width
content = content.replace(
    'parent="EmergencyTrainingPanel/MarginContainer/VBoxContainer/MainContent"]\ncustom_minimum_size = Vector2(250, 0)',
    'parent="EmergencyTrainingPanel/MarginContainer/VBoxContainer/MainContent"]\ncustom_minimum_size = Vector2(350, 0)'
)

# Increase StatusColumn width
content = content.replace(
    'parent="EmergencyTrainingPanel/MarginContainer/VBoxContainer/MainContent"]\ncustom_minimum_size = Vector2(280, 0)',
    'parent="EmergencyTrainingPanel/MarginContainer/VBoxContainer/MainContent"]\ncustom_minimum_size = Vector2(350, 0)'
)

# Add font sizes to titles
for title in ['ProgramTitle', 'MembersTitle', 'StatusTitle']:
    pattern = r'(\[node name="' + title + r'".*?\ntext = ".*?"\nhorizontal_alignment = 1)\n'
    content = re.sub(pattern, r'\1\ntheme_override_font_sizes/font_size = 26\ntheme_override_colors/font_color = Color(0.8, 0.9, 1.0, 1)\n', content)

# Update buttons
buttons = ['ElectricalButton', 'CrowdButton', 'MedicalButton', 'CrisisButton']
for btn in buttons:
    pattern = r'(\[node name="' + btn + r'".*?\ncustom_minimum_size = Vector2\(0, )60(\)\nlayout_mode = 2\ntext = ".*?")\n'
    content = re.sub(pattern, r'\1\ntheme_override_font_sizes/font_size = 20\n', content)
    
    # Also change 60 to 80
    content = content.replace(
        f'[node name="{btn}" type="Button" parent="EmergencyTrainingPanel/MarginContainer/VBoxContainer/MainContent/ProgramsColumn/TrainingButtons"]\ncustom_minimum_size = Vector2(0, 60)',
        f'[node name="{btn}" type="Button" parent="EmergencyTrainingPanel/MarginContainer/VBoxContainer/MainContent/ProgramsColumn/TrainingButtons"]\ncustom_minimum_size = Vector2(0, 80)'
    )

with open('Game.tscn', 'w') as f:
    f.write(content)
