extends Control

@onready var option_list: VBoxContainer = $MarginContainer/VBoxContainer/ScrollContainer/OptionList
@onready var result_label: Label = $MarginContainer/VBoxContainer/ResultLabel
@onready var confirm_button: Button = $MarginContainer/VBoxContainer/ButtonsRow/ConfirmButton
@onready var back_button: Button = $MarginContainer/VBoxContainer/ButtonsRow/BackButton

var selections: Dictionary = {}

func _ready() -> void:
	confirm_button.pressed.connect(_on_confirm_pressed)
	back_button.pressed.connect(_on_back_pressed)

	var title: Label = $MarginContainer/VBoxContainer/TitleLabel
	title.add_theme_font_size_override("font_size", 32)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	var desc: Label = $MarginContainer/VBoxContainer/DescriptionLabel
	desc.add_theme_font_size_override("font_size", 20)
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

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

	build_options()

func build_options() -> void:
	for child in option_list.get_children():
		child.queue_free()

	for delivery in GameState.transport_delivery_defs:
		var container = VBoxContainer.new()
		
		var name_label = Label.new()
		name_label.text = "🚚 " + delivery["name"]
		name_label.add_theme_font_size_override("font_size", 26)
		
		var details = Label.new()
		details.text = "      ↳ Time: %s  |  Paperwork: %s  |  Dependency: %s  |  Workload: %d/10" % [
			delivery["arrival_time"],
			delivery["paperwork_status"],
			delivery["dependency"],
			delivery["workload"]
		]
		details.add_theme_font_size_override("font_size", 18)
		details.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))

		var h_box = HBoxContainer.new()
		h_box.alignment = BoxContainer.ALIGNMENT_CENTER
		
		var group = ButtonGroup.new()
		
		var week8_btn = CheckBox.new()
		week8_btn.text = "Week 8"
		week8_btn.button_group = group
		week8_btn.add_theme_font_size_override("font_size", 20)
		
		var week9_btn = CheckBox.new()
		week9_btn.text = "Week 9"
		week9_btn.button_group = group
		week9_btn.add_theme_font_size_override("font_size", 20)
		
		var del_id = delivery["id"]
		week8_btn.toggled.connect(func(pressed: bool): _on_radio_toggled(del_id, "week_8", pressed))
		week9_btn.toggled.connect(func(pressed: bool): _on_radio_toggled(del_id, "week_9", pressed))
		
		h_box.add_child(week8_btn)
		h_box.add_child(week9_btn)
		
		container.add_child(name_label)
		container.add_child(details)
		container.add_child(h_box)
		
		var spacer = Control.new()
		spacer.custom_minimum_size = Vector2(0, 16)
		container.add_child(spacer)

		option_list.add_child(container)

func _get_delivery(del_id: String) -> Dictionary:
	for d in GameState.transport_delivery_defs:
		if d["id"] == del_id:
			return d
	return {}

func _time_val(time_str: String) -> int:
	var t = time_str.to_lower()
	if t == "morning": return 1
	if t == "afternoon": return 2
	if t == "evening": return 3
	return 4

func _on_radio_toggled(delivery_id: String, choice: String, pressed: bool) -> void:
	if pressed:
		selections[delivery_id] = choice
		_check_warnings()

func _check_warnings() -> void:
	var warnings = []
	
	for del_id in selections:
		var delivery = _get_delivery(del_id)
		if delivery["paperwork_status"] != "Complete":
			if not warnings.has("⚠️ " + delivery["name"] + " has incomplete paperwork! Needs attention."):
				warnings.append("⚠️ " + delivery["name"] + " has incomplete paperwork! Needs attention.")
			
	for del_id in selections:
		var delivery = _get_delivery(del_id)
		var dep_id = delivery["dependency"]
		if dep_id != "none" and dep_id != "":
			var my_week = 8 if selections[del_id] == "week_8" else 9
			if not selections.has(dep_id):
				# Missing dependency selection
				pass # Optional: could warn, but they might just haven't clicked it yet.
			else:
				var dep_week = 8 if selections[dep_id] == "week_8" else 9
				var dep_name = _get_delivery(dep_id)["name"]
				
				if my_week < dep_week:
					warnings.append("⚠️ Order Issue: " + delivery["name"] + " arriving in Week " + str(my_week) + " before " + dep_name + " in Week " + str(dep_week) + "!")
				elif my_week == dep_week:
					var my_time = _time_val(delivery["arrival_time"])
					var dep_time = _time_val(_get_delivery(dep_id)["arrival_time"])
					if my_time <= dep_time:
						warnings.append("⚠️ Time Issue: " + delivery["name"] + " arrives at " + delivery["arrival_time"] + ", same time or earlier than " + dep_name + "!")

	if warnings.is_empty():
		result_label.text = ""
		result_label.add_theme_color_override("font_color", Color(1, 1, 1))
	else:
		result_label.text = "\n".join(warnings)
		result_label.add_theme_color_override("font_color", Color(1, 0.8, 0.2))

func _on_confirm_pressed() -> void:
	if selections.size() < GameState.transport_delivery_defs.size():
		result_label.text = "Please select a week for all deliveries."
		return

	GameState.save_transport_schedule(selections)
	result_label.text = "Transport schedule saved successfully."
	
	hide()
	get_parent().get_node("ActivityBoard").show()
	get_parent().get_node("ActivityBoard").refresh_board()

func _on_back_pressed() -> void:
	hide()
	get_parent().get_node("ActivityBoard").show()
	get_parent().get_node("ActivityBoard").refresh_board()
