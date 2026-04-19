extends Control

# ---------------- DATA ----------------
var sponsor_defs = {
	"techcorp": {
		"display_name": "TechCorp",
		"price": 5000,
		"contribution": 5,
		"audience": 4,
		"logo": 3,
		"area": 2,
		"acceptance": 0.8,
		"conflicts": ["soundmax"],
		"desc": "Leading tech solutions provider."
	},
	"soundmax": {
		"display_name": "SoundMax",
		"price": 4500,
		"contribution": 4,
		"audience": 5,
		"logo": 4,
		"area": 3,
		"acceptance": 0.6,
		"conflicts": ["techcorp"],
		"desc": "Premium audio equipment."
	},
	"greenbite": {
		"display_name": "GreenBite",
		"price": 2500,
		"contribution": 3,
		"audience": 5,
		"logo": 1,
		"area": 1,
		"acceptance": 0.9,
		"conflicts": [],
		"desc": "Eco-friendly snacks and drinks."
	},
	"bluenetwork": {
		"display_name": "BlueNetwork",
		"price": 6000,
		"contribution": 4,
		"audience": 4,
		"logo": 4,
		"area": 2,
		"acceptance": 0.75,
		"conflicts": ["globallogistics"],
		"desc": "Telecommunications provider."
	},
	"redenergy": {
		"display_name": "RedEnergy",
		"price": 3500,
		"contribution": 5,
		"audience": 3,
		"logo": 2,
		"area": 2,
		"acceptance": 0.85,
		"conflicts": [],
		"desc": "Dynamic energy drinks."
	},
	"silverauto": {
		"display_name": "SilverAuto",
		"price": 8000,
		"contribution": 3,
		"audience": 5,
		"logo": 5,
		"area": 4,
		"acceptance": 0.55,
		"conflicts": [],
		"desc": "Luxury vehicle displays."
	},
	"goldfashion": {
		"display_name": "GoldFashion",
		"price": 4000,
		"contribution": 3,
		"audience": 2,
		"logo": 3,
		"area": 3,
		"acceptance": 0.8,
		"conflicts": [],
		"desc": "High-end apparel." # Score: 1.7
	},
	"urbanwear": {
		"display_name": "UrbanWear",
		"price": 2000,
		"contribution": 2,
		"audience": 3,
		"logo": 4,
		"area": 4,
		"acceptance": 0.95,
		"conflicts": [],
		"desc": "Street style clothing." # Score: 1.4
	},
	"globallogistics": {
		"display_name": "GlobalLogistics",
		"price": 7000,
		"contribution": 5,
		"audience": 2,
		"logo": 4,
		"area": 5,
		"acceptance": 0.7,
		"conflicts": ["bluenetwork"],
		"desc": "Transport solutions."
	}
}

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

func _ready() -> void:
	check_button.pressed.connect(_on_check_pressed)
	back_button.pressed.connect(_on_back_pressed)
	info_btn.pressed.connect(func(): guide_panel.show())
	close_guide_btn.pressed.connect(func(): guide_panel.hide())

	_setup_guide_text()
	_setup_ui_styles()
	
	create_sponsors()
	refresh_ui()

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
	grant_lbl.text = "GRANT: $" + str(s["price"])
	grant_lbl.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
	v_info.add_child(grant_lbl)

	var v_stats = VBoxContainer.new()
	v_stats.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_child(v_stats)

	var score = (0.5 * s["contribution"]) + (0.4 * s["audience"]) - (0.1 * (s["logo"] + s["area"]))
	var score_lbl = Label.new()
	score_lbl.text = "SCORE: " + str(snapped(score, 0.1))
	score_lbl.add_theme_font_size_override("font_size", 14)
	v_stats.add_child(score_lbl)

	var success_lbl = Label.new()
	success_lbl.text = str(int(s["acceptance"] * 100)) + "% CHANCE"
	success_lbl.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))
	success_lbl.add_theme_font_size_override("font_size", 12)
	v_stats.add_child(success_lbl)

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
			if selected[j] in sponsor_defs[selected[i]].get("conflicts", []):
				result_label.text = "CONFLICT: " + sponsor_defs[selected[i]]["display_name"] + " and " + sponsor_defs[selected[j]]["display_name"] + " cannot be together."
				return

	# Score Check (Aim to keep average > 2)
	var avg_score = 0.0
	for id in selected:
		var s = sponsor_defs[id]
		avg_score += (0.5 * s["contribution"]) + (0.4 * s["audience"]) - (0.1 * (s["logo"] + s["area"]))
	avg_score /= selected.size()

	if avg_score < 2.0:
		result_label.text = "PROPOSAL REJECTED: Average score is too low (" + str(snapped(avg_score, 0.1)) + "). Aim for > 2.0."
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
		signed_text += "✓ " + sponsor_defs[id]["display_name"] + " ($" + str(sponsor_defs[id]["price"]) + ")\n"
		total_grant += sponsor_defs[id]["price"]
	
	if signed_text == "": signed_text = "No deals signed."
	signed_list_label.text = signed_text + "\n\nSecured: $" + str(total_grant)

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
		"Key Constraints & Rules:\n" + \
		"• Not all selected sponsors will accept your offer immediately.\n" + \
		"• You can retry selection up to 2 times after rejections.\n" + \
		"• Accepted sponsors are locked in your portfolio.\n" + \
		"• Conflict Check: Some brands are competitors and cannot be selected together.\n" + \
		"• Target Score: Aim to keep your average sponsor score above 2.0."
