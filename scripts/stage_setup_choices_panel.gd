extends Control

@onready var option_list: VBoxContainer = $MarginContainer/VBoxContainer/OptionList
@onready var info_label: Label = $MarginContainer/VBoxContainer/InfoLabel
@onready var result_label: Label = $MarginContainer/VBoxContainer/ResultLabel
@onready var money_label: Label = $MarginContainer/VBoxContainer/MoneyLabel
@onready var confirm_button: Button = $MarginContainer/VBoxContainer/ButtonsRow/ConfirmButton
@onready var back_button: Button = $MarginContainer/VBoxContainer/ButtonsRow/BackButton

var selected_stage_id: String = ""

func _ready() -> void:
	confirm_button.pressed.connect(_on_confirm_pressed)
	back_button.pressed.connect(_on_back_pressed)
	build_options()
	print("stage_setup_defs: ", GameState.stage_setup_defs)
	print("count: ", GameState.stage_setup_defs.size())
	refresh_ui()

func build_options() -> void:
	for child in option_list.get_children():
		child.queue_free()

	for stage_data in GameState.stage_setup_defs:
		var checkbox := CheckBox.new()
		var impact := GameState.calculate_stage_impact(stage_data)

		checkbox.text = stage_data["name"] + \
			" | Cost: $" + str(stage_data["cost"]) + \
			" | Size: " + str(stage_data["stage_size"]) + \
			" | Lighting: " + str(stage_data["lighting_complexity"]) + \
			" | Features: " + str(stage_data["operation_features"]) + \
			" | Setup: " + str(stage_data["setup_duration"]) + " week" + \
			" | Impact: " + str(snapped(impact, 0.1))

		checkbox.set_meta("stage_data", stage_data)
		checkbox.toggled.connect(func(pressed: bool): _on_stage_toggled(checkbox, pressed))
		option_list.add_child(checkbox)

func _on_stage_toggled(changed_checkbox: CheckBox, pressed: bool) -> void:
	if not pressed:
		if changed_checkbox.get_meta("stage_data")["id"] == selected_stage_id:
			selected_stage_id = ""
			info_label.text = "No stage selected."
		return

	for child in option_list.get_children():
		if child is CheckBox and child != changed_checkbox:
			child.button_pressed = false

	var stage_data: Dictionary = changed_checkbox.get_meta("stage_data")
	selected_stage_id = stage_data["id"]

	var impact := GameState.calculate_stage_impact(stage_data)
	info_label.text = \
		"Selected: " + stage_data["name"] + "\n" + \
		"Cost: $" + str(stage_data["cost"]) + "\n" + \
		"Stage Size: " + str(stage_data["stage_size"]) + "\n" + \
		"Lighting Complexity: " + str(stage_data["lighting_complexity"]) + "\n" + \
		"Operation Features: " + str(stage_data["operation_features"]) + "\n" + \
		"Setup Duration: " + str(stage_data["setup_duration"]) + " week\n" + \
		"Impact Score: " + str(snapped(impact, 0.1))

func _on_confirm_pressed() -> void:
	if selected_stage_id == "":
		result_label.text = "Please select one stage setup."
		return

	var selected_data: Dictionary = {}
	for stage_data in GameState.stage_setup_defs:
		if stage_data["id"] == selected_stage_id:
			selected_data = stage_data
			break

	if selected_data.is_empty():
		result_label.text = "Stage data not found."
		return

	var ok := GameState.choose_stage_setup(selected_data)
	if not ok:
		result_label.text = "Not enough budget for this stage setup."
		return

	GameState.complete_activity("stage_setup_choices")
	result_label.text = "Stage setup selected successfully."
	refresh_ui()

	hide()
	get_parent().get_node("ActivityBoard").show()
	get_parent().get_node("ActivityBoard").refresh_board()

func refresh_ui() -> void:
	money_label.text = "Money: $" + str(GameState.money)

func _on_back_pressed() -> void:
	hide()
	get_parent().get_node("ActivityBoard").show()
	get_parent().get_node("ActivityBoard").refresh_board()
