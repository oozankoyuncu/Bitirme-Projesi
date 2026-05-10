with open('/Users/zeynepgokmen/Bitirme-Projesi/Game.tscn', 'r') as f:
    content = f.read()

signal_str = """
[connection signal="pressed" from="FestivalDayPanel/MarginContainer/VBoxContainer/HBoxContainer/CloseButton" to="FestivalDayPanel" method="_on_close_pressed"]
[connection signal="pressed" from="FestivalDayPanel/MarginContainer/VBoxContainer/StartFestivalButton" to="FestivalDayPanel" method="_on_start_festival_pressed"]
"""

content += signal_str

with open('/Users/zeynepgokmen/Bitirme-Projesi/Game.tscn', 'w') as f:
    f.write(content)

