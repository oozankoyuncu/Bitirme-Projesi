extends Control

var pricing_options = {
	"low_price": {
		"display_name": "Low Price Strategy",
		"ticket_price": 300,
		"expected_attendance_impact": 0.20,
		"perceived_value": 0
	},
	"balanced": {
		"display_name": "Balanced Pricing",
		"ticket_price": 500,
		"expected_attendance_impact": 0.0,
		"perceived_value": 1
	},
	"premium": {
		"display_name": "Premium Pricing",
		"ticket_price": 1000,
		"expected_attendance_impact": -0.30,
		"perceived_value": 3
	}
}

@onready var pricing_list: VBoxContainer = $MarginContainer/VBoxContainer/ContentPanel/MarginContainer/PricingList
@onready var base_reach_label: Label = $MarginContainer/VBoxContainer/HeaderPanel/VBoxContainer/BaseReachLabel
@onready var summary_label: Label = $MarginContainer/VBoxContainer/SummaryPanel/VBoxContainer/SummaryLabel
@onready var confirm_button: Button = $MarginContainer/VBoxContainer/ButtonRow/ConfirmButton

var option_checkboxes: Array = []

func _ready() -> void:
	confirm_button.pressed.connect(_on_confirm_pressed)
	create_options()
	refresh_ui()

func create_options() -> void:
	for c in pricing_list.get_children():
		c.queue_free()
	option_checkboxes.clear()

	var bg = ButtonGroup.new()

	for id in pricing_options.keys():
		var p = pricing_options[id]
		
		var price = p["ticket_price"]
		var impact = p["expected_attendance_impact"]
		var val = p["perceived_value"]
		
		var card = PanelContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		var margin = MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 15)
		margin.add_theme_constant_override("margin_top", 15)
		margin.add_theme_constant_override("margin_right", 15)
		margin.add_theme_constant_override("margin_bottom", 15)
		card.add_child(margin)
		
		var hbox = HBoxContainer.new()
		margin.add_child(hbox)
		
		var cb = CheckBox.new()
		cb.text = "   " + p["display_name"]
		cb.set_meta("id", id)
		cb.button_group = bg  # Provides automatic single-select radio behavior
		cb.toggled.connect(_on_option_toggled)
		if GameState.ticket_pricing_completed:
			cb.disabled = true
			if GameState.chosen_ticket_price == price:
				cb.button_pressed = true
		
		option_checkboxes.append(cb)
		hbox.add_child(cb)
		
		var spacer = Control.new()
		spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(spacer)
		
		var details_label = Label.new()
		
		var impact_str = str(impact * 100) + "%"
		if impact > 0:
			impact_str = "+" + impact_str
			
		details_label.text = "Ticket Price: " + str(price) + " TL   |   Impact on Attendance: " + impact_str + "   |   Event Quality: +" + str(val)
		details_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		hbox.add_child(details_label)
		
		pricing_list.add_child(card)

func _on_option_toggled(_toggled_on: bool) -> void:
	refresh_ui()

func get_selected_id() -> String:
	for cb in option_checkboxes:
		if cb.button_pressed:
			return cb.get_meta("id")
	return ""

func get_totals() -> Dictionary:
	var id = get_selected_id()
	
	var base_reach = GameState.promotion_total_actual_reach
	# If testing early, set base_reach artificially to avoid 0
	if base_reach <= 0.0:
		base_reach = 5000.0  # fallback debug number
		
	if id == "":
		return {
			"selected": false,
			"attendance": base_reach,
			"price": 0,
			"revenue": 0,
			"quality": 0
		}
		
	var p = pricing_options[id]
	var impact = p["expected_attendance_impact"]
	var adj_attendance = base_reach * (1.0 + impact)
	var revenue = adj_attendance * p["ticket_price"]
	var qual = p["perceived_value"]

	return {
		"selected": true,
		"id": id,
		"attendance": adj_attendance,
		"price": p["ticket_price"],
		"revenue": revenue,
		"quality": qual
	}

func refresh_ui() -> void:
	var base_reach = GameState.promotion_total_actual_reach
	if base_reach <= 0.0:
		base_reach = 5000.0
		
	base_reach_label.text = "Base Initial Attendance (From Promotion): " + str(base_reach)
	
	var data = get_totals()
	
	if GameState.ticket_pricing_completed:
		summary_label.text = "Pricing Fixed! Adjusted Attendance: " + str(data["attendance"]) + "   |   Estimated Revenue: " + str(data["revenue"]) + " TL"
		confirm_button.text = "Back to Board"
		confirm_button.disabled = false
	else:
		confirm_button.text = "Confirm Strategy"
		if not data["selected"]:
			summary_label.text = "Please select a pricing strategy..."
			confirm_button.disabled = true
		else:
			summary_label.text = "Adjusted Attendance: " + str(data["attendance"]) + "   |   Estimated Revenue: " + str(data["revenue"]) + " TL"
			confirm_button.disabled = false

func _on_confirm_pressed() -> void:
	if GameState.ticket_pricing_completed:
		go_back()
		return
		
	var data = get_totals()
	if not data["selected"]:
		return
		
	GameState.finalize_ticket_pricing(data["attendance"], data["price"], data["revenue"], data["quality"])
	go_back()

func go_back() -> void:
	hide()
	get_parent().get_node("ActivityBoard").show()
	get_parent().get_node("ActivityBoard").refresh_board()
