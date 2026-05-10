import re

with open('/Users/zeynepgokmen/Bitirme-Projesi/Game.tscn', 'r') as f:
    content = f.read()

# Find the next available ext_resource ID
ext_ids = [int(m) for m in re.findall(r'id="(\d+)_', content)]
next_id = str(max(ext_ids) + 1) if ext_ids else "1"
ext_str = f'[ext_resource type="Script" uid="uid://d3x7festival" path="res://scripts/festival_day_panel.gd" id="{next_id}_fest"]\n'

# Insert ext_resource before the first node
first_node_idx = content.find('[node')
content = content[:first_node_idx] + ext_str + content[first_node_idx:]

# Append node structure
node_str = f"""
[node name="FestivalDayPanel" type="Panel" parent="."]
visible = false
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
script = ExtResource("{next_id}_fest")

[node name="MarginContainer" type="MarginContainer" parent="FestivalDayPanel"]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
theme_override_constants/margin_left = 40
theme_override_constants/margin_top = 40
theme_override_constants/margin_right = 40
theme_override_constants/margin_bottom = 40

[node name="VBoxContainer" type="VBoxContainer" parent="FestivalDayPanel/MarginContainer"]
layout_mode = 2

[node name="HBoxContainer" type="HBoxContainer" parent="FestivalDayPanel/MarginContainer/VBoxContainer"]
layout_mode = 2

[node name="TitleLabel" type="Label" parent="FestivalDayPanel/MarginContainer/VBoxContainer/HBoxContainer"]
layout_mode = 2
size_flags_horizontal = 3
theme_override_font_sizes/font_size = 48
text = "Festival Day - Live Events"

[node name="CloseButton" type="Button" parent="FestivalDayPanel/MarginContainer/VBoxContainer/HBoxContainer"]
custom_minimum_size = Vector2(120, 50)
layout_mode = 2
text = "Close"

[node name="StartFestivalButton" type="Button" parent="FestivalDayPanel/MarginContainer/VBoxContainer"]
custom_minimum_size = Vector2(0, 80)
layout_mode = 2
theme_override_font_sizes/font_size = 32
text = "START FESTIVAL"

[node name="ScrollContainer" type="ScrollContainer" parent="FestivalDayPanel/MarginContainer/VBoxContainer"]
layout_mode = 2
size_flags_vertical = 3

[node name="ScenariosList" type="VBoxContainer" parent="FestivalDayPanel/MarginContainer/VBoxContainer/ScrollContainer"]
layout_mode = 2
size_flags_horizontal = 3

[node name="DetailPanel" type="PanelContainer" parent="FestivalDayPanel"]
visible = false
layout_mode = 1
anchors_preset = 8
anchor_left = 0.5
anchor_top = 0.5
anchor_right = 0.5
anchor_bottom = 0.5
offset_left = -300.0
offset_top = -200.0
offset_right = 300.0
offset_bottom = 200.0
grow_horizontal = 2
grow_vertical = 2

[node name="MarginContainer" type="MarginContainer" parent="FestivalDayPanel/DetailPanel"]
layout_mode = 2
theme_override_constants/margin_left = 20
theme_override_constants/margin_top = 20
theme_override_constants/margin_right = 20
theme_override_constants/margin_bottom = 20

[node name="VBoxContainer" type="VBoxContainer" parent="FestivalDayPanel/DetailPanel/MarginContainer"]
layout_mode = 2

[node name="TitleLabel" type="Label" parent="FestivalDayPanel/DetailPanel/MarginContainer/VBoxContainer"]
layout_mode = 2
theme_override_font_sizes/font_size = 32
text = "Scenario Title"
horizontal_alignment = 1

[node name="DescLabel" type="Label" parent="FestivalDayPanel/DetailPanel/MarginContainer/VBoxContainer"]
layout_mode = 2
theme_override_font_sizes/font_size = 20
text = "Scenario description here..."
autowrap_mode = 3

[node name="HSeparator" type="HSeparator" parent="FestivalDayPanel/DetailPanel/MarginContainer/VBoxContainer"]
layout_mode = 2

[node name="ActionsContainer" type="VBoxContainer" parent="FestivalDayPanel/DetailPanel/MarginContainer/VBoxContainer"]
layout_mode = 2
size_flags_vertical = 3
"""

content += node_str

with open('/Users/zeynepgokmen/Bitirme-Projesi/Game.tscn', 'w') as f:
    f.write(content)

