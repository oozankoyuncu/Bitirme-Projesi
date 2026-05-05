import re

with open('Game.tscn', 'r') as f:
    content = f.read()

content = content.replace('''[node name="ElectricalButton" type="Button" parent="EmergencyTrainingPanel/MarginContainer/VBoxContainer/MainContent/ProgramsColumn/TrainingButtons"]
custom_minimum_size = Vector2(0, 
theme_override_font_sizes/font_size = 20''', '''[node name="ElectricalButton" type="Button" parent="EmergencyTrainingPanel/MarginContainer/VBoxContainer/MainContent/ProgramsColumn/TrainingButtons"]
custom_minimum_size = Vector2(0, 80)
theme_override_font_sizes/font_size = 20
layout_mode = 2
text = "ELECTRICAL FAILURE"''')

content = content.replace('''[node name="CrowdButton" type="Button" parent="EmergencyTrainingPanel/MarginContainer/VBoxContainer/MainContent/ProgramsColumn/TrainingButtons"]
custom_minimum_size = Vector2(0, 
theme_override_font_sizes/font_size = 20''', '''[node name="CrowdButton" type="Button" parent="EmergencyTrainingPanel/MarginContainer/VBoxContainer/MainContent/ProgramsColumn/TrainingButtons"]
custom_minimum_size = Vector2(0, 80)
theme_override_font_sizes/font_size = 20
layout_mode = 2
text = "CROWD CONTROL"''')

content = content.replace('''[node name="MedicalButton" type="Button" parent="EmergencyTrainingPanel/MarginContainer/VBoxContainer/MainContent/ProgramsColumn/TrainingButtons"]
custom_minimum_size = Vector2(0, 
theme_override_font_sizes/font_size = 20''', '''[node name="MedicalButton" type="Button" parent="EmergencyTrainingPanel/MarginContainer/VBoxContainer/MainContent/ProgramsColumn/TrainingButtons"]
custom_minimum_size = Vector2(0, 80)
theme_override_font_sizes/font_size = 20
layout_mode = 2
text = "MEDICAL RESPONSE"''')

content = content.replace('''[node name="CrisisButton" type="Button" parent="EmergencyTrainingPanel/MarginContainer/VBoxContainer/MainContent/ProgramsColumn/TrainingButtons"]
custom_minimum_size = Vector2(0, 
theme_override_font_sizes/font_size = 20''', '''[node name="CrisisButton" type="Button" parent="EmergencyTrainingPanel/MarginContainer/VBoxContainer/MainContent/ProgramsColumn/TrainingButtons"]
custom_minimum_size = Vector2(0, 80)
theme_override_font_sizes/font_size = 20
layout_mode = 2
text = "CRISIS MGMT"''')

with open('Game.tscn', 'w') as f:
    f.write(content)

