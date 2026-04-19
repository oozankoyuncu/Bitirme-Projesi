extends Control

# ---------------- LOGISTICS DATA ----------------
var selected_system_id: String = ""

# ---------------- UI REFS ----------------
@onready var system_list: HBoxContainer = $MarginContainer/VBoxContainer/CatalogSection/ScrollContainer/SystemList
@onready var preview_title: Label = $MarginContainer/VBoxContainer/DetailsArea/VBox/PreviewTitle
@onready var setup_label: Label = $MarginContainer/VBoxContainer/DetailsArea/VBox/InfoRow/SetupLabel

@onready var quality_bar: ProgressBar = $MarginContainer/VBoxContainer/DetailsArea/VBox/StatsGrid/QualityStat/ProgressBar
@onready var skill_bar: ProgressBar = $MarginContainer/VBoxContainer/DetailsArea/VBox/StatsGrid/SkillStat/ProgressBar
@onready var grid_load_bar: ProgressBar = $MarginContainer/VBoxContainer/DetailsArea/VBox/StatsGrid/GridLoadStat/ProgressBar

@onready var result_label: Label = $MarginContainer/VBoxContainer/ResultLabel
@onready var money_label: Label = $MarginContainer/VBoxContainer/Footer/MoneyBox/MoneyLabel
@onready var confirm_button: Button = $MarginContainer/VBoxContainer/Footer/ConfirmButton
@onready var back_button: Button = $MarginContainer/VBoxContainer/Footer/BackButton

@onready var info_button: Button = $MarginContainer/VBoxContainer/Header/InfoButton
@onready var guide_panel: PanelContainer = $GuidePanel
@onready var guide_label: Label = $GuidePanel/MarginContainer/VBoxContainer/ScrollContainer/GuideLabel
@onready var close_guide_button: Button = $GuidePanel/MarginContainer/VBoxContainer/Header/CloseGuideButton

# ---------------- LOGIC ----------------

func _ready() -> void:
	confirm_button.pressed.connect(_on_confirm_pressed)
	back_button.pressed.connect(_on_back_pressed)
	info_button.pressed.connect(func(): guide_panel.show())
	close_guide_button.pressed.connect(func(): guide_panel.hide())
	visibility_changed.connect(_on_visibility_changed)
	
	_setup_guide_text()
	_setup_ui_styles()
	_create_system_cards()
	_refresh_ui()

func _process(_delta: float) -> void:
	if visible:
		money_label.text = "Budget: " + str(GameState.money) + " TL"

func _setup_ui_styles() -> void:
	var main_style = StyleBoxFlat.new()
	main_style.bg_color = Color(0.05, 0.08, 0.12, 0.95)
	main_style.border_width_top = 4
	main_style.border_color = Color(0.0, 0.6, 1.0) # Audio Blue
	add_theme_stylebox_override("panel", main_style)

	var details_style = StyleBoxFlat.new()
	details_style.bg_color = Color(0.1, 0.15, 0.2, 0.8)
	details_style.set_corner_radius_all(10)
	$MarginContainer/VBoxContainer/DetailsArea.add_theme_stylebox_override("panel", details_style)

func _create_system_cards() -> void:
	for child in system_list.get_children():
		child.queue_free()

	for system_data in GameState.sound_system_defs:
		system_list.add_child(_create_card(system_data))

func _create_card(system_data: Dictionary) -> PanelContainer:
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(220, 220)
	card.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.2, 0.25, 0.7)
	style.border_width_top = 5
	style.border_color = _get_quality_color(system_data["sound_quality"])
	card.add_theme_stylebox_override("panel", style)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_all", 15)
	card.add_child(margin)

	var v_box = VBoxContainer.new()
	v_box.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(v_box)

	var name_lbl = Label.new()
	name_lbl.text = system_data["name"]
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 20)
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v_box.add_child(name_lbl)

	var cost_lbl = Label.new()
	cost_lbl.text = str(system_data["cost"]) + " TL"
	cost_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cost_lbl.add_theme_color_override("font_color", Color(0.4, 1.0, 0.6))
	v_box.add_child(cost_lbl)

	card.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_select_system(system_data, card)
	)

	return card

func _get_quality_color(q: int) -> Color:
	if q >= 8: return Color(1, 0.84, 0) # Gold
	if q >= 6: return Color(0, 0.7, 1) # Blue
	return Color(0.6, 0.6, 0.6) # Gray

func _select_system(system_data: Dictionary, card: PanelContainer) -> void:
	selected_system_id = system_data["id"]
	
	# Highlight
	for c in system_list.get_children():
		c.get_theme_stylebox("panel").bg_color = Color(0.15, 0.2, 0.25, 0.7)
	card.get_theme_stylebox("panel").bg_color = Color(0.0, 0.3, 0.5, 0.9)

	# Update Details
	preview_title.text = system_data["name"].to_upper()
	setup_label.text = "Estimated Installation: " + str(system_data["setup_duration"]) + " Minutes"
	
	quality_bar.value = system_data["sound_quality"]
	skill_bar.value = system_data["technical_skill_level"]
	grid_load_bar.value = system_data["electricity_consumption"]
	
	result_label.text = ""

func _on_confirm_pressed() -> void:
	if selected_system_id == "":
		result_label.text = "SYSTEM ERROR: No acoustic configuration detected."
		result_label.add_theme_color_override("font_color", Color.CORAL)
		return

	var system_data: Dictionary = {}
	for s in GameState.sound_system_defs:
		if s["id"] == selected_system_id:
			system_data = s
			break

	if GameState.money < system_data["cost"]:
		result_label.text = "INSUFFICIENT FUNDS: Budget threshold exceeded."
		result_label.add_theme_color_override("font_color", Color.RED)
		return

	GameState.choose_sound_system(system_data)
	GameState.complete_activity("sound_system_choices")
	_on_back_pressed()

func _on_back_pressed() -> void:
	hide()
	get_parent().get_node("ActivityBoard").show()
	get_parent().get_node("ActivityBoard").refresh_board()

func _on_visibility_changed() -> void:
	if visible:
		_refresh_ui()

func _refresh_ui() -> void:
	money_label.text = "Budget: " + str(GameState.money) + " TL"
	result_label.text = ""

func _setup_guide_text() -> void:
	guide_label.text = "\n\nACTIVITY OVERVIEW\n\n" + \
		"Select the sound system for your festival by choosing one of the available system versions. " + \
		"Each system affects audio performance, technical requirements, and electricity consumption.\n\n" + \
		"YOUR OBJECTIVES\n" + \
		"• Provide high sound quality for participants.\n" + \
		"• Stay within your budget constraints.\n" + \
		"• Match your team’s technical capabilities.\n" + \
		"• Ensure your grid can support the electricity demand.\n\n" + \
		"KEY RULES\n" + \
		"• You can select only one sound system per event.\n" + \
		"• Higher technical requirements make the system harder to manage.\n" + \
		"• Higher electricity consumption places greater demand on power infrastructure.\n\n" + \
		"IMPACT\n" + \
		"A well-chosen system enhances the overall experience, while a poor choice may lead to technical issues or reduced quality."
