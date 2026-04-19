extends Control

# ---------------- LOGISTICS DATA ----------------
var selections: Dictionary = {} # del_id -> week_choice ("week_8" or "week_9")

# ---------------- UI REFS ----------------
@onready var manifest_list: VBoxContainer = $MarginContainer/VBoxContainer/MainContent/LeftManifest/ScrollContainer/ManifestList
@onready var w8_slots: VBoxContainer = $MarginContainer/VBoxContainer/MainContent/CenterTimeline/TimelineContent/TimelineGrid/Week8Box/W8Slots
@onready var w9_slots: VBoxContainer = $MarginContainer/VBoxContainer/MainContent/CenterTimeline/TimelineContent/TimelineGrid/Week9Box/W9Slots

@onready var risk_label: Label = $MarginContainer/VBoxContainer/MainContent/RightAdvisor/RiskBox/VBox/Margin/RiskLabel
@onready var efficiency_label: Label = $MarginContainer/VBoxContainer/MainContent/RightAdvisor/EfficiencyScore

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
	
	_setup_guide_text()
	_setup_ui_styles()
	_create_manifest_cards()
	_refresh_ui()

func _setup_ui_styles() -> void:
	var main_style = StyleBoxFlat.new()
	main_style.bg_color = Color(0.05, 0.08, 0.12, 0.95)
	main_style.border_width_left = 4
	main_style.border_color = Color(0.0, 0.8, 1.0) # Tactical Cyan
	add_theme_stylebox_override("panel", main_style)

	var center_style = StyleBoxFlat.new()
	center_style.bg_color = Color(0.1, 0.15, 0.2, 0.8)
	center_style.border_width_top = 2
	center_style.border_color = Color(0.3, 0.5, 0.7)
	$MarginContainer/VBoxContainer/MainContent/CenterTimeline.add_theme_stylebox_override("panel", center_style)

	var risk_style = StyleBoxFlat.new()
	risk_style.bg_color = Color(0.08, 0.1, 0.15, 0.9)
	risk_style.border_width_left = 4
	risk_style.border_color = Color(1.0, 0.4, 0.0) # Logistics Orange
	$MarginContainer/VBoxContainer/MainContent/RightAdvisor/RiskBox.add_theme_stylebox_override("panel", risk_style)

func _create_manifest_cards() -> void:
	for child in manifest_list.get_children():
		child.queue_free()

	for delivery in GameState.transport_delivery_defs:
		manifest_list.add_child(_create_card(delivery))

func _create_card(delivery: Dictionary) -> PanelContainer:
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 110)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.2, 0.25, 0.7)
	style.border_width_left = 4
	style.border_color = _get_type_color(delivery["type"])
	card.add_theme_stylebox_override("panel", style)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	card.add_child(margin)

	var v_box = VBoxContainer.new()
	v_box.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(v_box)

	var name_lbl = Label.new()
	name_lbl.text = delivery["name"]
	name_lbl.add_theme_font_size_override("font_size", 18)
	v_box.add_child(name_lbl)

	var stats_lbl = Label.new()
	stats_lbl.text = "Slot: %s | Workload: %d" % [delivery["arrival_time"], delivery["workload"]]
	stats_lbl.add_theme_font_size_override("font_size", 12)
	stats_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	v_box.add_child(stats_lbl)

	var choice_row = HBoxContainer.new()
	choice_row.alignment = BoxContainer.ALIGNMENT_CENTER
	v_box.add_child(choice_row)

	var group = ButtonGroup.new()
	var w8_btn = CheckBox.new()
	w8_btn.text = "W8"
	w8_btn.button_group = group
	w8_btn.toggled.connect(func(p): if p: _on_selection_changed(delivery["id"], "week_8"))
	
	var w9_btn = CheckBox.new()
	w9_btn.text = "W9"
	w9_btn.button_group = group
	w9_btn.toggled.connect(func(p): if p: _on_selection_changed(delivery["id"], "week_9"))
	
	choice_row.add_child(w8_btn)
	choice_row.add_child(w9_btn)

	return card

func _get_type_color(type: String) -> Color:
	match type:
		"stage": return Color(1, 0, 0) # Red for backbone
		"sound", "lighting": return Color(1, 1, 0) # Yellow for systems
		"decoration": return Color(0.5, 0, 1) # Purple
		"food": return Color(0, 1, 0) # Green
		_: return Color(1, 1, 1)

func _on_selection_changed(del_id: String, choice: String) -> void:
	selections[del_id] = choice
	_refresh_ui()

func _refresh_ui() -> void:
	_update_timeline()
	_update_risk_analysis()

func _update_timeline() -> void:
	# Clear slots
	for c in w8_slots.get_children(): c.queue_free()
	for c in w9_slots.get_children(): c.queue_free()

	# Populate slots
	for del_id in selections:
		var delivery = _get_delivery(del_id)
		var entry = Label.new()
		entry.text = "🚛 " + delivery["name"] + " (" + delivery["arrival_time"][0] + ")"
		entry.add_theme_font_size_override("font_size", 18)
		entry.add_theme_color_override("font_color", _get_type_color(delivery["type"]))
		entry.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		
		var tag = PanelContainer.new()
		var tag_style = StyleBoxFlat.new()
		tag_style.bg_color = Color(0.1, 0.1, 0.1, 0.8)
		tag_style.border_width_left = 3
		tag_style.border_color = _get_type_color(delivery["type"])
		tag_style.content_margin_left = 10
		tag_style.content_margin_top = 5
		tag_style.content_margin_bottom = 5
		tag.add_theme_stylebox_override("panel", tag_style)
		tag.add_child(entry)
		
		if selections[del_id] == "week_8":
			w8_slots.add_child(tag)
		else:
			w9_slots.add_child(tag)

func _update_risk_analysis() -> void:
	var warnings = []
	var efficiency = 100
	
	# Paperwork check
	for del_id in selections:
		var d = _get_delivery(del_id)
		if d["paperwork_status"] != "Complete":
			warnings.append("⚠️ DOCS: " + d["name"] + " missing paperwork.")
			efficiency -= 5

	# Dependency check
	for del_id in selections:
		var d = _get_delivery(del_id)
		var dep_id = d["dependency"]
		if dep_id != "none" and selections.has(dep_id):
			var my_week = 8 if selections[del_id] == "week_8" else 9
			var dep_week = 8 if selections[dep_id] == "week_8" else 9
			
			if my_week < dep_week:
				warnings.append("❌ ORDER: " + d["name"] + " arrives before " + _get_delivery(dep_id)["name"])
				efficiency -= 20
			elif my_week == dep_week:
				var my_time = _time_to_val(d["arrival_time"])
				var dep_time = _time_to_val(_get_delivery(dep_id)["arrival_time"])
				if my_time <= dep_time:
					warnings.append("⚠️ SLOT: " + d["name"] + " same slot as " + _get_delivery(dep_id)["name"])
					efficiency -= 10

	# Congestion check
	var slot_counts = {"w8_m":0, "w8_a":0, "w8_e":0, "w9_m":0, "w9_a":0, "w9_e":0}
	for del_id in selections:
		var d = _get_delivery(del_id)
		var week_prefix = "w8" if selections[del_id] == "week_8" else "w9"
		var key = week_prefix + "_" + d["arrival_time"].to_lower()[0]
		slot_counts[key] += 1
		
	for key in slot_counts:
		if slot_counts[key] >= 3:
			warnings.append("☢️ CONGESTION: Slot overloaded! Unloading will be slow.")
			efficiency -= 15

	if warnings.is_empty():
		risk_label.text = "Optimal logistics path detected. No major risks found."
		risk_label.add_theme_color_override("font_color", Color.GREEN)
	else:
		risk_label.text = "\n".join(warnings)
		risk_label.add_theme_color_override("font_color", Color.CORAL)
	
	efficiency_label.text = "Coordination Efficiency: " + str(max(efficiency, 0)) + "%"
	if efficiency < 50: efficiency_label.add_theme_color_override("font_color", Color.RED)
	elif efficiency < 80: efficiency_label.add_theme_color_override("font_color", Color.YELLOW)
	else: efficiency_label.add_theme_color_override("font_color", Color.GREEN)

func _get_delivery(id: String) -> Dictionary:
	for d in GameState.transport_delivery_defs:
		if d["id"] == id: return d
	return {}

func _time_to_val(t: String) -> int:
	match t.to_lower():
		"morning": return 1
		"afternoon": return 2
		"evening": return 3
	return 4

func _on_confirm_pressed() -> void:
	if selections.size() < GameState.transport_delivery_defs.size():
		risk_label.text = "SYSTEM: Sync incomplete. All trucks must be assigned."
		return

	GameState.save_transport_schedule(selections)
	_on_back_pressed()

func _on_back_pressed() -> void:
	hide()
	get_parent().get_node("ActivityBoard").show()
	get_parent().get_node("ActivityBoard").refresh_board()

func _setup_guide_text() -> void:
	guide_label.text = "\n\nACTIVITY OVERVIEW\n\n" + \
		"Decide which deliveries to accept and when they will arrive. All heavy equipment must be on-site by Week 9.\n\n" + \
		"YOUR OBJECTIVES\n" + \
		"• Coordinate deliveries efficiently\n" + \
		"• Avoid delays and bottlenecks\n" + \
		"• Respect delivery dependencies (e.g. Stage before Sound)\n\n" + \
		"KEY RULES\n" + \
		"• Stage Infrastructure: Must arrive before systems and security barriers.\n" + \
		"• Congestion: Slots with 3 or more trucks cause major unloading delays.\n" + \
		"• Paperwork: Incomplete documents lead to operational friction.\n\n" + \
		"IMPACT\n" + \
		"Your coordination efficiency score directly affects the setup speed in Week 8 and 9. Poor timing will lose points."
