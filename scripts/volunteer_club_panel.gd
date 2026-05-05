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

func _ready() -> void:
	confirm_button.pressed.connect(_on_confirm_pressed)
	_setup_ui_styles()
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
		req_label.add_theme_font_size_override("font_size", 14)
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
