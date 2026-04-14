extends Control

var vendor_options = {
	"burger_truck": {
		"display_name": "Gourmet Burgers",
		"cuisine_type": "American",
		"price": 1500,
		"service_capacity": 1800,
		"speed": "Normal", # Fast, Normal, Slow
		"hygiene_rating": 4.5,
		"electricity_requirement": 10,
		"space_requirement": 20
	},
	"taco_stand": {
		"display_name": "Taco Fiesta",
		"cuisine_type": "Mexican",
		"price": 800,
		"service_capacity": 1200,
		"speed": "Fast",
		"hygiene_rating": 3.8,
		"electricity_requirement": 5,
		"space_requirement": 15
	},
	"pizza_oven": {
		"display_name": "Woodfire Pizza",
		"cuisine_type": "Italian",
		"price": 2000,
		"service_capacity": 1400,
		"speed": "Slow",
		"hygiene_rating": 4.8,
		"electricity_requirement": 15,
		"space_requirement": 25
	},
	"sushi_cart": {
		"display_name": "Quick Sushi",
		"cuisine_type": "Japanese",
		"price": 1200,
		"service_capacity": 900,
		"speed": "Fast",
		"hygiene_rating": 4.9,
		"electricity_requirement": 8,
		"space_requirement": 10
	},
	"kebab_grill": {
		"display_name": "Street Kebabs",
		"cuisine_type": "Middle Eastern",
		"price": 900,
		"service_capacity": 1500,
		"speed": "Normal",
		"hygiene_rating": 2.1,
		"electricity_requirement": 5,
		"space_requirement": 20
	},
	"vegan_bowl": {
		"display_name": "Green Bowls",
		"cuisine_type": "Healthy/Vegan",
		"price": 1000,
		"service_capacity": 1000,
		"speed": "Normal",
		"hygiene_rating": 4.6,
		"electricity_requirement": 5,
		"space_requirement": 15
	}
}

# PLACEHOLDERS: Limits for resources
const MAX_SPACE: int = 100
const MAX_ELECTRICITY: int = 50

@onready var vendor_list: VBoxContainer = $MarginContainer/VBoxContainer/ContentPanel/MarginContainer/VendorList
@onready var capacity_label: Label = $MarginContainer/VBoxContainer/HeaderPanel/VBoxContainer/CapacityLabel
@onready var summary_label: Label = $MarginContainer/VBoxContainer/SummaryPanel/VBoxContainer/SummaryLabel
@onready var confirm_button: Button = $MarginContainer/VBoxContainer/ButtonRow/ConfirmButton

var option_checkboxes: Array = []

func _ready() -> void:
	confirm_button.pressed.connect(_on_confirm_pressed)
	create_options()
	refresh_ui()

func create_options() -> void:
	for c in vendor_list.get_children():
		c.queue_free()
	option_checkboxes.clear()

	for id in vendor_options.keys():
		var v_data = vendor_options[id]
		
		var card = PanelContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		var margin = MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 15)
		margin.add_theme_constant_override("margin_top", 10)
		margin.add_theme_constant_override("margin_right", 15)
		margin.add_theme_constant_override("margin_bottom", 10)
		card.add_child(margin)
		
		var hbox = HBoxContainer.new()
		margin.add_child(hbox)
		
		var cb = CheckBox.new()
		cb.text = "  " + v_data["display_name"]
		cb.set_meta("id", id)
		cb.toggled.connect(_on_option_toggled)
		
		if GameState.food_vendor_completed:
			cb.disabled = true
			if GameState.selected_food_vendors.has(id):
				cb.button_pressed = true
		
		option_checkboxes.append(cb)
		hbox.add_child(cb)
		
		var spacer = Control.new()
		spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(spacer)
		
		var details_label = Label.new()
		details_label.text = "Type: " + v_data["cuisine_type"] + " | Price: " + str(v_data["price"]) + " | Cap: " + str(v_data["service_capacity"]) + " | Speed: " + v_data["speed"] + " | Hyg: " + str(v_data["hygiene_rating"]) + " | Elec: " + str(v_data["electricity_requirement"]) + "kVA | Space: " + str(v_data["space_requirement"]) + "sqm"
		details_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		hbox.add_child(details_label)
		
		vendor_list.add_child(card)

func _on_option_toggled(_toggled_on: bool) -> void:
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
			
			total_capacity += v_data["service_capacity"]
			total_price += v_data["price"]
			total_hygiene += v_data["hygiene_rating"]
			total_electricity += v_data["electricity_requirement"]
			total_space += v_data["space_requirement"]
			
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
	capacity_label.text = "Limits - Space: " + str(MAX_SPACE) + " sqm | Electricity: " + str(MAX_ELECTRICITY) + " kVA"
	var data = get_totals()
	
	if GameState.food_vendor_completed:
		confirm_button.text = "Back to Board"
		confirm_button.disabled = false
		summary_label.text = "Selection Fixed! Cost: " + str(data["price"]) + " TL | Capacity: " + str(data["capacity"])
	else:
		confirm_button.text = "Confirm Selection"
		
		var warnings = []
		if data["budget_exceeded"]:
			warnings.append("OVER BUDGET!")
		if data["constraints_exceeded"]:
			warnings.append("OVER LIMITS (Space/Elec)!")
		if data["low_capacity"]:
			warnings.append("LOW CAPACITY!")
		if data["low_hygiene"]:
			warnings.append("BAD HYGIENE!")
		if data["low_diversity"]:
			warnings.append("POOR VARIETY!")
			
		var warning_text = ""
		if warnings.size() > 0:
			warning_text = "[WARNING: " + ", ".join(warnings) + "] "
			# Allow submission even if warnings exist, as per explicit user request
			
		summary_label.text = warning_text + "Cost: " + str(data["price"]) + " TL | Cap: " + str(data["capacity"]) + "/" + str(GameState.final_attendance) + " | Hyg: " + str(snapped(data["avg_hygiene"], 0.1)) + " | Elec: " + str(data["electricity"]) + " | Space: " + str(data["space"])
		
		# Confirm button stays enabled, warnings and penalties handle the UX
		confirm_button.disabled = false 

func _on_confirm_pressed() -> void:
	if GameState.food_vendor_completed:
		go_back()
		return
		
	var data = get_totals()
	GameState.finalize_food_vendor_selection(
		data["selected_ids"], 
		data["capacity"], 
		data["avg_hygiene"], 
		data["price"], 
		data["satisfaction_impact"], 
		data["quality_impact"]
	)
	go_back()

func go_back() -> void:
	hide()
	get_parent().get_node("ActivityBoard").show()
	get_parent().get_node("ActivityBoard").refresh_board()
