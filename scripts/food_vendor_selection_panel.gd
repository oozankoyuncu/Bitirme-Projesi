extends Control

var vendor_options = {
	"burger_truck": {
		"display_name": "Gourmet Burgers",
		"cuisine_type": "American",
		"revenue_per_sqm": 80,
		"cap_per_sqm": 90,
		"speed": "Normal", # Fast, Normal, Slow
		"hygiene_rating": 4.5,
		"electricity_requirement": 10,
		"min_space": 10,
		"max_space": 30
	},
	"taco_stand": {
		"display_name": "Taco Fiesta",
		"cuisine_type": "Mexican",
		"revenue_per_sqm": 60,
		"cap_per_sqm": 80,
		"speed": "Fast",
		"hygiene_rating": 3.8,
		"electricity_requirement": 5,
		"min_space": 10,
		"max_space": 20
	},
	"pizza_oven": {
		"display_name": "Woodfire Pizza",
		"cuisine_type": "Italian",
		"revenue_per_sqm": 100,
		"cap_per_sqm": 60,
		"speed": "Slow",
		"hygiene_rating": 4.8,
		"electricity_requirement": 15,
		"min_space": 15,
		"max_space": 35
	},
	"sushi_cart": {
		"display_name": "Quick Sushi",
		"cuisine_type": "Japanese",
		"revenue_per_sqm": 120,
		"cap_per_sqm": 90,
		"speed": "Fast",
		"hygiene_rating": 4.9,
		"electricity_requirement": 8,
		"min_space": 5,
		"max_space": 15
	},
	"kebab_grill": {
		"display_name": "Street Kebabs",
		"cuisine_type": "Middle Eastern",
		"revenue_per_sqm": 50,
		"cap_per_sqm": 75,
		"speed": "Normal",
		"hygiene_rating": 2.1,
		"electricity_requirement": 5,
		"min_space": 10,
		"max_space": 25
	},
	"vegan_bowl": {
		"display_name": "Green Bowls",
		"cuisine_type": "Healthy/Vegan",
		"revenue_per_sqm": 70,
		"cap_per_sqm": 65,
		"speed": "Normal",
		"hygiene_rating": 4.6,
		"electricity_requirement": 5,
		"min_space": 10,
		"max_space": 20
	}
}

# PLACEHOLDERS: Limits for resources
const MAX_SPACE: int = 100
const MAX_ELECTRICITY: int = 50

@onready var vendor_list: VBoxContainer = $MarginContainer/VBoxContainer/MainContent/LeftScroll/VendorList
@onready var budget_label: Label = $MarginContainer/VBoxContainer/MainContent/RightPanel/StatsPanel/MarginContainer/VBoxContainer/BudgetLabel
@onready var capacity_label: Label = $MarginContainer/VBoxContainer/MainContent/RightPanel/StatsPanel/MarginContainer/VBoxContainer/CapacityLabel
@onready var hygiene_label: Label = $MarginContainer/VBoxContainer/MainContent/RightPanel/StatsPanel/MarginContainer/VBoxContainer/HygieneLabel
@onready var electricity_label: Label = $MarginContainer/VBoxContainer/MainContent/RightPanel/StatsPanel/MarginContainer/VBoxContainer/ElectricityLabel
@onready var space_label: Label = $MarginContainer/VBoxContainer/MainContent/RightPanel/StatsPanel/MarginContainer/VBoxContainer/SpaceLabel
@onready var diversity_label: Label = $MarginContainer/VBoxContainer/MainContent/RightPanel/StatsPanel/MarginContainer/VBoxContainer/DiversityLabel
@onready var warning_label: Label = $MarginContainer/VBoxContainer/MainContent/RightPanel/StatsPanel/MarginContainer/VBoxContainer/WarningLabel
@onready var confirm_button: Button = $MarginContainer/VBoxContainer/MainContent/RightPanel/ConfirmButton

var option_checkboxes: Array = []
var space_sliders: Dictionary = {}

func _ready() -> void:
	confirm_button.pressed.connect(_on_confirm_pressed)
	_setup_ui_styles()
	create_options()
	refresh_ui()

func _setup_ui_styles() -> void:
	# Main Panel Glassmorphism
	var main_style = StyleBoxFlat.new()
	main_style.bg_color = Color(0.05, 0.07, 0.1, 0.95)
	main_style.border_width_left = 4
	main_style.border_color = Color(0.8, 0.4, 0.2)
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
	side_style.border_color = Color(0.4, 0.3, 0.2)
	$MarginContainer/VBoxContainer/MainContent/RightPanel/StatsPanel.add_theme_stylebox_override("panel", side_style)

func create_options() -> void:
	for c in vendor_list.get_children():
		c.queue_free()
	option_checkboxes.clear()

	for id in vendor_options.keys():
		var v_data = vendor_options[id]
		
		var card = PanelContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		var card_style = StyleBoxFlat.new()
		card_style.bg_color = Color(0.15, 0.18, 0.22, 0.8)
		card_style.corner_radius_top_left = 8
		card_style.corner_radius_top_right = 8
		card_style.corner_radius_bottom_right = 8
		card_style.corner_radius_bottom_left = 8
		card_style.border_width_left = 4
		card_style.border_color = Color(0.8, 0.4, 0.2)
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
		cb.text = "  " + v_data["display_name"]
		cb.add_theme_font_size_override("font_size", 20)
		cb.set_meta("id", id)
		cb.toggled.connect(func(toggled_on): _on_option_toggled(toggled_on, card, card_style))
		
		if GameState.food_vendor_completed:
			cb.disabled = true
			if GameState.selected_food_vendors.has(id):
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
		
		var top_label = Label.new()
		top_label.text = v_data["cuisine_type"] + " | Rev: " + str(v_data["revenue_per_sqm"]) + " TL/sqm | Cap: " + str(v_data["cap_per_sqm"]) + "/sqm"
		top_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		top_label.modulate = Color(1.0, 0.8, 0.6)
		details_vbox.add_child(top_label)
		
		var bottom_label = Label.new()
		bottom_label.text = "Hyg: " + str(v_data["hygiene_rating"]) + " | Speed: " + v_data["speed"] + " | Elec: " + str(v_data["electricity_requirement"]) + "kVA"
		bottom_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		bottom_label.modulate = Color(0.7, 0.7, 0.7)
		bottom_label.add_theme_font_size_override("font_size", 14)
		details_vbox.add_child(bottom_label)
		
		var slider_hbox = HBoxContainer.new()
		slider_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slider_hbox.alignment = BoxContainer.ALIGNMENT_END
		
		var slider_label = Label.new()
		slider_label.text = "Space: " + str(v_data["min_space"]) + " sqm"
		slider_label.add_theme_font_size_override("font_size", 14)
		slider_label.modulate = Color(0.8, 0.9, 1.0)
		
		var slider = HSlider.new()
		slider.min_value = v_data["min_space"]
		slider.max_value = v_data["max_space"]
		slider.step = 1
		slider.value = v_data["min_space"]
		slider.custom_minimum_size = Vector2(150, 20)
		slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		slider.visible = false
		slider_label.visible = false
		
		slider.value_changed.connect(func(val):
			slider_label.text = "Space: " + str(val) + " sqm"
			refresh_ui()
		)
		
		space_sliders[id] = slider
		
		slider_hbox.add_child(slider_label)
		slider_hbox.add_child(slider)
		details_vbox.add_child(slider_hbox)
		
		cb.toggled.connect(func(toggled_on): 
			slider.visible = toggled_on
			slider_label.visible = toggled_on
			_on_option_toggled(toggled_on, card, card_style)
		)
		
		vendor_list.add_child(card)

func _style_selected_card(style: StyleBoxFlat, selected: bool) -> void:
	if selected:
		style.bg_color = Color(0.4, 0.2, 0.1, 0.9)
		style.border_color = Color(1.0, 0.6, 0.2)
	else:
		style.bg_color = Color(0.15, 0.18, 0.22, 0.8)
		style.border_color = Color(0.8, 0.4, 0.2)

func _on_option_toggled(toggled_on: bool, card: PanelContainer, style: StyleBoxFlat) -> void:
	_style_selected_card(style, toggled_on)
	refresh_ui()

func get_totals() -> Dictionary:
	var selected_ids = []
	var total_capacity = 0
	var total_price = 0
	var total_hygiene = 0.0
	var total_electricity = 0
	var total_space = 0
	var cuisine_types = []
	var has_slow_speed = false
	
	for cb in option_checkboxes:
		if cb.button_pressed:
			var id = cb.get_meta("id")
			selected_ids.append(id)
			var v_data = vendor_options[id]
			var chosen_space = space_sliders[id].value
			
			total_capacity += chosen_space * v_data["cap_per_sqm"]
			total_price += chosen_space * v_data["revenue_per_sqm"] # this is revenue now!
			total_hygiene += v_data["hygiene_rating"]
			total_electricity += v_data["electricity_requirement"]
			total_space += chosen_space
			
			if v_data["speed"] == "Slow":
				has_slow_speed = true
			
			if not cuisine_types.has(v_data["cuisine_type"]):
				cuisine_types.append(v_data["cuisine_type"])
				
	var avg_hygiene = 0.0
	if selected_ids.size() > 0:
		avg_hygiene = total_hygiene / selected_ids.size()
		
	var diversity_count = cuisine_types.size()
	
	# Penalties calculation
	var satisfaction_impact = 0.0
	var quality_impact = 0.0
	
	var attendance = GameState.final_attendance
	if attendance > 0 and total_capacity < attendance:
		satisfaction_impact -= 5.0 # Penalty for low capacity
		
	if avg_hygiene > 0 and avg_hygiene < 2.5:
		quality_impact -= 10.0 # Extreme penalty for poor hygiene
		
	if selected_ids.size() > 0 and diversity_count < 2:
		satisfaction_impact -= 2.0 # Penalty for missing variety
		
	if has_slow_speed:
		satisfaction_impact -= 2.0 # Penalty for slow speed
		
	if total_space > MAX_SPACE or total_electricity > MAX_ELECTRICITY:
		quality_impact -= 3.0 # System overload / crowding penalty
		satisfaction_impact -= 2.0
		
	var constraints_exceeded = total_space > MAX_SPACE or total_electricity > MAX_ELECTRICITY
	var budget_exceeded = total_price > GameState.money
		
	return {
		"selected_ids": selected_ids,
		"capacity": total_capacity,
		"price": total_price,
		"avg_hygiene": avg_hygiene,
		"electricity": total_electricity,
		"space": total_space,
		"diversity_count": diversity_count,
		"satisfaction_impact": satisfaction_impact,
		"quality_impact": quality_impact,
		"constraints_exceeded": constraints_exceeded,
		"budget_exceeded": budget_exceeded,
		"low_capacity": attendance > 0 and total_capacity < attendance,
		"low_hygiene": avg_hygiene > 0 and avg_hygiene < 2.5,
		"low_diversity": selected_ids.size() > 0 and diversity_count < 2
	}

func refresh_ui() -> void:
	var data = get_totals()
	
	budget_label.text = "Revenue: +" + str(data["price"]) + " TL"
	capacity_label.text = "Capacity: " + str(data["capacity"]) + " / " + str(GameState.final_attendance)
	hygiene_label.text = "Avg Hygiene: " + str(snapped(data["avg_hygiene"], 0.1))
	electricity_label.text = "Electricity: " + str(data["electricity"]) + " / " + str(MAX_ELECTRICITY) + " kVA"
	space_label.text = "Space Used: " + str(data["space"]) + " / " + str(MAX_SPACE) + " sqm"
	diversity_label.text = "Diversity: " + str(data["diversity_count"]) + " types"
	
	if GameState.food_vendor_completed:
		confirm_button.text = "BACK TO BOARD"
		confirm_button.disabled = false
		warning_label.text = "Selection Fixed."
		warning_label.modulate = Color(0.4, 1.0, 0.4)
	else:
		confirm_button.text = "CONFIRM SELECTION"
		
		var warnings = []
		if data["budget_exceeded"]: warnings.append("OVER BUDGET")
		if data["constraints_exceeded"]: warnings.append("OVER LIMITS")
		if data["low_capacity"]: warnings.append("LOW CAPACITY")
		if data["low_hygiene"]: warnings.append("BAD HYGIENE")
		if data["low_diversity"]: warnings.append("POOR VARIETY")
			
		if warnings.size() > 0:
			warning_label.text = "WARNING: " + ", ".join(warnings)
			warning_label.modulate = Color(1.0, 0.2, 0.2)
		else:
			warning_label.text = "All constraints met."
			warning_label.modulate = Color(0.6, 0.6, 0.6)
			
		budget_label.modulate = Color(0.4, 1.0, 0.4) if data["price"] > 0 else Color.WHITE
		electricity_label.modulate = Color(1.0, 0.2, 0.2) if data["electricity"] > MAX_ELECTRICITY else Color.WHITE
		space_label.modulate = Color(1.0, 0.2, 0.2) if data["space"] > MAX_SPACE else Color.WHITE
		capacity_label.modulate = Color(1.0, 0.6, 0.2) if data["low_capacity"] else Color.WHITE
		hygiene_label.modulate = Color(1.0, 0.6, 0.2) if data["low_hygiene"] else Color.WHITE
		diversity_label.modulate = Color(1.0, 0.6, 0.2) if data["low_diversity"] else Color.WHITE
		
		# Confirm button stays enabled
		confirm_button.disabled = false 

func _on_confirm_pressed() -> void:
	if GameState.food_vendor_completed:
		go_back()
		return
		
	var data = get_totals()
	# Multiply revenue by -1 to ADD to money since finalize_food_vendor_selection subtracts it
	var revenue_as_negative_cost = -data["price"]
	GameState.finalize_food_vendor_selection(
		data["selected_ids"], 
		data["capacity"], 
		data["avg_hygiene"], 
		revenue_as_negative_cost, 
		data["satisfaction_impact"], 
		data["quality_impact"]
	)
	go_back()

func go_back() -> void:
	hide()
	get_parent().get_node("ActivityBoard").show()
	get_parent().get_node("ActivityBoard").refresh_board()
