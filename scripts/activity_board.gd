extends Control

@onready var activity_list: GridContainer = $MarginContainer/VBox/ScrollContainer/ActivityList

func _ready() -> void:
	refresh_board()
	_setup_dashboard_styles()
	_add_budget_warning()

func _process(_delta: float) -> void:
	if GameState.money <= -300000 and not has_node("GameOverOverlay"):
		show_game_over()

func _setup_dashboard_styles() -> void:
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.08, 0.1, 0.13, 0.95)
	$Background.add_theme_stylebox_override("panel", bg_style)

func _add_budget_warning() -> void:
	var warning_hbox = HBoxContainer.new()
	warning_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	warning_hbox.add_theme_constant_override("separation", 10)
	
	# Add some margin
	var warning_margin = MarginContainer.new()
	warning_margin.add_theme_constant_override("margin_bottom", 10)
	warning_margin.add_child(warning_hbox)
	
	var warning_icon = Label.new()
	warning_icon.text = "ℹ️"
	warning_icon.add_theme_font_size_override("font_size", 20)
	warning_hbox.add_child(warning_icon)
	
	var warning_text = Label.new()
	warning_text.text = "Financial Policy: If the budget drops to -300,000 TL or below, the project will be terminated immediately."
	warning_text.add_theme_font_size_override("font_size", 22)
	warning_text.modulate = Color(1.0, 0.8, 0.2, 1.0) # More noticeable color (amber)
	warning_hbox.add_child(warning_text)
	
	# Insert at the top of the VBox
	var vbox = $MarginContainer/VBox
	vbox.add_child(warning_margin)
	vbox.move_child(warning_margin, 0)

func refresh_board() -> void:
	# Clean old cards
	for child in activity_list.get_children():
		child.queue_free()
		
	# Clean old top-right container
	var old_rc = get_node_or_null("FestivalRightContainer")
	if old_rc: old_rc.queue_free()
	
	# Create top-right container
	var rc = MarginContainer.new()
	rc.name = "FestivalRightContainer"
	rc.set_anchors_preset(PRESET_TOP_RIGHT)
	rc.grow_horizontal = GROW_DIRECTION_BEGIN
	rc.add_theme_constant_override("margin_right", 120)
	rc.add_theme_constant_override("margin_top", 210) # Align with the first row of activities
	add_child(rc)

	# Populate with new cards
	for activity in GameState.activities:
		var card = create_activity_card(activity)
		
		if activity["id"] == "festival_day":
			rc.add_child(card)
		else:
			activity_list.add_child(card)
		
	# Check for game completion
	_check_game_completion()

func _check_game_completion() -> void:
	if GameState.completed_activities.size() >= GameState.activities.size():
		var charter = get_parent().get_node("CharterPanel")
		if charter:
			charter.show()
			# Switch to Success tab
			var tab_container = charter.get_node("MarginContainer/TabContainer")
			for i in range(tab_container.get_tab_count()):
				if tab_container.get_tab_title(i) == "Success":
					tab_container.current_tab = i
					break
			# Hide activity board
			hide()

func create_activity_card(activity: Dictionary) -> PanelContainer:
	var card = PanelContainer.new()
	
	if activity["id"] == "festival_day":
		card.custom_minimum_size = Vector2(480, 320)
	else:
		card.custom_minimum_size = Vector2(380, 260)
		
	card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	
	var status = get_activity_status(activity)
	_style_card(card, status, activity["id"])
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	card.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)
	
	# Header (Icon + Status)
	var header = HBoxContainer.new()
	vbox.add_child(header)
	
	var icon_label = Label.new()
	icon_label.text = get_activity_emoji(activity["id"])
	if activity["id"] == "festival_day":
		icon_label.add_theme_font_size_override("font_size", 60)
	else:
		icon_label.add_theme_font_size_override("font_size", 42)
	header.add_child(icon_label)
	
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)
	
	var status_label = Label.new()
	status_label.text = status.to_upper()
	status_label.add_theme_font_size_override("font_size", 16)
	status_label.modulate = get_status_color(status)
	header.add_child(status_label)
	
	# Title
	var title = Label.new()
	title.text = activity["name"]
	if activity["id"] == "festival_day":
		title.add_theme_font_size_override("font_size", 36)
	else:
		title.add_theme_font_size_override("font_size", 28)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(title)
	
	# Stats Row
	var stats_row = HBoxContainer.new()
	stats_row.add_theme_constant_override("separation", 20)
	vbox.add_child(stats_row)
	
	var cost_label = Label.new()
	cost_label.text = "💰 " + str(activity["cost"])
	cost_label.modulate = Color(0.7, 0.7, 0.7)
	stats_row.add_child(cost_label)
	
	var dur_label = Label.new()
	dur_label.text = "⏱ " + str(activity["duration"]) + "w"
	dur_label.modulate = Color(0.7, 0.7, 0.7)
	stats_row.add_child(dur_label)
	
	# Interaction
	if status == "Available" or (status == "Completed" and activity["id"] in ["initial_festival_layout_mapping", "final_festival_layout_mapping"]):
		card.gui_input.connect(func(event): 
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				start_activity(activity)
		)
		
		# Hover effects
		card.mouse_entered.connect(func(): _animate_hover(card, true))
		card.mouse_exited.connect(func(): _animate_hover(card, false))
	else:
		card.modulate.a = 0.5 if status == "Locked" else 0.8
	
	return card

func _style_card(card: PanelContainer, status: String, activity_id: String = "") -> void:
	var style = StyleBoxFlat.new()
	if activity_id == "festival_day":
		style.bg_color = Color(0.1, 0.4, 0.1, 0.9) # Distinct green background
	else:
		style.bg_color = Color(0.15, 0.18, 0.22, 0.8)
	style.set_corner_radius_all(12)
	style.border_width_bottom = 4
	
	match status:
		"Available":
			style.border_color = Color(0.15, 0.55, 0.9) # Blue
			if activity_id == "festival_day":
				style.border_color = Color(0.2, 0.9, 0.3) # Bright green border when available
		"Completed":
			style.border_color = Color(0.2, 0.8, 0.2) # Green
			style.bg_color = Color(0.1, 0.15, 0.1, 0.8)
		"Locked":
			style.border_color = Color(0.4, 0.4, 0.4) # Grey
			if activity_id == "festival_day":
				style.bg_color = Color(0.1, 0.2, 0.1, 0.6) # Darker green when locked
			
	card.add_theme_stylebox_override("panel", style)

func _animate_hover(card: PanelContainer, entering: bool) -> void:
	var tween = create_tween().set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	var target_scale = Vector2(1.05, 1.05) if entering else Vector2(1.0, 1.0)
	var target_color = Color(1.2, 1.2, 1.2) if entering else Color(1.0, 1.0, 1.0)
	
	tween.parallel().tween_property(card, "scale", target_scale, 0.3)
	tween.parallel().tween_property(card, "modulate", target_color, 0.3)

func get_activity_emoji(id: String) -> String:
	match id:
		"team_assignment": return "👥"
		"initial_festival_layout_mapping": return "🗺️"
		"emergency_training": return "⛑️"
		"sponsor_management": return "💰"
		"promotion_strategy": return "📢"
		"entertainment_lineup": return "🎵"
		"ticket_pricing": return "🎟️"
		"volunteer_club_recruitment": return "🤝"
		"food_vendor_selection": return "🍔"
		"stage_setup_choices": return "🏗️"
		"sound_system_choices": return "🔊"
		"transport_coordination": return "🚚"
		"decoration_theme_decision": return "🎨"
		"festival_cleaning_security": return "🧹"
		"final_festival_layout_mapping": return "📍"
		"festival_day": return "🎉"
	return "📋"

func get_status_color(status: String) -> Color:
	match status:
		"Available": return Color(0.15, 0.55, 0.9)
		"Completed": return Color(0.2, 0.8, 0.2)
		"Locked": return Color(0.6, 0.6, 0.6)
	return Color.WHITE

func get_activity_status(activity: Dictionary) -> String:
	var activity_id = activity["id"]
	if GameState.completed_activities.has(activity_id): return "Completed"
	
	if not _dependencies_completed(activity): return "Locked"
	return "Available"

func _dependencies_completed(activity: Dictionary) -> bool:
	for dep in activity["dependencies"]:
		if not GameState.completed_activities.has(dep): return false
	return true

func start_activity(activity: Dictionary) -> void:
	var activity_id = activity["id"]
	var panels = {
		"team_assignment": "TeamAssignmentPanel",
		"initial_festival_layout_mapping": "InitialFacilityLayoutPanel",
		"emergency_training": "EmergencyTrainingPanel",
		"sponsor_management": "SponsorManagementPanel",
		"entertainment_lineup": "EntertainmentLineupPanel",
		"promotion_strategy": "PromotionStrategyPanel",
		"ticket_pricing": "TicketPricingPanel",
		"volunteer_club_recruitment": "VolunteerClubPanel",
		"food_vendor_selection": "FoodVendorSelectionPanel",
		"stage_setup_choices": "StageSetupChoicesPanel",
		"sound_system_choices": "SoundSystemChoicesPanel",
		"transport_coordination": "TransportCoordinationPanel",
		"decoration_theme_decision": "DecorationThemePanel",
		"festival_cleaning_security": "FestivalCleaningSecurityPanel",
		"final_festival_layout_mapping": "FinalFacilityLayoutPanel",
		"festival_day": "FestivalDayPanel"
	}
	
	if activity_id in panels:
		var panel_name = panels[activity_id]
		_check_scenarios_and_start(activity, panel_name)
		return

	print("Started: ", activity["name"])
	GameState.completed_activities.append(activity_id)
	refresh_board()

func _check_scenarios_and_start(activity: Dictionary, panel_name: String) -> void:
	var activity_id = activity["id"]
	var messages = []
	
	if activity_id == "team_assignment":
		if GameState.active_scenarios.has("missing_team_members") and not GameState.triggered_scenarios.has("missing_team_members"):
			GameState.triggered_scenarios.append("missing_team_members")
			var members = GameState.all_team_members.duplicate()
			members.shuffle()
			if members.size() >= 2:
				var m1 = members[0]
				var m2 = members[1]
				GameState.all_team_members.erase(m1)
				GameState.all_team_members.erase(m2)
				messages.append("School Administration: %s and %s have been assigned to other tasks and will not be available for the festival." % [m1["name"], m2["name"]])
				
		if GameState.active_scenarios.has("extra_workload_capacity") and not GameState.triggered_scenarios.has("extra_workload_capacity"):
			GameState.triggered_scenarios.append("extra_workload_capacity")
			var members = GameState.all_team_members.duplicate()
			members.shuffle()
			if members.size() >= 2:
				members[0]["workload_capacity"] += 1
				members[1]["workload_capacity"] += 1
				messages.append("Team Notification: %s and %s have no exams, they can take on 1 additional task each. Workload capacity increased!" % [members[0]["name"], members[1]["name"]])
				
	elif activity_id == "emergency_training":
		if GameState.active_scenarios.has("mandatory_emergency_training") and not GameState.triggered_scenarios.has("mandatory_emergency_training"):
			GameState.triggered_scenarios.append("mandatory_emergency_training")
			var m_team = GameState.selected_team.duplicate()
			m_team.shuffle()
			var types = ["electrical_failure_response", "crowd_control", "medical_first_response", "crisis_management"]
			types.shuffle()
			if m_team.size() >= 2:
				GameState.start_member_training(m_team[0], types[0], 60.0, 0)
				GameState.start_member_training(m_team[1], types[1], 120.0, 0)
				messages.append("School Board: Due to school rules, 2 random emergency trainings have been made mandatory.\n%s and %s have been automatically assigned." % [m_team[0]["name"], m_team[1]["name"]])

	if messages.size() > 0:
		_show_scenario_popup(messages, activity, panel_name)
	else:
		_open_panel(activity, panel_name)

func _open_panel(activity: Dictionary, panel_name: String) -> void:
	var activity_id = activity["id"]
	var panel = get_parent().get_node(panel_name)
	if activity_id == "emergency_training":
		if panel.has_method("refresh_member_list"):
			panel.refresh_member_list()
	panel.show()
	hide()

func _show_scenario_popup(messages: Array, activity: Dictionary, panel_name: String) -> void:
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.85)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 100
	
	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(700, 400)
	var p_style = StyleBoxFlat.new()
	p_style.bg_color = Color(0.1, 0.12, 0.18, 1.0)
	p_style.set_corner_radius_all(15)
	p_style.border_width_left = 6
	p_style.border_width_right = 6
	p_style.border_width_top = 6
	p_style.border_width_bottom = 6
	p_style.border_color = Color(0.9, 0.7, 0.2, 1.0)
	p_style.shadow_size = 30
	p_style.shadow_color = Color(0, 0, 0, 0.7)
	panel.add_theme_stylebox_override("panel", p_style)
	center.add_child(panel)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 40)
	margin.add_theme_constant_override("margin_right", 40)
	margin.add_theme_constant_override("margin_top", 40)
	margin.add_theme_constant_override("margin_bottom", 40)
	panel.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 25)
	margin.add_child(vbox)
	
	var title = Label.new()
	title.text = "⚠️ RANDOM SCENARIO EVENT ⚠️"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 38)
	title.add_theme_color_override("font_color", Color(1.0, 0.8, 0.3))
	vbox.add_child(title)
	
	var sep = HSeparator.new()
	vbox.add_child(sep)
	
	var text = ""
	for m in messages:
		text += m + "\n\n"
		
	var body = Label.new()
	body.text = text.strip_edges()
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_size_override("font_size", 24)
	vbox.add_child(body)
	
	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)
	
	var btn = Button.new()
	btn.text = "ACKNOWLEDGE"
	btn.custom_minimum_size = Vector2(300, 65)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	
	var b_style = StyleBoxFlat.new()
	b_style.bg_color = Color(0.8, 0.6, 0.2)
	b_style.set_corner_radius_all(10)
	btn.add_theme_stylebox_override("normal", b_style)
	var b_hover = b_style.duplicate()
	b_hover.bg_color = Color(0.9, 0.7, 0.3)
	btn.add_theme_stylebox_override("hover", b_hover)
	btn.add_theme_font_size_override("font_size", 22)
	
	btn.pressed.connect(func():
		var out_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN)
		out_tween.tween_property(overlay, "modulate:a", 0.0, 0.2)
		out_tween.tween_property(panel, "scale", Vector2(0.8, 0.8), 0.2)
		out_tween.chain().tween_callback(func():
			overlay.queue_free()
			_open_panel(activity, panel_name)
		)
	)
	vbox.add_child(btn)
	
	overlay.modulate.a = 0.0
	panel.scale = Vector2(0.8, 0.8)
	var in_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	in_tween.tween_property(overlay, "modulate:a", 1.0, 0.4)
	in_tween.tween_property(panel, "scale", Vector2(1.0, 1.0), 0.4)
	
	add_child(overlay)



func show_game_over() -> void:
	# Stop the game timer
	GameState.is_running = false
	
	# Create overlay
	var overlay = ColorRect.new()
	overlay.name = "GameOverOverlay"
	overlay.color = Color(0, 0, 0, 0.85)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 100
	add_child(overlay)
	
	var center_container = CenterContainer.new()
	center_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center_container)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 30)
	center_container.add_child(vbox)
	
	# Icon
	var icon = Label.new()
	icon.text = "⚠️"
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.add_theme_font_size_override("font_size", 120)
	vbox.add_child(icon)
	
	# Title
	var title = Label.new()
	title.text = "PROJECT FAILED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 72)
	title.modulate = Color(1, 0.2, 0.2)
	vbox.add_child(title)
	
	# Message
	var msg = Label.new()
	msg.text = "Critical Budget Loss: Your funding has dropped to " + str(GameState.money) + " TL.\n\nThe university has cancelled the festival due to financial instability.\nAll planning activities must cease immediately."
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	msg.custom_minimum_size = Vector2(600, 0)
	msg.add_theme_font_size_override("font_size", 24)
	vbox.add_child(msg)
	
	# Restart Button
	var btn = Button.new()
	btn.text = "RETURN TO MAIN MENU"
	btn.custom_minimum_size = Vector2(300, 60)
	btn.pressed.connect(func(): get_tree().change_scene_to_file("res://main_menu.tscn"))
	
	var btn_center = CenterContainer.new()
	btn_center.add_child(btn)
	vbox.add_child(btn_center)
	
	# Animation
	overlay.modulate.a = 0
	var tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(overlay, "modulate:a", 1.0, 1.0)
	
	# Visual effects for the card board to show it's disabled
	activity_list.modulate = Color(0.3, 0.3, 0.3)
