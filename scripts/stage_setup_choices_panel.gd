extends Control

# ---------------- DATA ----------------
var selected_stage_id: String = ""

# ---------------- UI REFS ----------------
@onready var stage_list: HBoxContainer = $MarginContainer/VBoxContainer/MainContent/CenterDashboard/VBoxContainer/ScrollContainer/StageList
@onready var preview_title: Label = $MarginContainer/VBoxContainer/MainContent/CenterDashboard/VBoxContainer/PreviewTitle
@onready var duration_label: Label = $MarginContainer/VBoxContainer/MainContent/CenterDashboard/VBoxContainer/DurationLabel

@onready var size_bar: ProgressBar = $MarginContainer/VBoxContainer/MainContent/RightPalette/StatsContainer/SizeStat/ProgressBar
@onready var lighting_bar: ProgressBar = $MarginContainer/VBoxContainer/MainContent/RightPalette/StatsContainer/LightingStat/ProgressBar
@onready var operation_bar: ProgressBar = $MarginContainer/VBoxContainer/MainContent/RightPalette/StatsContainer/OperationStat/ProgressBar
@onready var result_label: Label = $MarginContainer/VBoxContainer/MainContent/RightPalette/ResultLabel

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
	_create_stage_cards()
	_refresh_ui()

func _process(_delta: float) -> void:
	if visible:
		money_label.text = "Budget: " + str(GameState.money) + " TL"

func _setup_ui_styles() -> void:
	var main_style = StyleBoxFlat.new()
	main_style.bg_color = Color(0.05, 0.08, 0.12, 0.95)
	main_style.border_width_left = 4
	main_style.border_color = Color(0.0, 1.0, 0.8) # Technical Cyan
	add_theme_stylebox_override("panel", main_style)

	var dash_style = StyleBoxFlat.new()
	dash_style.bg_color = Color(0.1, 0.15, 0.2, 0.8)
	dash_style.set_corner_radius_all(10)
	$MarginContainer/VBoxContainer/MainContent/CenterDashboard.add_theme_stylebox_override("panel", dash_style)

func _create_stage_cards() -> void:
	for child in stage_list.get_children():
		child.queue_free()

	for stage_data in GameState.stage_setup_defs:
		var card = _create_card(stage_data)
		stage_list.add_child(card)

func _create_card(stage_data: Dictionary) -> PanelContainer:
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(220, 220)
	card.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.2, 0.25, 0.7)
	style.border_width_left = 4
	style.border_color = Color(0, 0.6, 1.0)
	card.add_theme_stylebox_override("panel", style)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 15)
	margin.add_theme_constant_override("margin_right", 15)
	card.add_child(margin)

	var v_box = VBoxContainer.new()
	v_box.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(v_box)

	var name_lbl = Label.new()
	name_lbl.text = stage_data["name"]
	name_lbl.add_theme_font_size_override("font_size", 22)
	v_box.add_child(name_lbl)

	var cost_lbl = Label.new()
	cost_lbl.text = str(stage_data["cost"]) + " TL"
	cost_lbl.add_theme_font_size_override("font_size", 18)
	cost_lbl.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5))
	v_box.add_child(cost_lbl)

	# Click logic
	card.gui_input.connect(func(event): 
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_select_stage(stage_data, card)
	)

	return card

func _select_stage(stage_data: Dictionary, card: PanelContainer) -> void:
	selected_stage_id = stage_data["id"]
	
	# Highlight selected card
	for c in stage_list.get_children():
		c.get_theme_stylebox("panel").bg_color = Color(0.15, 0.2, 0.25, 0.7)
		c.get_theme_stylebox("panel").border_width_left = 4
	
	card.get_theme_stylebox("panel").bg_color = Color(0.1, 0.3, 0.5, 0.9)
	card.get_theme_stylebox("panel").border_width_left = 8 # Stronger highlight

	# Update Details
	duration_label.text = "Estimated Setup: " + str(stage_data["setup_duration"]) + " Weeks"

	# Update bars
	size_bar.value = stage_data["stage_size"]
	lighting_bar.value = stage_data["lighting_complexity"]
	operation_bar.value = stage_data["operation_features"]
	
	result_label.text = ""

func _on_confirm_pressed() -> void:
	if selected_stage_id == "":
		result_label.text = "CRITICAL: No infrastructure catalog selected."
		result_label.add_theme_color_override("font_color", Color.CORAL)
		return

	var stage_data: Dictionary = {}
	for s in GameState.stage_setup_defs:
		if s["id"] == selected_stage_id:
			stage_data = s
			break

	if GameState.money < stage_data["cost"]:
		result_label.text = "ERROR: Insufficient capital for this infrastructure."
		result_label.add_theme_color_override("font_color", Color.RED)
		return

	GameState.choose_stage_setup(stage_data)
	GameState.complete_activity("stage_setup_choices")
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
		"Select the main stage infrastructure for your festival. Each option has a direct impact on audience experience and technical quality.\n\n" + \
		"YOUR OBJECTIVES\n" + \
		"• Provide strong performance capabilities.\n" + \
		"• Stay within budget constraints.\n" + \
		"• Manage physical scale vs complexity.\n\n" + \
		"CALCULATIONS (Stage Impact)\n" + \
		"Impact = (Scale * 0.5) + (Lighting * 0.3) + (Operations * 0.2)\n\n" + \
		"KEY RULES\n" + \
		"• You can only assign one infrastructure version per project.\n" + \
		"• The setup duration will affect your logistical timeline.\n" + \
		"• Minimum attribute levels of 3+ are recommended for professional results."
