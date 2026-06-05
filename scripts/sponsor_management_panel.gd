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
@onready var finish_button: Button = $MarginContainer/VBoxContainer/Footer/FinishButton

@onready var info_btn: Button = $MarginContainer/VBoxContainer/Header/InfoButton
@onready var guide_panel: PanelContainer = $GuidePanel
@onready var guide_label: Label = $GuidePanel/MarginContainer/VBoxContainer/ScrollContainer/GuideLabel
@onready var close_guide_btn: Button = $GuidePanel/MarginContainer/VBoxContainer/Header/CloseGuideButton

# ---------------- LOGIC ----------------

var secret_nodes: Array = []
var _popup_timer_started: bool = false
var all_conflicts: Dictionary = {}

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
	_load_sponsors()
	
	check_button.pressed.connect(_on_check_pressed)
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
	
	# Build bidirectional conflict map
	all_conflicts.clear()
	for id in sponsor_defs.keys():
		all_conflicts[id] = []
	for id in sponsor_defs.keys():
		var conflicts = sponsor_defs[id].get("conflict_brands", [])
		for cid in conflicts:
			if sponsor_defs.has(cid):
				if not cid in all_conflicts[id]:
					all_conflicts[id].append(cid)
				if not id in all_conflicts[cid]:
					all_conflicts[cid].append(id)

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
	dialog.dialog_text = "Would you like to purchase intelligence data to see the true probability (CHANCE) of each sponsor accepting your offer?\nCost: 10000 TL"
	dialog.ok_button_text = "Yes (Pay 10000 TL)"
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
		if GameState.money >= 10000:
			GameState.money -= 10000
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

	sponsor_list.mouse_filter = Control.MOUSE_FILTER_PASS
	sponsor_list.get_parent().mouse_filter = Control.MOUSE_FILTER_PASS

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
	card.mouse_filter = Control.MOUSE_FILTER_PASS
	
	# Check for conflicts with already accepted/signed sponsors
	var has_conflict_with_accepted = false
	for accepted_id in GameState.accepted_sponsors:
		if accepted_id in all_conflicts.get(id, []):
			has_conflict_with_accepted = true
			break
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.18, 0.25, 0.7)
	style.border_width_left = 4
	if is_accepted:
		style.border_color = Color(0.0, 1.0, 0.0) # Signed/accepted green
	elif has_conflict_with_accepted:
		style.border_color = Color(0.8, 0.2, 0.2) # Conflict red
		style.bg_color = Color(0.1, 0.1, 0.1, 0.5) # Darkened background
	else:
		style.border_color = Color(0.0, 0.8, 1.0) # Standard blue
	card.add_theme_stylebox_override("panel", style)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 15)
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(hbox)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 15)
	margin.add_theme_constant_override("margin_right", 15)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(margin)

	var cb = CheckBox.new()
	cb.name = "CheckBox"
	cb.button_pressed = is_accepted
	cb.disabled = is_accepted or has_conflict_with_accepted
	cb.set_meta("id", id)
	hbox.add_child(cb)

	var v_info = VBoxContainer.new()
	v_info.size_flags_horizontal = SIZE_EXPAND_FILL
	v_info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(v_info)

	var name_lbl = Label.new()
	name_lbl.text = s["display_name"]
	name_lbl.add_theme_font_size_override("font_size", 20)
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v_info.add_child(name_lbl)
	
	var grant_lbl = Label.new()
	grant_lbl.text = "GRANT: " + str(s["price"]) + " TL"
	grant_lbl.add_theme_font_size_override("font_size", 18)
	grant_lbl.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
	grant_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v_info.add_child(grant_lbl)

	# Branding demands info
	var branding_lbl = Label.new()
	branding_lbl.text = "Logo: " + str(s["branding_logo_placement"]) + " | Area: " + str(s["branding_area_demand"]) + " | Audience: " + str(s["target_audience_compatibility"])
	branding_lbl.add_theme_font_size_override("font_size", 16)
	branding_lbl.modulate = Color(0.7, 0.7, 0.7)
	branding_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v_info.add_child(branding_lbl)

	# Conflict info (using bidirectional conflicts)
	var conflicts = all_conflicts.get(id, [])
	if conflicts.size() > 0:
		var conflict_names = []
		for cid in conflicts:
			if sponsor_defs.has(cid):
				conflict_names.append(sponsor_defs[cid]["display_name"])
			else:
				conflict_names.append(cid)
		var conflict_lbl = Label.new()
		conflict_lbl.text = "⚠ Conflict: " + ", ".join(conflict_names)
		conflict_lbl.add_theme_font_size_override("font_size", 16)
		conflict_lbl.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
		conflict_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v_info.add_child(conflict_lbl)

	var v_stats = VBoxContainer.new()
	v_stats.alignment = BoxContainer.ALIGNMENT_CENTER
	v_stats.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(v_stats)

	var score = s.get("sponsor_score", 0.0)
	var score_lbl = Label.new()
	score_lbl.text = "SCORE: " + str(snapped(score, 0.01))
	score_lbl.add_theme_font_size_override("font_size", 18)
	score_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v_stats.add_child(score_lbl)

	var success_lbl = Label.new()
	success_lbl.text = str(int(s["acceptance"] * 100)) + "% CHANCE"
	success_lbl.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))
	success_lbl.add_theme_font_size_override("font_size", 16)
	success_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
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
	
	# Conflict Check within selected sponsors
	for i in range(selected.size()):
		for j in range(i + 1, selected.size()):
			if selected[j] in all_conflicts.get(selected[i], []):
				result_label.text = "CONFLICT: " + sponsor_defs[selected[i]]["display_name"] + " and " + sponsor_defs[selected[j]]["display_name"] + " cannot be together."
				return

	# Conflict Check with already signed sponsors
	for id in selected:
		for accepted_id in GameState.accepted_sponsors:
			if accepted_id in all_conflicts.get(id, []):
				result_label.text = "CONFLICT: " + sponsor_defs[id]["display_name"] + " conflicts with already signed " + sponsor_defs[accepted_id]["display_name"] + "."
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
		"• Conflict Check: Some brands are competitors and cannot be selected together."

func _on_finish_pressed() -> void:
	GameState.complete_activity("sponsor_management")
	hide()
	if get_parent().has_node("ActivityBoard"):
		get_parent().get_node("ActivityBoard").show()
		get_parent().get_node("ActivityBoard").refresh_board()
