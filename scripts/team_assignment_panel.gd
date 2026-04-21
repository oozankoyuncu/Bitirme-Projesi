extends Panel

@onready var member_list: GridContainer = $MarginContainer/VBoxContainer/MainContent/LeftScroll/MemberList
@onready var confirm_button: Button = $MarginContainer/VBoxContainer/MainContent/RightPanel/ConfirmButton

var right_panel_bars: Dictionary = {}

@onready var main_panel: Panel = self
@onready var stats_sidebar: PanelContainer = $MarginContainer/VBoxContainer/MainContent/RightPanel/StatsPanel

func _ready() -> void:
	if has_node("MarginContainer/VBoxContainer/MainContent/RightPanel/CostPanel"):
		get_node("MarginContainer/VBoxContainer/MainContent/RightPanel/CostPanel").hide()
	
	_init_right_panel_stats()
	
	confirm_button.pressed.connect(_on_confirm_pressed)
	_setup_ui_styles()
	create_member_cards()
	update_stats_display()


func _setup_ui_styles() -> void:
	# Main Panel Styling
	var main_style = StyleBoxFlat.new()
	main_style.bg_color = Color(0.05, 0.07, 0.1, 0.95) # Very dark navy blue
	main_style.border_width_left = 4
	main_style.border_color = Color(0.1, 0.4, 0.7) # Neon blue accent
	main_panel.add_theme_stylebox_override("panel", main_style)
	
	# Stats Sidebar Styling
	var sidebar_style = StyleBoxFlat.new()
	sidebar_style.bg_color = Color(0.1, 0.12, 0.15, 0.8)
	sidebar_style.corner_radius_top_left = 10
	sidebar_style.corner_radius_top_right = 10
	sidebar_style.corner_radius_bottom_right = 10
	sidebar_style.corner_radius_bottom_left = 10
	sidebar_style.border_width_left = 1
	sidebar_style.border_width_top = 1
	sidebar_style.border_width_right = 1
	sidebar_style.border_width_bottom = 1
	sidebar_style.border_color = Color(0.2, 0.3, 0.4)
	stats_sidebar.add_theme_stylebox_override("panel", sidebar_style)
	
	# Button Styling
	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = Color(0.2, 0.5, 0.8) # Primary Blue
	btn_style.corner_radius_top_left = 5
	btn_style.corner_radius_top_right = 5
	btn_style.corner_radius_bottom_right = 5
	btn_style.corner_radius_bottom_left = 5
	confirm_button.add_theme_stylebox_override("normal", btn_style)
	
	var btn_hover = btn_style.duplicate()
	btn_hover.bg_color = Color(0.3, 0.6, 0.9)
	confirm_button.add_theme_stylebox_override("hover", btn_hover)


func create_member_cards() -> void:
	# Clean up old cards
	for child in member_list.get_children():
		child.queue_free()

	if GameState.all_team_members.is_empty():
		GameState.load_team_members()

	for member in GameState.all_team_members:
		var card = create_card_ui(member)
		member_list.add_child(card)


func create_card_ui(member: Dictionary) -> PanelContainer:
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(380, 280) # Increased size for more stats
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Metadata for identification
	card.set_meta("member_data", member)
	card.set_meta("selected", false)
	
	# Layout
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20) # Increased padding
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	card.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15) # More separation
	margin.add_child(vbox)
	
	# Name & Cost
	var header = HBoxContainer.new()
	vbox.add_child(header)
	
	var name_label = Label.new()
	name_label.text = member["name"]
	name_label.add_theme_font_size_override("font_size", 22) # Larger font
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(name_label)
	
	# Stats - Now in a GridContainer to allow multiple stats nicely
	var stats_grid = GridContainer.new()
	stats_grid.columns = 2
	stats_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stats_grid.add_theme_constant_override("h_separation", 15)
	stats_grid.add_theme_constant_override("v_separation", 10)
	vbox.add_child(stats_grid)
	
	add_stat_row(stats_grid, "Communication", member["communication"])
	add_stat_row(stats_grid, "Speed", member["speed"])
	add_stat_row(stats_grid, "Operations", member["operations"])
	add_stat_row(stats_grid, "Reliability", member["reliability"])
	add_stat_row(stats_grid, "Teamwork", member["teamwork"])
	add_stat_row(stats_grid, "Stress Tol.", member["stress_tolerance"])
	add_stat_row(stats_grid, "Creativity", member["creativity"])
	add_stat_row(stats_grid, "Experience", member["experience_level"])
	add_stat_row(stats_grid, "Workload Cap.", member["workload_capacity"])
	
	# Selection Button (Invisible but covers the card)
	var btn = Button.new()
	btn.flat = true
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.set_anchors_preset(Control.PRESET_FULL_RECT)
	card.add_child(btn)
	
	btn.pressed.connect(_on_card_pressed.bind(card))
	
	# Styling
	update_card_style(card)
	
	return card


func add_stat_row(parent: Control, label_text: String, value: float) -> void:
	var stat_container = VBoxContainer.new()
	stat_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(stat_container)
	
	var label_hbox = HBoxContainer.new()
	stat_container.add_child(label_hbox)
	
	var lbl = Label.new()
	lbl.text = label_text
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label_hbox.add_child(lbl)
	
	var percent_lbl = Label.new()
	percent_lbl.text = "%d%%" % (value * 20)
	percent_lbl.add_theme_font_size_override("font_size", 14)
	percent_lbl.add_theme_color_override("font_color", Color(1, 1, 1))
	label_hbox.add_child(percent_lbl)
	
	var bar = ProgressBar.new()
	bar.max_value = 5
	bar.value = value
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 10) # Slightly thicker bar
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Color based on value
	var style = StyleBoxFlat.new()
	if value >= 4:
		style.bg_color = Color(0.2, 0.8, 0.2) # Green
	elif value >= 3:
		style.bg_color = Color(0.8, 0.8, 0.2) # Yellow
	else:
		style.bg_color = Color(0.8, 0.2, 0.2) # Red
	
	style.corner_radius_top_left = 2
	style.corner_radius_top_right = 2
	style.corner_radius_bottom_right = 2
	style.corner_radius_bottom_left = 2
	
	bar.add_theme_stylebox_override("fill", style)
	stat_container.add_child(bar)


func update_card_style(card: PanelContainer) -> void:
	var is_selected = card.get_meta("selected")
	var style = StyleBoxFlat.new()
	
	if is_selected:
		style.bg_color = Color(0.2, 0.4, 0.6, 0.4) # Light blue transparent highlight
		style.border_width_left = 2
		style.border_width_top = 2
		style.border_width_right = 2
		style.border_width_bottom = 2
		style.border_color = Color(0.4, 0.8, 1.0) # Neon blue border
		style.shadow_size = 5
		style.shadow_color = Color(0, 0, 0, 0.3)
	else:
		style.bg_color = Color(0.15, 0.15, 0.15, 0.6) # Dark transparent
		style.border_width_left = 1
		style.border_width_top = 1
		style.border_width_right = 1
		style.border_width_bottom = 1
		style.border_color = Color(0.3, 0.3, 0.3)
	
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 8
	style.corner_radius_bottom_left = 8
	
	card.add_theme_stylebox_override("panel", style)


func _on_card_pressed(card: PanelContainer) -> void:
	var is_selected = card.get_meta("selected")
	card.set_meta("selected", !is_selected)
	update_card_style(card)
	update_stats_display()


func get_selected_members() -> Array:
	var selected: Array = []
	for child in member_list.get_children():
		if child is PanelContainer and child.get_meta("selected"):
			selected.append(child.get_meta("member_data"))
	return selected


func _init_right_panel_stats() -> void:
	var right_stats_container = $MarginContainer/VBoxContainer/MainContent/RightPanel/StatsPanel/MarginContainer/VBoxContainer
	for child in right_stats_container.get_children():
		child.queue_free()
	
	var stats_grid = GridContainer.new()
	stats_grid.columns = 1
	stats_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stats_grid.add_theme_constant_override("h_separation", 10)
	stats_grid.add_theme_constant_override("v_separation", 8)
	right_stats_container.add_child(stats_grid)
	
	var stat_keys = [
		{"key": "communication", "label": "Communication"},
		{"key": "speed", "label": "Speed"},
		{"key": "operations", "label": "Operations"},
		{"key": "reliability", "label": "Reliability"},
		{"key": "teamwork", "label": "Teamwork"},
		{"key": "stress_tolerance", "label": "Stress Tol."},
		{"key": "creativity", "label": "Creativity"},
		{"key": "experience_level", "label": "Experience"},
		{"key": "workload_capacity", "label": "Workload Cap."}
	]
	
	for stat in stat_keys:
		var bar = _add_right_panel_stat_row(stats_grid, stat["label"])
		right_panel_bars[stat["key"]] = bar

func _add_right_panel_stat_row(parent: Control, label_text: String) -> ProgressBar:
	var stat_container = VBoxContainer.new()
	stat_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(stat_container)
	
	var label_hbox = HBoxContainer.new()
	stat_container.add_child(label_hbox)
	
	var lbl = Label.new()
	lbl.text = label_text
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label_hbox.add_child(lbl)
	
	var percent_lbl = Label.new()
	percent_lbl.text = "0%"
	percent_lbl.add_theme_font_size_override("font_size", 12)
	percent_lbl.add_theme_color_override("font_color", Color(1, 1, 1))
	label_hbox.add_child(percent_lbl)
	
	var bar = ProgressBar.new()
	bar.max_value = 5
	bar.value = 0
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 8)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.8, 0.2, 0.2)
	style.corner_radius_top_left = 2
	style.corner_radius_top_right = 2
	style.corner_radius_bottom_right = 2
	style.corner_radius_bottom_left = 2
	bar.add_theme_stylebox_override("fill", style)
	stat_container.add_child(bar)
	
	bar.set_meta("percent_lbl", percent_lbl)
	return bar

func update_stats_display() -> void:
	var selected := get_selected_members()

	var totals = {
		"communication": 0.0,
		"speed": 0.0,
		"operations": 0.0,
		"reliability": 0.0,
		"teamwork": 0.0,
		"stress_tolerance": 0.0,
		"creativity": 0.0,
		"experience_level": 0.0,
		"workload_capacity": 0.0
	}

	var count := selected.size()
	if count > 0:
		for member in selected:
			for key in totals.keys():
				totals[key] += member[key]
		for key in totals.keys():
			totals[key] /= count

	for key in totals.keys():
		var val = totals[key]
		var bar: ProgressBar = right_panel_bars[key]
		bar.value = val
		var percent_lbl: Label = bar.get_meta("percent_lbl")
		percent_lbl.text = "%d%%" % (val * 20)
		
		var style = bar.get_theme_stylebox("fill").duplicate() as StyleBoxFlat
		if val >= 4.0:
			style.bg_color = Color(0.2, 0.8, 0.2)
		elif val >= 3.0:
			style.bg_color = Color(0.8, 0.8, 0.2)
		else:
			style.bg_color = Color(0.8, 0.2, 0.2)
		bar.add_theme_stylebox_override("fill", style)


func _on_confirm_pressed() -> void:
	var selected := get_selected_members()

	if selected.is_empty():
		# TODO: Add a nice visual warning instead of print
		print("En az bir üye seçmelisin")
		return

	GameState.selected_team = selected
	
	if not GameState.completed_activities.has("team_assignment"):
		GameState.completed_activities.append("team_assignment")
	
	hide()
	var parent_node = get_parent()
	if parent_node.has_node("ActivityBoard"):
		var activity_board = parent_node.get_node("ActivityBoard")
		activity_board.show()
		activity_board.refresh_board()
