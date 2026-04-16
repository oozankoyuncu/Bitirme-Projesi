extends Control

@onready var option_list: VBoxContainer = $MarginContainer/VBoxContainer/OptionList
@onready var info_label: Label = $MarginContainer/VBoxContainer/InfoLabel
@onready var result_label: Label = $MarginContainer/VBoxContainer/ResultLabel
@onready var money_label: Label = $MarginContainer/VBoxContainer/MoneyLabel
@onready var confirm_button: Button = $MarginContainer/VBoxContainer/ButtonsRow/ConfirmButton
@onready var back_button: Button = $MarginContainer/VBoxContainer/ButtonsRow/BackButton

var selected_theme_id: String = ""

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

	for theme in GameState.decoration_theme_defs:
		var container = VBoxContainer.new()
		var checkbox := CheckBox.new()
		var impact := GameState.calculate_decoration_theme_impact(theme)

		checkbox.text = " " + theme["name"] + "  (💰 $" + str(theme["cost"]) + ")"
		checkbox.add_theme_font_size_override("font_size", 26)
		checkbox.set_meta("theme_data", theme)
		checkbox.toggled.connect(func(pressed: bool): _on_theme_toggled(checkbox, pressed))
		
		var details := Label.new()
		details.text = "      ↳ 😊 Satisfaction: %d/10   |   ⚙️ Complexity: %d/10   |   📏 Space: %d/10   |   ⭐ Theme Score: %.1f" % [
			theme["satisfaction_impact"],
			theme["complexity"],
			theme["space_impact"],
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

func _on_theme_toggled(changed_checkbox: CheckBox, pressed: bool) -> void:
	if not pressed:
		if changed_checkbox.get_meta("theme_data")["id"] == selected_theme_id:
			selected_theme_id = ""
			info_label.text = "Please select a theme from the list..."
		return

	for container in option_list.get_children():
		for child in container.get_children():
			if child is CheckBox and child != changed_checkbox:
				child.button_pressed = false

	var theme: Dictionary = changed_checkbox.get_meta("theme_data")
	selected_theme_id = theme["id"]

	var impact := GameState.calculate_decoration_theme_impact(theme)
	info_label.text = \
		"=== SELECTED: " + theme["name"].to_upper() + " ===\n" + \
		"💰 Budget Cost: $" + str(theme["cost"]) + "\n" + \
		"⏱️ Setup Processing Time: " + str(theme["setup_duration"]) + " weeks\n" + \
		"😊 Joy & Satisfaction Impact: " + str(theme["satisfaction_impact"]) + " / 10\n" + \
		"⚙️ Construction Complexity: " + str(theme["complexity"]) + " / 10\n" + \
		"📏 Scale & Space Requirements: " + str(theme["space_impact"]) + " / 10\n" + \
		"⭐ Computed Synergy Score: " + str(snapped(impact, 0.1))

func _on_confirm_pressed() -> void:
	if selected_theme_id == "":
		result_label.text = "Please select one decoration theme."
		return

	var selected_data: Dictionary = {}
	for theme in GameState.decoration_theme_defs:
		if theme["id"] == selected_theme_id:
			selected_data = theme
			break

	if selected_data.is_empty():
		result_label.text = "Theme data not found."
		return

	var ok := GameState.choose_decoration_theme(selected_data)
	if not ok:
		result_label.text = "Not enough budget for this theme selection."
		return

	GameState.complete_activity("decoration_theme_decision")
	result_label.text = "Decoration Theme selected successfully."
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
