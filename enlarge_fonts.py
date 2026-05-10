import re

with open('/Users/zeynepgokmen/Bitirme-Projesi/scripts/festival_day_panel.gd', 'r') as f:
    content = f.read()

# clock
content = content.replace('clock_label.add_theme_font_size_override("font_size", 42)', 'clock_label.add_theme_font_size_override("font_size", 64)')
# live
content = content.replace('live_label.add_theme_font_size_override("font_size", 28)', 'live_label.add_theme_font_size_override("font_size", 42)')

# Card icon and title
content = content.replace('icon.add_theme_font_size_override("font_size", 36)', 'icon.add_theme_font_size_override("font_size", 48)')
content = content.replace('title.add_theme_font_size_override("font_size", 24)', 'title.add_theme_font_size_override("font_size", 32)')

# Card time label
content = content.replace('vbox.add_child(time_lbl)', 'time_lbl.add_theme_font_size_override("font_size", 24)\n\tvbox.add_child(time_lbl)')

# Card respond btn
content = content.replace('btn.custom_minimum_size = Vector2(150, 0)', 'btn.custom_minimum_size = Vector2(200, 0)\n\tbtn.add_theme_font_size_override("font_size", 28)')

# Modal texts
# Since detail_title and detail_desc are nodes from tscn, we should add theme overrides in _on_scenario_selected
mod = """	detail_title.text = "INCIDENT: " + sc["title"]
	detail_title.add_theme_color_override("font_color", sc["color"].lightened(0.5))
	detail_title.add_theme_font_size_override("font_size", 36)
	detail_desc.text = sc["desc"]
	detail_desc.add_theme_font_size_override("font_size", 28)"""
content = re.sub(r'detail_title.text = "INCIDENT: " \+ sc\["title"\].*?detail_desc.text = sc\["desc"\]', mod, content, flags=re.DOTALL)

# Modal Decision Options
mod_btn1 = """btn.custom_minimum_size = Vector2(0, 70)
			btn.add_theme_font_size_override("font_size", 24)"""
content = content.replace('btn.custom_minimum_size = Vector2(0, 70)', mod_btn1)

# Modal Member Selection
content = content.replace('info.text = "Select an executive action:"', 'info.text = "Select an executive action:"\n\t\tinfo.add_theme_font_size_override("font_size", 28)')
content = content.replace('info.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))\n\t\tdetail_actions.add_child(info)', 'info.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))\n\t\tinfo.add_theme_font_size_override("font_size", 28)\n\t\tdetail_actions.add_child(info)')

# Grid members
content = content.replace('m_btn.custom_minimum_size = Vector2(250, 50)', 'm_btn.custom_minimum_size = Vector2(250, 60)\n\t\t\tm_btn.add_theme_font_size_override("font_size", 24)')

# Dispatch button
content = content.replace('resolve_btn.add_theme_font_size_override("font_size", 20)', 'resolve_btn.add_theme_font_size_override("font_size", 32)')

# Cancel button
content = content.replace('close_btn.custom_minimum_size = Vector2(0, 40)', 'close_btn.custom_minimum_size = Vector2(0, 60)\n\tclose_btn.add_theme_font_size_override("font_size", 28)')


with open('/Users/zeynepgokmen/Bitirme-Projesi/scripts/festival_day_panel.gd', 'w') as f:
    f.write(content)

