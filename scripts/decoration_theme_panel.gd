extends Control

# ---------------- DATA ----------------
# The data is loaded from JSON in GameState, but we'll manage local selection state
var selected_theme_id: String = ""

# ---------------- UI REFS ----------------
@onready var theme_list: VBoxContainer = $MarginContainer/VBoxContainer/MainContent/LeftPalette/ScrollContainer/ThemeList
@onready var preview_title: Label = $MarginContainer/VBoxContainer/MainContent/CenterDashboard/VBoxContainer/PreviewTitle
@onready var description_label: Label = $MarginContainer/VBoxContainer/MainContent/CenterDashboard/VBoxContainer/DescriptionLabel
@onready var synergy_label: Label = $MarginContainer/VBoxContainer/MainContent/CenterDashboard/VBoxContainer/SynergyScoreLabel

@onready var satisfaction_bar: ProgressBar = $MarginContainer/VBoxContainer/MainContent/RightPalette/StatsContainer/SatisfactionStats/ProgressBar
@onready var complexity_bar: ProgressBar = $MarginContainer/VBoxContainer/MainContent/RightPalette/StatsContainer/ComplexityStats/ProgressBar
@onready var space_bar: ProgressBar = $MarginContainer/VBoxContainer/MainContent/RightPalette/StatsContainer/SpaceStats/ProgressBar
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
	_create_theme_cards()
	
	# Move RightPalette below MainContent
	var main_content = $MarginContainer/VBoxContainer/MainContent
	var right_palette = $MarginContainer/VBoxContainer/MainContent/RightPalette
	var vbox = $MarginContainer/VBoxContainer
	
	main_content.remove_child(right_palette)
	vbox.add_child(right_palette)
	vbox.move_child(right_palette, main_content.get_index() + 1)
	
	# Align the progress bars horizontally
	var stats_container = right_palette.get_node("StatsContainer")
	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 50)
	
	var stat_nodes = stats_container.get_children()
	for child in stat_nodes:
		stats_container.remove_child(child)
		hbox.add_child(child)
	
	right_palette.remove_child(stats_container)
	right_palette.add_child(hbox)
	right_palette.move_child(hbox, 0)
	stats_container.queue_free()
	
	_refresh_ui()

func _process(_delta: float) -> void:
	if visible:
		money_label.text = "Budget: " + str(GameState.money) + " TL"

func _setup_ui_styles() -> void:
	var main_style = StyleBoxFlat.new()
	main_style.bg_color = Color(0.05, 0.08, 0.12, 0.95) # Deep HUD blue
	main_style.border_width_left = 4
	main_style.border_color = Color(0.0, 0.6, 1.0) # Tactical Cyan
	add_theme_stylebox_override("panel", main_style)

	var dash_style = StyleBoxFlat.new()
	dash_style.bg_color = Color(0.1, 0.15, 0.2, 0.8)
	dash_style.set_corner_radius_all(10)
	$MarginContainer/VBoxContainer/MainContent/CenterDashboard.add_theme_stylebox_override("panel", dash_style)

func _create_theme_cards() -> void:
	for child in theme_list.get_children():
		child.queue_free()

	for theme in GameState.decoration_theme_defs:
		var card = _create_card(theme)
		theme_list.add_child(card)

func _create_card(theme: Dictionary) -> PanelContainer:
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 100)
	card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.2, 0.25, 0.7)
	style.border_width_left = 5
	style.border_color = _get_theme_color(theme["id"])
	card.add_theme_stylebox_override("panel", style)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 15)
	margin.add_theme_constant_override("margin_right", 15)
	card.add_child(margin)

	var v_box = VBoxContainer.new()
	v_box.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(v_box)

	var name_lbl = Label.new()
	name_lbl.text = theme["name"]
	name_lbl.add_theme_font_size_override("font_size", 20)
	v_box.add_child(name_lbl)

	var cost_lbl = Label.new()
	cost_lbl.text = "Cost: " + str(theme["cost"]) + " TL"
	cost_lbl.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
	v_box.add_child(cost_lbl)

	# Click logic
	card.gui_input.connect(func(event): 
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_select_theme(theme, card)
	)

	return card

func _get_theme_color(id: String) -> Color:
	match id:
		"electro_neon": return Color(0.8, 0.0, 1.0) # Neon Purple
		"colorful_carnival": return Color(1.0, 0.4, 0.0) # Carnival Orange
		"old_school_retro": return Color(0.0, 0.8, 0.8) # Retro Cyan
		"freedom_time": return Color(1.0, 1.0, 1.0) # Pure White/Beyond
		_: return Color(0.5, 0.5, 0.5)

func _select_theme(theme: Dictionary, card: PanelContainer) -> void:
	selected_theme_id = theme["id"]
	
	# Highlight selected card
	for c in theme_list.get_children():
		c.get_theme_stylebox("panel").bg_color = Color(0.15, 0.2, 0.25, 0.7)
	card.get_theme_stylebox("panel").bg_color = Color(0.1, 0.3, 0.5, 0.9)

	# Update Preview
	preview_title.text = theme["name"].to_upper()
	preview_title.add_theme_color_override("font_color", _get_theme_color(theme["id"]))
	
	# Descriptions mapping (dynamic)
	match theme["id"]:
		"electro_neon": description_label.text = "Immerse the festival in futuristic neon lights and electronic vibes. High satisfaction but requires significant power and space."
		"colorful_carnival": description_label.text = "A burst of traditional colors and street-party aesthetics. Reliable, simple to set up, and universally loved."
		"old_school_retro": description_label.text = "Nostalgic 90s vibes with pixel art and retro props. Low cost and low complexity, perfect for tighter budgets."
		"freedom_time": description_label.text = "Abstract, minimalist, and open-ended. A sophisticated choice that balances space and satisfaction beautifully."
	
	var impact = GameState.calculate_decoration_theme_impact(theme)
	synergy_label.text = "Synergy Score: " + str(snapped(impact, 0.1))

	# Update bars
	satisfaction_bar.value = theme["satisfaction_impact"]
	complexity_bar.value = theme["complexity"]
	space_bar.value = theme["space_impact"]
	
	result_label.text = ""

func _on_confirm_pressed() -> void:
	if selected_theme_id == "":
		result_label.text = "Please select a theme catalog entry."
		result_label.add_theme_color_override("font_color", Color.CORAL)
		return

	var theme_data: Dictionary = {}
	for t in GameState.decoration_theme_defs:
		if t["id"] == selected_theme_id:
			theme_data = t
			break

	if GameState.money < theme_data["cost"]:
		result_label.text = "CRITICAL: Insufficient funds for this deployment."
		result_label.add_theme_color_override("font_color", Color.RED)
		return

	GameState.choose_decoration_theme(theme_data)
	GameState.complete_activity("decoration_theme_decision")
	
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
	guide_label.text = "\n\nACTIVITY GUIDE: DECORATION & THEME\n\n" + \
		"Activity Overview:\n" + \
		"The decoration theme defines the visual identity of your festival. It influences participant happiness and construction logistics.\n\n" + \
		"Your Objective:\n" + \
		"• Choose a theme that maximizes satisfaction while managing costs and space.\n" + \
		"• Higher complexity might lead to longer setup times or higher risks.\n\n" + \
		"Calculations:\n" + \
		"• Synergy Score = (Satisfaction Impact * 0.6) / ((Complexity + Space) * 0.4)\n" + \
		"  Synergy Score serves as a comprehensive indicator of how well a theme balances visual appeal and participant enjoyment against the logistical burdens of construction and space utilization. A higher score means you are getting more value out of your setup.\n" + \
		"• Higher Satisfaction Impact = Translates to much better participant reviews, stronger social media presence, and significantly boosts the overall Event Quality metric of the festival.\n" + \
		"• Higher Complexity = Increased engineering challenge.\n\n" + \
		"Rules:\n" + \
		"• You can only finalize one primary theme.\n" + \
		"• Ensure you have enough budget before confirming."
