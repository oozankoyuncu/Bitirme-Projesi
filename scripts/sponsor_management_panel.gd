extends Control

# ---------------- DATA ----------------
var sponsor_defs = {}

# ---------------- UI ----------------
@onready var sponsor_list: VBoxContainer = $MarginContainer/VBoxContainer/MainContent/CenterSponsors/ScrollContainer/SponsorList
@onready var result_label: Label = $MarginContainer/VBoxContainer/MainContent/LeftNegotiation/ResultLabel
@onready var attempts_label: Label = $MarginContainer/VBoxContainer/MainContent/LeftNegotiation/AttemptsLabel
@onready var money_label: Label = $MarginContainer/VBoxContainer/Footer/MoneyBox/MoneyLabel
@onready var signed_list_label: Label = $MarginContainer/VBoxContainer/MainContent/RightSummary/SummaryPanel/MarginContainer/VBoxContainer/SignedListLabel
@onready var check_button: Button = $MarginContainer/VBoxContainer/MainContent/LeftNegotiation/CheckButton
@onready var back_button: Button = $MarginContainer/VBoxContainer/Footer/BackButton

@onready var info_btn: Button = $MarginContainer/VBoxContainer/Header/InfoButton
@onready var guide_panel: PanelContainer = $GuidePanel
@onready var guide_label: Label = $GuidePanel/MarginContainer/VBoxContainer/ScrollContainer/GuideLabel
@onready var close_guide_btn: Button = $GuidePanel/MarginContainer/VBoxContainer/Header/CloseGuideButton

# ---------------- LOGIC ----------------

var secret_nodes: Array = []
var _popup_timer_started: bool = false

func _ready() -> void:
	_load_sponsors()
	
	check_button.pressed.connect(_on_check_pressed)
	back_button.pressed.connect(_on_back_pressed)
	info_btn.pressed.connect(func(): guide_panel.show())
	close_guide_btn.pressed.connect(func(): guide_panel.hide())

	_setup_guide_text()
	_setup_ui_styles()
	
	create_sponsors()
	refresh_ui()
	
	self.visibility_changed.connect(_on_visibility_changed)

func _load_sponsors() -> void:
	var file = FileAccess.open("res://data/sponsors.json", FileAccess.READ)
	if file == null:
		print("ERROR: sponsors.json could not be opened")
		return
	
	var content = file.get_as_text()
	file.close()
	
	var data = JSON.parse_string(content)
	if data == null or not data.has("sponsors"):
		print("ERROR: Failed to parse sponsors.json")
		return
	
	sponsor_defs = data["sponsors"]
	print("Sponsors loaded: ", sponsor_defs.size())

func _on_visibility_changed() -> void:
	if is_visible_in_tree() and not GameState.sponsor_intelligence_bought and not _popup_timer_started:
		_popup_timer_started = true
		_start_popup_timer()

func _start_popup_timer() -> void:
	await get_tree().create_timer(2.0).timeout
	if not is_inside_tree() or not is_visible_in_tree() or GameState.sponsor_intelligence_bought:
		return
	_show_intelligence_popup()

func _show_intelligence_popup() -> void:
	var dialog = ConfirmationDialog.new()
	dialog.title = "Consulting Intelligence Service"
	dialog.dialog_text = "Would you like to purchase intelligence data to see the true probability (CHANCE) of each sponsor accepting your offer?\nCost: 5000 TL"
	dialog.ok_button_text = "Yes (Pay 5000 TL)"
	dialog.cancel_button_text = "No"
	
	dialog.min_size = Vector2(650, 200)
	var lbl = dialog.get_label()
	if lbl:
		lbl.add_theme_font_size_override("font_size", 20)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	dialog.get_ok_button().add_theme_font_size_override("font_size", 18)
	dialog.get_ok_button().custom_minimum_size = Vector2(180, 50)
	dialog.get_cancel_button().add_theme_font_size_override("font_size", 18)
	dialog.get_cancel_button().custom_minimum_size = Vector2(100, 50)
	
	dialog.confirmed.connect(func():
		if GameState.money >= 5000:
			GameState.money -= 5000
			GameState.sponsor_intelligence_bought = true
			_reveal_intelligence()
	)
	
	add_child(dialog)
	dialog.popup_centered()

func _reveal_intelligence() -> void:
	for node in secret_nodes:
		if is_instance_valid(node):
			node.visible = true

func _process(_delta: float) -> void:
	money_label.text = "Budget: " + str(GameState.money) + " TL"
	attempts_label.text = "Negotiations Left: " + str(GameState.sponsor_attempts_left)

func _setup_ui_styles() -> void:
	var main_style = StyleBoxFlat.new()
	main_style.bg_color = Color(0.05, 0.07, 0.1, 0.95)
	main_style.border_width_left = 4
	main_style.border_color = Color(0.1, 0.7, 1.0)
	add_theme_stylebox_override("panel", main_style)

	var side_style = StyleBoxFlat.new()
	side_style.bg_color = Color(0.1, 0.12, 0.15, 0.8)
	side_style.border_width_left = 1
	side_style.border_color = Color(0.2, 0.4, 0.6)
	$MarginContainer/VBoxContainer/MainContent/RightSummary/SummaryPanel.add_theme_stylebox_override("panel", side_style)

func create_sponsors() -> void:
	for c in sponsor_list.get_children():
		c.queue_free()
	secret_nodes.clear()

	for id in sponsor_defs.keys():
		var s = sponsor_defs[id]
		var is_accepted = id in GameState.accepted_sponsors
		
		var card = _create_sponsor_card(id, s, is_accepted)
		sponsor_list.add_child(card)

func _create_sponsor_card(id: String, s: Dictionary, is_accepted: bool) -> PanelContainer:
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 100)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.18, 0.25, 0.7)
	style.border_width_left = 4
	style.border_color = Color(0.0, 0.8, 1.0) if not is_accepted else Color(0.0, 1.0, 0.0)
	card.add_theme_stylebox_override("panel", style)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 15)
	card.add_child(hbox)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 15)
	margin.add_theme_constant_override("margin_right", 15)
	hbox.add_child(margin)

	var cb = CheckBox.new()
	cb.name = "CheckBox"
	cb.button_pressed = is_accepted
	cb.disabled = is_accepted
	cb.set_meta("id", id)
	hbox.add_child(cb)

	var v_info = VBoxContainer.new()
	v_info.size_flags_horizontal = SIZE_EXPAND_FILL
	hbox.add_child(v_info)

	var name_lbl = Label.new()
	name_lbl.text = s["display_name"]
	name_lbl.add_theme_font_size_override("font_size", 20)
	v_info.add_child(name_lbl)
	
	var grant_lbl = Label.new()
	grant_lbl.text = "GRANT: " + str(s["price"]) + " TL"
	grant_lbl.add_theme_font_size_override("font_size", 18)
	grant_lbl.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
	v_info.add_child(grant_lbl)

	# Branding demands info
	var branding_lbl = Label.new()
	branding_lbl.text = "Logo: " + str(s["branding_logo_placement"]) + " | Area: " + str(s["branding_area_demand"]) + " | Audience: " + str(s["target_audience_compatibility"])
	branding_lbl.add_theme_font_size_override("font_size", 16)
	branding_lbl.modulate = Color(0.7, 0.7, 0.7)
	v_info.add_child(branding_lbl)

	# Conflict info
	var conflict_brands = s.get("conflict_brands", [])
	if conflict_brands.size() > 0:
		var conflict_names = []
		for cid in conflict_brands:
			if sponsor_defs.has(cid):
				conflict_names.append(sponsor_defs[cid]["display_name"])
			else:
				conflict_names.append(cid)
		var conflict_lbl = Label.new()
		conflict_lbl.text = "⚠ Conflict: " + ", ".join(conflict_names)
		conflict_lbl.add_theme_font_size_override("font_size", 16)
		conflict_lbl.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
		v_info.add_child(conflict_lbl)

	var v_stats = VBoxContainer.new()
	v_stats.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_child(v_stats)

	var score = s.get("sponsor_score", 0.0)
	var score_lbl = Label.new()
	score_lbl.text = "SCORE: " + str(snapped(score, 0.01))
	score_lbl.add_theme_font_size_override("font_size", 18)
	v_stats.add_child(score_lbl)

	var success_lbl = Label.new()
	success_lbl.text = str(int(s["acceptance"] * 100)) + "% CHANCE"
	success_lbl.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))
	success_lbl.add_theme_font_size_override("font_size", 16)
	v_stats.add_child(success_lbl)
	
	if not GameState.sponsor_intelligence_bought:
		success_lbl.visible = false
		
	secret_nodes.append(success_lbl)

	return card

func get_selected() -> Array:
	var arr = []
	for card in sponsor_list.get_children():
		var cb = card.find_child("CheckBox", true, false)
		if cb and cb.button_pressed and not cb.disabled:
			arr.append(cb.get_meta("id"))
	return arr

func _on_check_pressed() -> void:
	if GameState.sponsor_attempts_left <= 0:
		result_label.text = "DEAL REJECTED: Out of attempts."
		return

	var selected = get_selected()
	if selected.is_empty():
		result_label.text = "NO PROPOSAL: Select a sponsor first."
		return
	
	# Conflict Check
	for i in range(selected.size()):
		for j in range(i + 1, selected.size()):
			var conflicts_i = sponsor_defs[selected[i]].get("conflict_brands", [])
			if selected[j] in conflicts_i:
				result_label.text = "CONFLICT: " + sponsor_defs[selected[i]]["display_name"] + " and " + sponsor_defs[selected[j]]["display_name"] + " cannot be together."
				return
			var conflicts_j = sponsor_defs[selected[j]].get("conflict_brands", [])
			if selected[i] in conflicts_j:
				result_label.text = "CONFLICT: " + sponsor_defs[selected[j]]["display_name"] + " and " + sponsor_defs[selected[i]]["display_name"] + " cannot be together."
				return

	# Score Check (Aim to keep average > 2)
	var avg_score = 0.0
	for id in selected:
		var s = sponsor_defs[id]
		avg_score += s.get("sponsor_score", 0.0)
	avg_score /= selected.size()

	if avg_score < 2.0:
		result_label.text = "PROPOSAL REJECTED: Average score is too low (" + str(snapped(avg_score, 0.01)) + "). Aim for > 2.0."
		return

	var results = GameState.process_sponsor_acceptance(selected, sponsor_defs)
	var accepted = results["accepted"]
	
	if accepted.size() > 0:
		result_label.text = "SUCCESS! Signed " + str(accepted.size()) + " deal(s)."
	else:
		result_label.text = "ALL REJECTED: Keep trying!"

	create_sponsors()
	refresh_ui()

func refresh_ui() -> void:
	var signed_text = ""
	var total_grant = 0
	for id in GameState.accepted_sponsors:
		if sponsor_defs.has(id):
			signed_text += "✓ " + sponsor_defs[id]["display_name"] + " (" + str(sponsor_defs[id]["price"]) + " TL)\n"
			total_grant += int(sponsor_defs[id]["price"])
	
	if signed_text == "": signed_text = "No deals signed."
	signed_list_label.text = signed_text + "\n\nSecured: " + str(total_grant) + " TL"

func _on_back_pressed() -> void:
	GameState.complete_activity("sponsor_management")
	hide()
	if get_parent().has_node("ActivityBoard"):
		get_parent().get_node("ActivityBoard").show()
		get_parent().get_node("ActivityBoard").refresh_board()

func _setup_guide_text() -> void:
	guide_label.text = "\n\nACTIVITY GUIDE\n\n" + \
		"How to Negotiate:\n" + \
		"• Select sponsors based on your strategy.\n" + \
		"• Click 'NEGOTIATE DEAL' to see which sponsors accept or reject your offer.\n" + \
		"• If some sponsors reject: You can reselect and try again (up to 2 additional attempts).\n" + \
		"• Sponsors that have already been accepted will remain fixed and cannot be changed.\n\n" + \
		"Sponsor Card Info:\n" + \
		"• GRANT: The amount the sponsor will contribute to your budget.\n" + \
		"• Logo Placement: How much branding space the sponsor demands for logo.\n" + \
		"• Area Demand: How much festival area the sponsor requires.\n" + \
		"• Audience Compatibility: How well the sponsor fits your target audience (1-5).\n" + \
		"• Conflict: Some brands cannot appear together.\n\n" + \
		"Key Constraints & Rules:\n" + \
		"• Not all selected sponsors will accept your offer immediately.\n" + \
		"• You can retry selection up to 2 times after rejections.\n" + \
		"• Accepted sponsors are locked in your portfolio.\n" + \
		"• Conflict Check: Some brands are competitors and cannot be selected together.\n" + \
		"• Target Score: Aim to keep your average sponsor score above 2.0."
