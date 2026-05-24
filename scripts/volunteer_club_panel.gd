extends Control

var club_options = {
	"art_club": {
		"display_name": "University Art Club",
		"activity_type": "Artistic",
		"engagement_level": 10,
		"space_requirement": 50,
		"operational_needs": "Covered Tent"
	},
	"esports_club": {
		"display_name": "E-Sports Society",
		"activity_type": "Interactive",
		"engagement_level": 20,
		"space_requirement": 60,
		"operational_needs": "Electricity, Internet"
	},
	"dance_troupe": {
		"display_name": "Modern Dance Troupe",
		"activity_type": "Performance",
		"engagement_level": 15,
		"space_requirement": 80,
		"operational_needs": "Open Floor, Audio"
	},
	"tech_club": {
		"display_name": "Tech Innovators",
		"activity_type": "Informational",
		"engagement_level": 5,
		"space_requirement": 40,
		"operational_needs": "Electricity"
	},
	"sports_team": {
		"display_name": "Athletics Mini-Games",
		"activity_type": "Competitive",
		"engagement_level": 15,
		"space_requirement": 100,
		"operational_needs": "Open Space"
	}
}

# PLACEHOLDER: Maximum space allowed for volunteer/club booths.
# Update this to match real area capacities when fully designed.
const MAX_SPACE: int = 200

@onready var club_list: VBoxContainer = $MarginContainer/VBoxContainer/MainContent/LeftScroll/ClubList
@onready var capacity_label: Label = $MarginContainer/VBoxContainer/MainContent/RightPanel/StatsPanel/MarginContainer/VBoxContainer/CapacityLabel
@onready var engagement_label: Label = $MarginContainer/VBoxContainer/MainContent/RightPanel/StatsPanel/MarginContainer/VBoxContainer/EngagementLabel
@onready var types_label: Label = $MarginContainer/VBoxContainer/MainContent/RightPanel/StatsPanel/MarginContainer/VBoxContainer/TypesLabel
@onready var warning_label: Label = $MarginContainer/VBoxContainer/MainContent/RightPanel/StatsPanel/MarginContainer/VBoxContainer/WarningLabel
@onready var confirm_button: Button = $MarginContainer/VBoxContainer/MainContent/RightPanel/ConfirmButton

var option_checkboxes: Array = []
var guide_panel: PanelContainer
var guide_label: Label
var info_button: Button

func _ready() -> void:
	confirm_button.pressed.connect(_on_confirm_pressed)
	visibility_changed.connect(_on_visibility_changed)
	_setup_ui_styles()
	_setup_guide_ui()
	_setup_guide_text()
	create_options()
	
	# Add Go to Layout button at the top
	var top_vbox = $MarginContainer/VBoxContainer
	
	var layout_btn_container = CenterContainer.new()
	layout_btn_container.custom_minimum_size = Vector2(0, 80)
	top_vbox.add_child(layout_btn_container)
	top_vbox.move_child(layout_btn_container, 1) # Put it below the header but above main content
	
	var go_to_layout_btn = Button.new()
	go_to_layout_btn.text = "📍 GO TO INITIAL LAYOUT MAPPING (REVIEW CAPACITY)"
	go_to_layout_btn.add_theme_font_size_override("font_size", 24)
	go_to_layout_btn.custom_minimum_size = Vector2(600, 70)
	
	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = Color(0.1, 0.5, 0.25, 0.9) # Bright Green
	btn_style.border_width_left = 4
	btn_style.border_width_top = 4
	btn_style.border_width_right = 4
	btn_style.border_width_bottom = 4
	btn_style.border_color = Color(0.4, 0.8, 0.5, 1.0)
	btn_style.set_corner_radius_all(12)
	
	var btn_hover = btn_style.duplicate()
	btn_hover.bg_color = Color(0.15, 0.7, 0.35, 1.0)
	
	go_to_layout_btn.add_theme_stylebox_override("normal", btn_style)
	go_to_layout_btn.add_theme_stylebox_override("hover", btn_hover)
	go_to_layout_btn.add_theme_stylebox_override("pressed", btn_style)
	
	go_to_layout_btn.pressed.connect(_on_go_to_layout_pressed)
	layout_btn_container.add_child(go_to_layout_btn)
	
	refresh_ui()

func _setup_ui_styles() -> void:
	# Main Panel Glassmorphism
	var main_style = StyleBoxFlat.new()
	main_style.bg_color = Color(0.05, 0.07, 0.1, 0.95)
	main_style.border_width_left = 4
	main_style.border_color = Color(0.2, 0.6, 0.8)
	add_theme_stylebox_override("panel", main_style)

	# Stats Panel
	var side_style = StyleBoxFlat.new()
	side_style.bg_color = Color(0.1, 0.12, 0.15, 0.8)
	side_style.corner_radius_top_left = 10
	side_style.corner_radius_top_right = 10
	side_style.corner_radius_bottom_right = 10
	side_style.corner_radius_bottom_left = 10
	side_style.border_width_left = 1
	side_style.border_width_top = 1
	side_style.border_width_right = 1
	side_style.border_width_bottom = 1
	side_style.border_color = Color(0.3, 0.4, 0.5)
	$MarginContainer/VBoxContainer/MainContent/RightPanel/StatsPanel.add_theme_stylebox_override("panel", side_style)
	
	var expl_label = Label.new()
	expl_label.text = "\nEngagement Level: Represents the enthusiasm and energy volunteers bring to the festival. Higher engagement increases the overall Event Quality and brings life to your festival."
	expl_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	expl_label.add_theme_font_size_override("font_size", 16)
	expl_label.modulate = Color(0.7, 0.9, 1.0)
	
	var container = $MarginContainer/VBoxContainer/MainContent/RightPanel/StatsPanel/MarginContainer/VBoxContainer
	container.add_child(expl_label)
	container.move_child(expl_label, container.get_child_count() - 2)

func _setup_guide_ui() -> void:
	var header = $MarginContainer/VBoxContainer/Header
	
	info_button = Button.new()
	info_button.text = "?"
	info_button.custom_minimum_size = Vector2(40, 40)
	header.add_child(info_button)
	
	guide_panel = PanelContainer.new()
	guide_panel.visible = false
	guide_panel.set_anchors_preset(Control.PRESET_CENTER)
	guide_panel.custom_minimum_size = Vector2(800, 600)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.10, 0.14, 1.0)
	style.set_corner_radius_all(12)
	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 3
	style.border_color = Color(0.15, 0.55, 0.9, 0.8)
	style.shadow_color = Color(0, 0, 0, 0.6)
	style.shadow_size = 20
	guide_panel.add_theme_stylebox_override("panel", style)
	
	var g_margin = MarginContainer.new()
	g_margin.add_theme_constant_override("margin_left", 20)
	g_margin.add_theme_constant_override("margin_right", 20)
	g_margin.add_theme_constant_override("margin_top", 20)
	g_margin.add_theme_constant_override("margin_bottom", 20)
	guide_panel.add_child(g_margin)
	
	var g_vbox = VBoxContainer.new()
	g_margin.add_child(g_vbox)
	
	var g_header = HBoxContainer.new()
	g_vbox.add_child(g_header)
	
	var g_title = Label.new()
	g_title.text = "ACTIVITY GUIDE"
	g_title.add_theme_font_size_override("font_size", 24)
	g_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	g_header.add_child(g_title)
	
	var close_btn = Button.new()
	close_btn.text = "X"
	close_btn.custom_minimum_size = Vector2(40, 40)
	g_header.add_child(close_btn)
	
	var g_sep = HSeparator.new()
	g_vbox.add_child(g_sep)
	
	var g_scroll = ScrollContainer.new()
	g_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	g_vbox.add_child(g_scroll)
	
	guide_label = Label.new()
	guide_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	guide_label.custom_minimum_size = Vector2(740, 0)
	g_scroll.add_child(guide_label)
	
	add_child(guide_panel)
	
	guide_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	
	info_button.pressed.connect(func():
		guide_panel.show()
		guide_panel.position = (size - guide_panel.size) / 2
	)
	close_btn.pressed.connect(func(): guide_panel.hide())

func _setup_guide_text() -> void:
	guide_label.text = "ACTIVITY GUIDE: VOLUNTEER & CLUB RECRUITMENT\n\n" + \
		"What You Need to Pay Attention To:\n" + \
		"• Capacity Constraints: Selected participants must fit within the available 200 sqm area limit. If you exceed this capacity, your festival will become overcrowded and you will face severe penalties to Event Quality.\n" + \
		"• Diversity: Try to pick clubs with different Activity Types (e.g., Artistic, Interactive, Competitive). Selecting only one type limits the festival's appeal.\n\n" + \
		"How You Gather Points & Impact Success:\n" + \
		"• Engagement Contribution: Each selected participant adds an 'Engagement Level' score. The more total Engagement you have, the higher your Event Quality and Participant Satisfaction will be.\n" + \
		"• Diversity Bonus: Mixing different types of clubs provides a multiplier to your Event Quality score. A diverse festival is a successful festival.\n" + \
		"• Strategic Rule: Maximize Engagement and Diversity WITHOUT exceeding the 200 sqm limit."

var scenario_timer_active = false
func _on_visibility_changed() -> void:
	if visible:
		if not GameState.triggered_scenarios.has("volunteer_club_event") and not GameState.volunteer_club_completed and not scenario_timer_active:
			scenario_timer_active = true
			_start_scenario_timer()

func _start_scenario_timer() -> void:
	await get_tree().create_timer(1.0).timeout
	if not is_inside_tree() or not is_visible_in_tree() or GameState.triggered_scenarios.has("volunteer_club_event"):
		scenario_timer_active = false
		return
		
	GameState.triggered_scenarios.append("volunteer_club_event")
	var is_increase = randf() > 0.5
	
	if is_increase:
		club_options["photo_club"] = {
			"display_name": "Photography Society",
			"activity_type": "Artistic",
			"engagement_level": 12,
			"space_requirement": 40,
			"operational_needs": "Display Boards"
		}
		club_options["robotics_club"] = {
			"display_name": "Robotics Club",
			"activity_type": "Informational",
			"engagement_level": 18,
			"space_requirement": 50,
			"operational_needs": "Electricity, Tables"
		}
	else:
		var keys = club_options.keys()
		keys.shuffle()
		club_options.erase(keys[0])
		club_options.erase(keys[1])
		
	create_options()
	refresh_ui()

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
	p_style.border_color = Color(0.2, 0.9, 0.4, 1.0) if is_increase else Color(1.0, 0.4, 0.3, 1.0)
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
	title.text = "🎉 GREAT NEWS 🎉" if is_increase else "⚠️ BAD NEWS ⚠️"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 38)
	title.add_theme_color_override("font_color", Color(0.2, 1.0, 0.4) if is_increase else Color(1.0, 0.4, 0.3))
	vbox.add_child(title)
	
	var sep = HSeparator.new()
	vbox.add_child(sep)
	
	var body = Label.new()
	if is_increase:
		body.text = "Because your festival is becoming very popular on campus, two additional clubs (Photography Society & Robotics Club) have requested to participate!\n\nYou can now include them in your festival."
	else:
		body.text = "Due to the upcoming mid-term exam week, two clubs have withdrawn their participation to focus on studying.\n\nThey have been removed from your selection pool."
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
	b_style.bg_color = Color(0.15, 0.6, 0.25) if is_increase else Color(0.8, 0.3, 0.2)
	b_style.set_corner_radius_all(10)
	btn.add_theme_stylebox_override("normal", b_style)
	var b_hover = b_style.duplicate()
	b_hover.bg_color = Color(0.2, 0.75, 0.35) if is_increase else Color(0.9, 0.4, 0.3)
	btn.add_theme_stylebox_override("hover", b_hover)
	btn.add_theme_font_size_override("font_size", 22)
	
	btn.pressed.connect(func():
		var out_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN)
		out_tween.tween_property(overlay, "modulate:a", 0.0, 0.2)
		out_tween.tween_property(panel, "scale", Vector2(0.8, 0.8), 0.2)
		out_tween.chain().tween_callback(func():
			overlay.queue_free()
		)
	)
	vbox.add_child(btn)
	
	overlay.modulate.a = 0.0
	panel.scale = Vector2(0.8, 0.8)
	var in_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	in_tween.tween_property(overlay, "modulate:a", 1.0, 0.4)
	in_tween.tween_property(panel, "scale", Vector2(1.0, 1.0), 0.4)
	
	add_child(overlay)

func create_options() -> void:
	for c in club_list.get_children():
		c.queue_free()
	option_checkboxes.clear()

	for id in club_options.keys():
		var c_data = club_options[id]
		
		var card = PanelContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		var card_style = StyleBoxFlat.new()
		card_style.bg_color = Color(0.15, 0.18, 0.22, 0.8)
		card_style.corner_radius_top_left = 8
		card_style.corner_radius_top_right = 8
		card_style.corner_radius_bottom_right = 8
		card_style.corner_radius_bottom_left = 8
		card_style.border_width_left = 4
		card_style.border_color = Color(0.2, 0.6, 0.8)
		card.add_theme_stylebox_override("panel", card_style)
		
		var margin = MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 20)
		margin.add_theme_constant_override("margin_top", 15)
		margin.add_theme_constant_override("margin_right", 20)
		margin.add_theme_constant_override("margin_bottom", 15)
		card.add_child(margin)
		
		var hbox = HBoxContainer.new()
		margin.add_child(hbox)
		
		var cb = CheckBox.new()
		cb.text = "  " + c_data["display_name"]
		cb.add_theme_font_size_override("font_size", 20)
		cb.set_meta("id", id)
		cb.toggled.connect(func(toggled_on): _on_option_toggled(toggled_on, card, card_style))
		
		if GameState.volunteer_club_completed:
			cb.disabled = true
			if GameState.selected_volunteer_clubs.has(id):
				cb.button_pressed = true
				_style_selected_card(card_style, true)
		
		option_checkboxes.append(cb)
		hbox.add_child(cb)
		
		var spacer = Control.new()
		spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(spacer)
		
		var details_vbox = VBoxContainer.new()
		details_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		hbox.add_child(details_vbox)
		
		var type_label = Label.new()
		type_label.text = c_data["activity_type"] + " | +" + str(c_data["engagement_level"]) + " Eng."
		type_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		type_label.modulate = Color(0.6, 0.8, 1.0)
		details_vbox.add_child(type_label)
		
		var req_label = Label.new()
		req_label.text = str(c_data["space_requirement"]) + " sqm | " + c_data["operational_needs"]
		req_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		req_label.modulate = Color(0.7, 0.7, 0.7)
		req_label.add_theme_font_size_override("font_size", 18)
		details_vbox.add_child(req_label)
		
		club_list.add_child(card)

func _style_selected_card(style: StyleBoxFlat, selected: bool) -> void:
	if selected:
		style.bg_color = Color(0.2, 0.3, 0.4, 0.9)
		style.border_color = Color(0.4, 0.8, 1.0)
	else:
		style.bg_color = Color(0.15, 0.18, 0.22, 0.8)
		style.border_color = Color(0.2, 0.6, 0.8)

func _on_option_toggled(toggled_on: bool, card: PanelContainer, style: StyleBoxFlat) -> void:
	_style_selected_card(style, toggled_on)
	refresh_ui()

func get_totals() -> Dictionary:
	var selected_ids = []
	var total_space = 0
	var total_engagement = 0
	var types = []
	
	for cb in option_checkboxes:
		if cb.button_pressed:
			var id = cb.get_meta("id")
			selected_ids.append(id)
			var c_data = club_options[id]
			total_space += c_data["space_requirement"]
			total_engagement += c_data["engagement_level"]
			
			if not types.has(c_data["activity_type"]):
				types.append(c_data["activity_type"])
				
	var diversity_effect = types.size()
	
	# Base impact from engagement, scaled down
	var quality_impact = (total_engagement / 10.0)
	
	# Bonus impact from variety
	quality_impact += (diversity_effect * 0.5)
	
	var space_penalty = 0.0
	
	if total_space > MAX_SPACE:
		space_penalty = -2.0 # Fixed penalty if exceeding limits
		quality_impact += space_penalty
		
	return {
		"selected_ids": selected_ids,
		"space": total_space,
		"engagement": total_engagement,
		"diversity_effect": diversity_effect,
		"quality_impact": quality_impact,
		"space_exceeded": total_space > MAX_SPACE
	}

func refresh_ui() -> void:
	var data = get_totals()
	
	capacity_label.text = "Space Used: " + str(data["space"]) + " / " + str(MAX_SPACE) + " sqm"
	engagement_label.text = "Total Engagement: +" + str(data["engagement"])
	types_label.text = "Diversity (Types): " + str(data["diversity_effect"])
	
	if GameState.volunteer_club_completed:
		confirm_button.text = "BACK TO BOARD"
		confirm_button.disabled = false
		warning_label.text = "Selection Fixed."
		warning_label.modulate = Color(0.4, 1.0, 0.4)
	else:
		confirm_button.text = "CONFIRM SELECTION"
		
		if data["space_exceeded"]:
			warning_label.text = "WARNING: Over Capacity! Penalty will be applied."
			warning_label.modulate = Color(1.0, 0.2, 0.2)
			capacity_label.modulate = Color(1.0, 0.2, 0.2)
		else:
			warning_label.text = "Space is within limits."
			warning_label.modulate = Color(0.6, 0.6, 0.6)
			capacity_label.modulate = Color.WHITE
		
		confirm_button.disabled = false

func _on_confirm_pressed() -> void:
	if GameState.volunteer_club_completed:
		go_back()
		return
		
	var data = get_totals()
	GameState.finalize_volunteer_club(data["selected_ids"], data["space"], data["engagement"], data["diversity_effect"], data["quality_impact"])
	go_back()

func go_back() -> void:
	hide()
	get_parent().get_node("ActivityBoard").show()
	get_parent().get_node("ActivityBoard").refresh_board()

func _on_go_to_layout_pressed() -> void:
	hide()
	var layout_panel = get_parent().get_node("InitialFacilityLayoutPanel")
	if layout_panel and layout_panel.has_method("open_from_volunteer"):
		layout_panel.open_from_volunteer()
