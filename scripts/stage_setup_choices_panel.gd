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
@onready var finish_button: Button = $MarginContainer/VBoxContainer/Footer/FinishButton

@onready var info_button: Button = $MarginContainer/VBoxContainer/Header/InfoButton
@onready var guide_panel: PanelContainer = $GuidePanel
@onready var guide_label: Label = $GuidePanel/MarginContainer/VBoxContainer/ScrollContainer/GuideLabel
@onready var close_guide_button: Button = $GuidePanel/MarginContainer/VBoxContainer/Header/CloseGuideButton

# ---------------- LOGIC ----------------

func _ready() -> void:

	# -- DYNAMIC BUTTON INJECTION --
	var __footer_found = false
	var __footer_node = null
	
	# Try common paths
	var __paths = [
		"MarginContainer/VBoxContainer/Footer",
		"MarginContainer/VBoxContainer/ButtonRow",
		"MarginContainer/VBoxContainer/MainContent/RightPanel",
		"MarginContainer/VBoxContainer/HBoxContainer"
	]
	
	for p in __paths:
		if has_node(p):
			__footer_node = get_node(p)
			__footer_found = true
			break
	
	if __footer_node != null:
		# Hide or remove any existing Confirm/Back buttons to replace with our standard ones
		for c in __footer_node.get_children():
			if c is Button and (c.name.find("Confirm") >= 0 or c.name.find("Back") >= 0 or c.name.find("Finish") >= 0):
				c.hide()
				# Keep them hidden, we'll use our own
		
		var __hbox = HBoxContainer.new()
		__hbox.alignment = BoxContainer.ALIGNMENT_CENTER
		__hbox.add_theme_constant_override("separation", 20)
		__hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		var __back_btn = Button.new()
		__back_btn.text = "BACK"
		__back_btn.custom_minimum_size = Vector2(150, 45)
		var __b_style = StyleBoxFlat.new()
		__b_style.bg_color = Color(0.3, 0.3, 0.3)
		__b_style.set_corner_radius_all(6)
		__back_btn.add_theme_stylebox_override("normal", __b_style)
		__back_btn.pressed.connect(self._on_back_pressed)
		__hbox.add_child(__back_btn)
		
		var __finish_btn = Button.new()
		__finish_btn.text = "FINISH"
		__finish_btn.custom_minimum_size = Vector2(150, 45)
		var __f_style = StyleBoxFlat.new()
		__f_style.bg_color = Color(0.1, 0.6, 0.2)
		__f_style.set_corner_radius_all(6)
		__finish_btn.add_theme_stylebox_override("normal", __f_style)
		if self.has_method("_on_finish_pressed"):
			__finish_btn.pressed.connect(self._on_finish_pressed)
		__hbox.add_child(__finish_btn)
		
		__footer_node.add_child(__hbox)
	confirm_button.pressed.connect(_on_confirm_pressed)
	info_button.pressed.connect(func(): guide_panel.show())
	close_guide_button.pressed.connect(func(): guide_panel.hide())
	visibility_changed.connect(_on_visibility_changed)

	_setup_guide_text()
	_setup_ui_styles()
	_create_stage_cards()
	
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

var scenario_timer_active = false

func _on_visibility_changed() -> void:
	if visible:
		_refresh_ui()
		if GameState.active_scenarios.has("stage_setup_event") and not GameState.triggered_scenarios.has("stage_setup_event") and not scenario_timer_active:
			scenario_timer_active = true
			_start_scenario_timer()

func _start_scenario_timer() -> void:
	await get_tree().create_timer(3.0).timeout
	if not is_inside_tree() or not is_visible_in_tree() or GameState.triggered_scenarios.has("stage_setup_event"):
		scenario_timer_active = false
		return
		
	GameState.triggered_scenarios.append("stage_setup_event")
	var is_increase = randf() > 0.5
	
	for s in GameState.stage_setup_defs:
		if is_increase:
			s["cost"] = int(s["cost"] * 1.15)
		else:
			s["cost"] = int(s["cost"] * 0.85)
			
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.85)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 100
	
	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(700, 400)
	var p_style = StyleBoxFlat.new()
	p_style.bg_color = Color(0.1, 0.12, 0.18, 1.0)
	p_style.set_corner_radius_all(15)
	p_style.border_width_left = 6
	p_style.border_width_right = 6
	p_style.border_width_top = 6
	p_style.border_width_bottom = 6
	p_style.border_color = Color(0.9, 0.3, 0.3, 1.0) if is_increase else Color(0.3, 0.9, 0.3, 1.0)
	p_style.shadow_size = 30
	p_style.shadow_color = Color(0, 0, 0, 0.7)
	panel.add_theme_stylebox_override("panel", p_style)
	center.add_child(panel)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 40)
	margin.add_theme_constant_override("margin_right", 40)
	margin.add_theme_constant_override("margin_top", 40)
	margin.add_theme_constant_override("margin_bottom", 40)
	panel.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 25)
	margin.add_child(vbox)
	
	var title = Label.new()
	title.text = "📈 MARKET SHIFT 📈" if is_increase else "🎉 GOOD NEWS 🎉"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 38)
	title.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3) if is_increase else Color(0.3, 1.0, 0.3))
	vbox.add_child(title)
	
	var sep = HSeparator.new()
	vbox.add_child(sep)
	
	var body = Label.new()
	if is_increase:
		body.text = "Market Notification: Due to recent currency fluctuations and supply chain issues,\nthe cost of all stage setup options has increased by 15%!"
	else:
		body.text = "School Board Notification: Good news! The school administration has decided to partially\nsponsor the festival's infrastructure. All stage setup costs have been reduced by 15%!"
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_size_override("font_size", 24)
	vbox.add_child(body)
	
	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)
	
	var btn = Button.new()
	btn.text = "ACKNOWLEDGE"
	btn.custom_minimum_size = Vector2(300, 65)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	
	var b_style = StyleBoxFlat.new()
	b_style.bg_color = Color(0.8, 0.2, 0.2) if is_increase else Color(0.2, 0.8, 0.2)
	b_style.set_corner_radius_all(10)
	btn.add_theme_stylebox_override("normal", b_style)
	var b_hover = b_style.duplicate()
	b_hover.bg_color = Color(0.9, 0.3, 0.3) if is_increase else Color(0.3, 0.9, 0.3)
	btn.add_theme_stylebox_override("hover", b_hover)
	btn.add_theme_font_size_override("font_size", 22)
	
	btn.pressed.connect(func():
		var out_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN)
		out_tween.tween_property(overlay, "modulate:a", 0.0, 0.2)
		out_tween.tween_property(panel, "scale", Vector2(0.8, 0.8), 0.2)
		out_tween.chain().tween_callback(func():
			overlay.queue_free()
			_create_stage_cards()
			selected_stage_id = ""
			duration_label.text = "Estimated Setup: --"
			size_bar.value = 0
			lighting_bar.value = 0
			operation_bar.value = 0
		)
	)
	vbox.add_child(btn)
	
	overlay.modulate.a = 0.0
	panel.scale = Vector2(0.8, 0.8)
	var in_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	in_tween.tween_property(overlay, "modulate:a", 1.0, 0.4)
	in_tween.tween_property(panel, "scale", Vector2(1.0, 1.0), 0.4)
	
	add_child(overlay)

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

func _on_finish_pressed() -> void:
	_on_confirm_pressed()
