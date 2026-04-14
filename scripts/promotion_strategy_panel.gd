extends Control

# Placeholder values according to instructions
var promotion_options = {
	"social_media": {
		"display_name": "Social Media",
		"cost": 1500,
		"expected_reach": 2000,
		"reliability": 0.8  # Actual = 1600
	},
	"influencers": {
		"display_name": "Influencers",
		"cost": 5000,
		"expected_reach": 8000,
		"reliability": 0.5  # Actual = 4000
	},
	"traditional_media": {
		"display_name": "Traditional Media",
		"cost": 3000,
		"expected_reach": 3000,
		"reliability": 0.95 # Actual = 2850
	}
}

@onready var promotion_list: VBoxContainer = $MarginContainer/VBoxContainer/ContentPanel/MarginContainer/PromotionList
@onready var budget_label: Label = $MarginContainer/VBoxContainer/HeaderPanel/VBoxContainer/BudgetLabel
@onready var summary_label: Label = $MarginContainer/VBoxContainer/SummaryPanel/VBoxContainer/SummaryLabel
@onready var confirm_button: Button = $MarginContainer/VBoxContainer/ButtonRow/ConfirmButton

var option_checkboxes: Array = []

func _ready() -> void:
	confirm_button.pressed.connect(_on_confirm_pressed)
	create_options()
	refresh_ui()

func create_options() -> void:
	for c in promotion_list.get_children():
		c.queue_free()
	option_checkboxes.clear()

	for id in promotion_options.keys():
		var p = promotion_options[id]
		
		var expected = p["expected_reach"]
		var rel = p["reliability"]
		var actual = expected * rel
		
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
		cb.toggled.connect(_on_option_toggled)
		if GameState.promotion_phase_completed:
			cb.disabled = true
		option_checkboxes.append(cb)
		hbox.add_child(cb)
		
		var spacer = Control.new()
		spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(spacer)
		
		var details_label = Label.new()
		# Format the label nicely
		details_label.text = "Cost: " + str(p["cost"]) + " TL   |   Expected: " + str(expected) + "   |   Reliability: " + str(rel*100) + "%   =>   Actual: " + str(actual)
		details_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		hbox.add_child(details_label)
		
		promotion_list.add_child(card)

func _on_option_toggled(_toggled_on: bool) -> void:
	refresh_ui()

func get_totals() -> Dictionary:
	var total_cost: int = 0
	var total_actual_reach: float = 0.0
	var selected_ids: Array = []
	
	for cb in option_checkboxes:
		if cb.button_pressed:
			var id = cb.get_meta("id")
			selected_ids.append(id)
			total_cost += promotion_options[id]["cost"]
			total_actual_reach += promotion_options[id]["expected_reach"] * promotion_options[id]["reliability"]

	return {
		"cost": total_cost,
		"reach": total_actual_reach,
		"selected": selected_ids
	}

func refresh_ui() -> void:
	var data = get_totals()
	budget_label.text = "Current Game Budget: " + str(GameState.money) + " TL"
	summary_label.text = "Selected Cost: " + str(data["cost"]) + " TL     |     Combined Actual Reach: " + str(data["reach"])
	
	if GameState.promotion_phase_completed:
		confirm_button.text = "Back to Board"
		confirm_button.disabled = false
	else:
		confirm_button.text = "Confirm Strategy"
		if GameState.money - data["cost"] < GameState.university_debt_limit:
			confirm_button.disabled = true
			summary_label.text += "\n[Cannot afford! Over debt limit]"
		else:
			confirm_button.disabled = false

func _on_confirm_pressed() -> void:
	if GameState.promotion_phase_completed:
		go_back()
		return
		
	var data = get_totals()
	
	if GameState.money - data["cost"] < GameState.university_debt_limit:
		return
		
	GameState.finalize_promotion_strategy(data["selected"], data["cost"], data["reach"])
	go_back()

func go_back() -> void:
	hide()
	get_parent().get_node("ActivityBoard").show()
	get_parent().get_node("ActivityBoard").refresh_board()
