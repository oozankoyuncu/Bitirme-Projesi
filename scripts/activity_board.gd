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
	
	 ##Manual Lock Logic
	#if activity_id == "sponsor_management" and GameState.week < 2: return "Locked"
	#if activity_id == "promotion_strategy" and GameState.week < 4: return "Locked"
	#if activity_id == "ticket_pricing" and GameState.week < 4: return "Locked"
	#if activity_id == "sound_system_choices" and GameState.week < 7: return "Locked"
	#if activity_id == "transport_coordination" and GameState.week < 7: return "Locked"
	#if activity_id == "decoration_theme_decision" and GameState.week < 8: return "Locked"
	#
	#if not _dependencies_completed(activity): return "Locked"
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
		var panel = get_parent().get_node(panel_name)
		if activity_id == "emergency_training": panel.refresh_member_list()
		panel.show()
		hide()
		return

	print("Started: ", activity["name"])
	GameState.completed_activities.append(activity_id)
	refresh_board()

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
