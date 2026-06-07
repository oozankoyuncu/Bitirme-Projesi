extends Panel

var selected_training_type: String = ""

var training_defs = {
	"electrical_failure_response": {
		"display_name": "Electrical Failure Response",
		"duration": 60.0,
		"cost_per_member": 100,
		"description": "Handle power outages and technical failures."
	},
	"crowd_control": {
		"display_name": "Crowd Control & Evacuation",
		"duration": 120.0,
		"cost_per_member": 80,
		"description": "Manage large crowds and safe evacuations."
	},
	"medical_first_response": {
		"display_name": "Medical First Response",
		"duration": 90.0,
		"cost_per_member": 90,
		"description": "Respond to medical emergencies and first aid."
	},
	"crisis_management": {
		"display_name": "Crisis & Risk Management",
		"duration": 150.0,
		"cost_per_member": 110,
		"description": "Handle unforeseen problems and high pressure."
	}
}

# UI References
@onready var time_label: Label = $MarginContainer/VBoxContainer/Footer/TimerBox/TimeRemainingLabel
@onready var money_label: Label = $MarginContainer/VBoxContainer/Footer/MoneyBox/MoneyLabel
@onready var member_list_container: GridContainer = $MarginContainer/VBoxContainer/MainContent/MembersColumn/ScrollContainer/MemberList
@onready var active_trainings_container: VBoxContainer = $MarginContainer/VBoxContainer/MainContent/StatusColumn/StatusPanel/MarginContainer/ScrollContainer/VBoxContainer
@onready var back_button: Button = $MarginContainer/VBoxContainer/Footer/BackButton
@onready var finish_button: Button = $MarginContainer/VBoxContainer/Footer/FinishButton

@onready var elec_btn: Button = $MarginContainer/VBoxContainer/MainContent/ProgramsColumn/TrainingButtons/ElectricalButton
@onready var crowd_btn: Button = $MarginContainer/VBoxContainer/MainContent/ProgramsColumn/TrainingButtons/CrowdButton
@onready var med_btn: Button = $MarginContainer/VBoxContainer/MainContent/ProgramsColumn/TrainingButtons/MedicalButton
@onready var crisis_btn: Button = $MarginContainer/VBoxContainer/MainContent/ProgramsColumn/TrainingButtons/CrisisButton

@onready var info_btn: Button = $MarginContainer/VBoxContainer/Header/InfoButton
@onready var guide_panel: PanelContainer = $GuidePanel
@onready var guide_label: Label = $GuidePanel/MarginContainer/VBoxContainer/ScrollContainer/GuideLabel
@onready var close_guide_btn: Button = $GuidePanel/MarginContainer/VBoxContainer/Header/CloseGuideButton

func _ready() -> void:

	# -- DYNAMIC BUTTON INJECTION --
	var __footer_found = false
	var __footer_node = null
	
	# Try common paths
	var __paths = [
		"MarginContainer/VBoxContainer/Footer",
		"MarginContainer/VBoxContainer/ButtonRow",
		"MarginContainer/VBoxContainer/MainContent/RightPanel",
		"MarginContainer/VBoxContainer/HBoxContainer"
	]
	
	for p in __paths:
		if has_node(p):
			__footer_node = get_node(p)
			__footer_found = true
			break
	
	if __footer_node != null:
		# Hide or remove any existing Confirm/Back buttons to replace with our standard ones
		for c in __footer_node.get_children():
			if c is Button and (c.name.find("Confirm") >= 0 or c.name.find("Back") >= 0 or c.name.find("Finish") >= 0):
				c.hide()
				# Keep them hidden, we'll use our own
		
		var __hbox = HBoxContainer.new()
		__hbox.alignment = BoxContainer.ALIGNMENT_CENTER
		__hbox.add_theme_constant_override("separation", 20)
		__hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		var __back_btn = Button.new()
		__back_btn.text = "BACK"
		__back_btn.custom_minimum_size = Vector2(150, 45)
		var __b_style = StyleBoxFlat.new()
		__b_style.bg_color = Color(0.3, 0.3, 0.3)
		__b_style.set_corner_radius_all(6)
		__back_btn.add_theme_stylebox_override("normal", __b_style)
		__back_btn.pressed.connect(self._on_back_pressed)
		__hbox.add_child(__back_btn)
		
		var __finish_btn = Button.new()
		__finish_btn.text = "FINISH"
		__finish_btn.custom_minimum_size = Vector2(150, 45)
		var __f_style = StyleBoxFlat.new()
		__f_style.bg_color = Color(0.1, 0.6, 0.2)
		__f_style.set_corner_radius_all(6)
		__finish_btn.add_theme_stylebox_override("normal", __f_style)
		if self.has_method("_on_finish_pressed"):
			__finish_btn.pressed.connect(self._on_finish_pressed)
		__hbox.add_child(__finish_btn)
		
		__footer_node.add_child(__hbox)
	# Program Connections
	elec_btn.pressed.connect(func(): _on_program_selected("electrical_failure_response", elec_btn))
	crowd_btn.pressed.connect(func(): _on_program_selected("crowd_control", crowd_btn))
	med_btn.pressed.connect(func(): _on_program_selected("medical_first_response", med_btn))
	crisis_btn.pressed.connect(func(): _on_program_selected("crisis_management", crisis_btn))

	# Update button labels with cost & duration info
	var _btn_map = {
		"electrical_failure_response": elec_btn,
		"crowd_control": crowd_btn,
		"medical_first_response": med_btn,
		"crisis_management": crisis_btn,
	}
	for type_key in _btn_map:
		var btn = _btn_map[type_key]
		var td = training_defs[type_key]
		btn.text = td["display_name"] + "\nCost: " + str(td["cost_per_member"]) + " TL/member  |  Duration: " + str(int(td["duration"])) + "s"

	info_btn.pressed.connect(func(): guide_panel.show())
	close_guide_btn.pressed.connect(func(): guide_panel.hide())

	_setup_guide_text()
	_setup_ui_styles()
	
	# Dynamically add note below the footer
	var note_label = Label.new()
	note_label.text = "* Note: Pressing FINISH will immediately advance the time by the total max duration (240 seconds)."
	note_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note_label.add_theme_font_size_override("font_size", 16)
	note_label.add_theme_color_override("font_color", Color(0.8, 0.4, 0.4))
	$MarginContainer/VBoxContainer.add_child(note_label)

func _process(_delta: float) -> void:
	_refresh_ui()

func _setup_ui_styles() -> void:
	var main_style = StyleBoxFlat.new()
	main_style.bg_color = Color(0.02, 0.05, 0.1, 0.95)
	main_style.border_width_left = 4
	main_style.border_color = Color(0.1, 0.4, 0.8) # Academy Blue
	add_theme_stylebox_override("panel", main_style)

	var status_style = StyleBoxFlat.new()
	status_style.bg_color = Color(0.1, 0.12, 0.15, 0.8)
	status_style.border_width_left = 1
	status_style.border_color = Color(0.2, 0.3, 0.5)
	$MarginContainer/VBoxContainer/MainContent/StatusColumn/StatusPanel.add_theme_stylebox_override("panel", status_style)

	# Ensure the scroll container and list container pass mouse events to enable scroll wheel scrolling
	member_list_container.mouse_filter = Control.MOUSE_FILTER_PASS
	member_list_container.get_parent().mouse_filter = Control.MOUSE_FILTER_PASS
	
	active_trainings_container.mouse_filter = Control.MOUSE_FILTER_PASS
	active_trainings_container.get_parent().mouse_filter = Control.MOUSE_FILTER_PASS

	refresh_member_list()

func refresh_member_list() -> void:
	for child in member_list_container.get_children():
		child.queue_free()

	for member in GameState.selected_team:
		var card = _create_member_card(member)
		member_list_container.add_child(card)

func _create_member_card(member: Dictionary) -> PanelContainer:
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 95)
	card.mouse_filter = Control.MOUSE_FILTER_PASS
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.18, 0.25, 0.7)
	style.corner_radius_top_left = 5
	style.corner_radius_bottom_left = 5
	card.add_theme_stylebox_override("panel", style)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 15)
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(hbox)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(margin)

	var v_info = VBoxContainer.new()
	v_info.size_flags_horizontal = SIZE_EXPAND_FILL
	v_info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(v_info)

	var name_lbl = Label.new()
	name_lbl.text = member["name"]
	name_lbl.add_theme_font_size_override("font_size", 22)
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v_info.add_child(name_lbl)

	# Training Load Progress
	var load_box = HBoxContainer.new()
	load_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v_info.add_child(load_box)

	var pbar = ProgressBar.new()
	pbar.max_value = 240.0
	pbar.value = member.get("total_training_time", 0.0)
	pbar.custom_minimum_size = Vector2(300, 20) # Larger bar
	pbar.show_percentage = false
	pbar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Color coding for load
	var p_style = StyleBoxFlat.new()
	p_style.set_corner_radius_all(8)
	if pbar.value > 200: p_style.bg_color = Color(0.9, 0.2, 0.2)
	elif pbar.value > 120: p_style.bg_color = Color(0.9, 0.6, 0.1)
	else: p_style.bg_color = Color(0.2, 0.7, 0.9)
	pbar.add_theme_stylebox_override("fill", p_style)
	
	load_box.add_child(pbar)
	
	var time_lbl = Label.new()
	time_lbl.text = str(int(pbar.value)) + "s / 240s"
	time_lbl.add_theme_font_size_override("font_size", 18) # Larger font
	time_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	load_box.add_child(time_lbl)

	# Assign Button
	var assign_btn = Button.new()
	assign_btn.text = "ASSIGN"
	assign_btn.custom_minimum_size = Vector2(140, 50)
	assign_btn.add_theme_font_size_override("font_size", 18)
	assign_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	
	if member.get("is_in_training", false):
		assign_btn.text = "TRAINING..."
		assign_btn.disabled = true
	elif selected_training_type == "":
		assign_btn.disabled = true
	
	assign_btn.pressed.connect(func(): _on_assign_pressed(member))
	hbox.add_child(assign_btn)

	return card

func _on_program_selected(type: String, btn: Button) -> void:
	selected_training_type = type
	
	# Clear styles
	for b in [elec_btn, crowd_btn, med_btn, crisis_btn]:
		b.remove_theme_stylebox_override("normal")
	
	var select_style = StyleBoxFlat.new()
	select_style.bg_color = Color(0.1, 0.4, 0.9, 0.6)
	select_style.border_width_left = 4
	select_style.border_color = Color.WHITE
	btn.add_theme_stylebox_override("normal", select_style)
	
	refresh_member_list()

func _on_assign_pressed(member: Dictionary) -> void:
	if selected_training_type == "": return
	
	var training = training_defs[selected_training_type]
	var ok = GameState.start_member_training(
		member,
		selected_training_type,
		training["duration"],
		training["cost_per_member"]
	)
	
	if ok:
		refresh_member_list()
		_refresh_ui()

func _refresh_ui() -> void:
	var remaining := GameState.get_emergency_training_remaining_time()
	time_label.text = "Academy Window Remaining: %.1f sec" % remaining
	time_label.add_theme_font_size_override("font_size", 24) # Bigger label
	money_label.text = "Available Budget: $" + str(GameState.money)
	money_label.add_theme_font_size_override("font_size", 24)

	# Update active training bars
	for child in active_trainings_container.get_children():
		child.queue_free()
		
	if GameState.active_trainings.is_empty():
		var empty_lbl = Label.new()
		empty_lbl.text = "No active training sessions."
		empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_lbl.add_theme_font_size_override("font_size", 20)
		empty_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		active_trainings_container.add_child(empty_lbl)
	else:
		for training in GameState.active_trainings:
			var t_box = VBoxContainer.new()
			t_box.add_theme_constant_override("separation", 5)
			t_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
			active_trainings_container.add_child(t_box)
			
			var name_lbl = Label.new()
			name_lbl.text = training["member_name"] + " - " + training_defs[training["training_type"]]["display_name"]
			name_lbl.add_theme_font_size_override("font_size", 20)
			name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			t_box.add_child(name_lbl)
			
			var left = max(0.0, training["end_time"] - GameState.game_seconds)
			var duration = training_defs[training["training_type"]]["duration"]
			
			var bar = ProgressBar.new()
			bar.max_value = duration
			bar.value = left # This will decrease as 'left' decreases
			bar.custom_minimum_size = Vector2(0, 30) # Big enough bar
			bar.show_percentage = false
			bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
			
			# Stylish fill
			var style = StyleBoxFlat.new()
			style.bg_color = Color(0.2, 0.8, 0.4) # Fresh green for progress
			style.set_corner_radius_all(6)
			bar.add_theme_stylebox_override("fill", style)
			
			var bg = StyleBoxFlat.new()
			bg.bg_color = Color(0.1, 0.1, 0.1, 1.0)
			bg.set_corner_radius_all(6)
			bar.add_theme_stylebox_override("background", bg)
			
			t_box.add_child(bar)
			
			var countdown_lbl = Label.new()
			countdown_lbl.text = str(int(left)) + " seconds remaining"
			countdown_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			countdown_lbl.add_theme_font_size_override("font_size", 18)
			countdown_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			t_box.add_child(countdown_lbl)
			
			# Spacing
			var spacer = Control.new()
			spacer.custom_minimum_size.y = 10
			spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
			active_trainings_container.add_child(spacer)
	
	# Periodically refresh the member list to update "is_in_training" status
	# (In a real game, you might use signals, but for 4 mins, a quick scan works)
	var still_training = false
	for m in GameState.selected_team:
		if m.get("is_in_training", false):
			still_training = true
			break
	
	# If any training finished since last card refresh, update the UI
	# We could optimize this, but simple is fine for now
	# _refresh_member_list() is called via _process or better yet, signals from GameState

func _on_back_pressed() -> void:
	
	hide()
	get_parent().get_node("ActivityBoard").show()
	get_parent().get_node("ActivityBoard").refresh_board()

func _setup_guide_text() -> void:
	guide_label.text = "\n\nACTIVITY GUIDE\n\n" + \
		"Activity Overview:\n" + \
		"Emergency Training is an investment in your team’s future performance. Assign team members to specialized programs to handle unexpected festival situations.\n\n" + \
		"Your Objective:\n" + \
		"Improve preparedness, strengthen critical performance, and balance benefits with cost/time constraints.\n\n" + \
		"Training Programs:\n" + \
		"• Electrical Failure: Handle power outages and technical failures.\n" + \
		"• Crowd Control: Manage large crowds and safely handle evacuations.\n" + \
		"• Medical Response: Respond to medical emergencies and provide assistance.\n" + \
		"• Crisis Management: Handle unforeseen problems and high-pressure situations.\n\n" + \
		"Key Rules:\n" + \
		"• TOTAL TIME LIMIT: Each member can train for a maximum of 4 minutes (240s).\n" + \
		"• IMPACT: Trained members complete related scenarios 50% FASTER during the festival.\n" + \
		"• Member status: Trainees are unavailable for other tasks while in session."

func _on_finish_pressed() -> void:
	GameState.finish_emergency_training()
	hide()
	get_parent().get_node("ActivityBoard").show()
	get_parent().get_node("ActivityBoard").refresh_board()
