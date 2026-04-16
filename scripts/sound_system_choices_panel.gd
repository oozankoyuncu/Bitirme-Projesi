extends Control

@onready var option_list: VBoxContainer = $MarginContainer/VBoxContainer/OptionList
@onready var info_label: Label = $MarginContainer/VBoxContainer/InfoLabel
@onready var result_label: Label = $MarginContainer/VBoxContainer/ResultLabel
@onready var money_label: Label = $MarginContainer/VBoxContainer/MoneyLabel
@onready var confirm_button: Button = $MarginContainer/VBoxContainer/ButtonsRow/ConfirmButton
@onready var back_button: Button = $MarginContainer/VBoxContainer/ButtonsRow/BackButton

var selected_system_id: String = ""

func _ready() -> void:
	confirm_button.pressed.connect(_on_confirm_pressed)
	back_button.pressed.connect(_on_back_pressed)
	visibility_changed.connect(_on_visibility_changed)

	# --- Estetik / UX Ayarları ---
	var title: Label = $MarginContainer/VBoxContainer/TitleLabel
	title.add_theme_font_size_override("font_size", 32)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	var desc: Label = $MarginContainer/VBoxContainer/DescriptionLabel
	desc.add_theme_font_size_override("font_size", 20)
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	money_label.add_theme_font_size_override("font_size", 24)
	money_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	info_label.add_theme_font_size_override("font_size", 20)
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	result_label.add_theme_font_size_override("font_size", 22)
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	var buttons_row: HBoxContainer = $MarginContainer/VBoxContainer/ButtonsRow
	buttons_row.alignment = BoxContainer.ALIGNMENT_CENTER
	
	confirm_button.add_theme_font_size_override("font_size", 20)
	back_button.add_theme_font_size_override("font_size", 20)
	
	option_list.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	option_list.alignment = BoxContainer.ALIGNMENT_CENTER
	
	# MarginContainer margins
	var margin: MarginContainer = $MarginContainer
	margin.add_theme_constant_override("margin_top", 60)
	margin.add_theme_constant_override("margin_bottom", 60)
	margin.add_theme_constant_override("margin_left", 60)
	margin.add_theme_constant_override("margin_right", 60)
	
	$MarginContainer/VBoxContainer.add_theme_constant_override("separation", 20)
	# ----------------------------

	build_options()
	refresh_ui()

func build_options() -> void:
	for child in option_list.get_children():
		child.queue_free()

	for system_data in GameState.sound_system_defs:
		var container = VBoxContainer.new()
		var checkbox := CheckBox.new()
		var impact := GameState.calculate_sound_system_impact(system_data)

		checkbox.text = " " + system_data["name"] + "  (Cost: $" + str(system_data["cost"]) + ")"
		checkbox.add_theme_font_size_override("font_size", 26)
		checkbox.set_meta("system_data", system_data)
		checkbox.toggled.connect(func(pressed: bool): _on_system_toggled(checkbox, pressed))
		
		var details := Label.new()
		details.text = "      ↳ Quality: %d/10   |   Tech Skill: %d/10   |   Electricity: %d   |   Score: %.1f" % [
			system_data["sound_quality"],
			system_data["technical_skill_level"],
			system_data["electricity_consumption"],
			impact
		]
		details.add_theme_font_size_override("font_size", 18)
		details.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))

		container.add_child(checkbox)
		container.add_child(details)
		
		var spacer = Control.new()
		spacer.custom_minimum_size = Vector2(0, 8)
		container.add_child(spacer)

		option_list.add_child(container)

func _on_system_toggled(changed_checkbox: CheckBox, pressed: bool) -> void:
	if not pressed:
		if changed_checkbox.get_meta("system_data")["id"] == selected_system_id:
			selected_system_id = ""
			info_label.text = "Please select a system from the list..."
		return

	for container in option_list.get_children():
		for child in container.get_children():
			if child is CheckBox and child != changed_checkbox:
				child.button_pressed = false

	var system_data: Dictionary = changed_checkbox.get_meta("system_data")
	selected_system_id = system_data["id"]

	var impact := GameState.calculate_sound_system_impact(system_data)
	info_label.text = \
		"=== SELECTED: " + system_data["name"].to_upper() + " ===\n" + \
		"Budget Cost: $" + str(system_data["cost"]) + "\n" + \
		"Sound Quality Rating: " + str(system_data["sound_quality"]) + " / 10\n" + \
		"Required Tech Skill: " + str(system_data["technical_skill_level"]) + " / 10\n" + \
		"Electricity Consumption: " + str(system_data["electricity_consumption"]) + " / 10\n" + \
		"Installation Phase: " + str(system_data["setup_duration"]) + " mins\n" + \
		"Final Impact Score: " + str(snapped(impact, 0.1))

func _on_confirm_pressed() -> void:
	if selected_system_id == "":
		result_label.text = "Please select one sound system setup."
		return

	var selected_data: Dictionary = {}
	for system_data in GameState.sound_system_defs:
		if system_data["id"] == selected_system_id:
			selected_data = system_data
			break

	if selected_data.is_empty():
		result_label.text = "Sound system data not found."
		return

	var ok := GameState.choose_sound_system(selected_data)
	if not ok:
		result_label.text = "Not enough budget for this sound system setup."
		return

	GameState.complete_activity("sound_system_choices")
	result_label.text = "Sound system selected successfully."
	refresh_ui()

	hide()
	get_parent().get_node("ActivityBoard").show()
	get_parent().get_node("ActivityBoard").refresh_board()

func refresh_ui() -> void:
	money_label.text = "Budget: " + str(GameState.money) + " TL"

func _on_visibility_changed() -> void:
	if visible:
		refresh_ui()

func _on_back_pressed() -> void:
	hide()
	get_parent().get_node("ActivityBoard").show()
	get_parent().get_node("ActivityBoard").refresh_board()
