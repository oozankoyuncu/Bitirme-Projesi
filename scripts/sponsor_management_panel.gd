extends Control

# ---------------- SPONSORS ----------------
var sponsor_defs = {
	"techcorp": {
		"display_name": "TechCorp",
		"price": 5000,
		"contribution": 5,
		"audience": 4,
		"logo": 3,
		"area": 2,
		"acceptance": 0.8,
		"conflicts": ["soundmax"]
	},
	"soundmax": {
		"display_name": "SoundMax",
		"price": 4500,
		"contribution": 4,
		"audience": 5,
		"logo": 4,
		"area": 3,
		"acceptance": 0.6,
		"conflicts": ["techcorp"]
	},
	"greenbite": {
		"display_name": "GreenBite",
		"price": 2500,
		"contribution": 3,
		"audience": 5,
		"logo": 1,
		"area": 1,
		"acceptance": 0.9,
		"conflicts": []
	}
}

# ---------------- UI ----------------
@onready var sponsor_list = $MarginContainer/VBoxContainer/SponsorList
@onready var result_label = $MarginContainer/VBoxContainer/ResultLabel
@onready var money_label = $MarginContainer/VBoxContainer/MoneyLabel
@onready var check_button = $MarginContainer/VBoxContainer/CheckButton
@onready var back_button = $MarginContainer/VBoxContainer/BackButton

var card_style_normal: StyleBoxFlat
var card_style_hover: StyleBoxFlat
var card_style_accepted: StyleBoxFlat

# ---------------- READY ----------------
func _ready():
	_init_styles()
	
	check_button.pressed.connect(_on_check_pressed)
	back_button.pressed.connect(_on_back_pressed)
	
	# Main Panel Styling
	var main_style = StyleBoxFlat.new()
	main_style.bg_color = Color(0.1, 0.1, 0.12) # Deep Dark
	main_style.border_width_top = 2
	main_style.border_color = Color(0.1, 0.7, 1.0, 0.5) # Glow effect top
	add_theme_stylebox_override("panel", main_style)

	# --- Estetik / UX Ayarları ---
	var title: Label = $MarginContainer/VBoxContainer/TitleLabel if has_node("MarginContainer/VBoxContainer/TitleLabel") else null
	if title:
		title.text = "SPONSOR MANAGEMENT"
		title.add_theme_font_size_override("font_size", 42)
		title.add_theme_color_override("font_color", Color(0.1, 0.7, 1.0)) # Modern Blue
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		# Shadow logic for title
		title.add_theme_constant_override("shadow_offset_x", 2)
		title.add_theme_constant_override("shadow_offset_y", 2)
		title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.5))

	var desc: Label = $MarginContainer/VBoxContainer/DescriptionLabel if has_node("MarginContainer/VBoxContainer/DescriptionLabel") else null
	if desc:
		desc.text = "Negotiate with potential sponsors to fund your festival. Watch out for conflicts!"
		desc.add_theme_font_size_override("font_size", 18)
		desc.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	money_label.add_theme_font_size_override("font_size", 28)
	money_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4)) # Budget Green
	money_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	result_label.add_theme_font_size_override("font_size", 20)
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	
	# Button Styling
	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = Color(0.2, 0.2, 0.25)
	btn_style.corner_radius_top_left = 8
	btn_style.corner_radius_top_right = 8
	btn_style.corner_radius_bottom_left = 8
	btn_style.corner_radius_bottom_right = 8
	btn_style.content_margin_top = 10
	btn_style.content_margin_bottom = 10
	
	check_button.add_theme_stylebox_override("normal", btn_style)
	check_button.add_theme_font_size_override("font_size", 24)
	
	back_button.add_theme_font_size_override("font_size", 20)
	
	sponsor_list.add_theme_constant_override("separation", 15)
	
	var margin: MarginContainer = $MarginContainer
	margin.add_theme_constant_override("margin_top", 40)
	margin.add_theme_constant_override("margin_bottom", 40)
	margin.add_theme_constant_override("margin_left", 80)
	margin.add_theme_constant_override("margin_right", 80)
	
	$MarginContainer/VBoxContainer.add_theme_constant_override("separation", 20)

	create_sponsors()
	refresh_ui()

func _init_styles():
	card_style_normal = StyleBoxFlat.new()
	card_style_normal.bg_color = Color(0.15, 0.15, 0.18)
	card_style_normal.border_width_left = 4
	card_style_normal.border_color = Color(0.3, 0.3, 0.35)
	card_style_normal.corner_radius_top_right = 10
	card_style_normal.corner_radius_bottom_right = 10
	card_style_normal.content_margin_left = 15
	card_style_normal.content_margin_right = 15
	card_style_normal.content_margin_top = 10
	card_style_normal.content_margin_bottom = 10

	card_style_hover = card_style_normal.duplicate()
	card_style_hover.bg_color = Color(0.18, 0.18, 0.22)
	card_style_hover.border_color = Color(0.2, 0.6, 1.0) # Hover Highlight Blue

	card_style_accepted = card_style_normal.duplicate()
	card_style_accepted.bg_color = Color(0.1, 0.25, 0.1)
	card_style_accepted.border_color = Color(0.0, 0.8, 0.2)

# ---------------- CREATE UI ----------------
func create_sponsors():
	for c in sponsor_list.get_children():
		c.queue_free()

	for id in sponsor_defs.keys():
		var s = sponsor_defs[id]
		var is_accepted = id in GameState.accepted_sponsors
		
		var card = PanelContainer.new()
		card.add_theme_stylebox_override("panel", card_style_accepted if is_accepted else card_style_normal)
		card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		
		if not is_accepted:
			card.mouse_entered.connect(func(): card.add_theme_stylebox_override("panel", card_style_hover))
			card.mouse_exited.connect(func(): card.add_theme_stylebox_override("panel", card_style_normal))

		var h_box = HBoxContainer.new()
		h_box.name = "HBoxContainer"
		h_box.add_theme_constant_override("separation", 20)
		card.add_child(h_box)

		# Checkbox / Status Icon
		var cb = CheckBox.new()
		cb.name = "CheckBox"
		cb.button_pressed = is_accepted
		cb.disabled = is_accepted
		cb.set_meta("id", id)
		cb.custom_minimum_size = Vector2(40, 0)
		h_box.add_child(cb)

		# Name and Price
		var info_vbox = VBoxContainer.new()
		info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h_box.add_child(info_vbox)

		var name_label = Label.new()
		name_label.text = s["display_name"]
		name_label.add_theme_font_size_override("font_size", 24)
		info_vbox.add_child(name_label)

		var price_label = Label.new()
		price_label.text = "Grant: $" + str(s["price"])
		price_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2)) # Gold
		price_label.add_theme_font_size_override("font_size", 16)
		info_vbox.add_child(price_label)

		# Stats Column
		var stats_vbox = VBoxContainer.new()
		stats_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		h_box.add_child(stats_vbox)

		var stats_text = "Contr: %d | Aud: %d | Logo: %d | Area: %d" % [
			s["contribution"], s["audience"], s["logo"], s["area"]
		]
		var stats_label = Label.new()
		stats_label.text = stats_text
		stats_label.add_theme_font_size_override("font_size", 16)
		stats_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		stats_vbox.add_child(stats_label)

		var score_label = Label.new()
		var score = get_score(id)
		score_label.text = "Sponsor Score: " + str(snapped(score, 0.1))
		score_label.add_theme_font_size_override("font_size", 14)
		score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		stats_vbox.add_child(score_label)

		# Success Rate
		var rate_label = Label.new()
		rate_label.text = str(int(s["acceptance"] * 100)) + "% SUCCESS"
		rate_label.add_theme_font_size_override("font_size", 14)
		rate_label.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))
		rate_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		h_box.add_child(rate_label)

		if is_accepted:
			var signed_label = Label.new()
			signed_label.text = "SIGNED ✓"
			signed_label.add_theme_color_override("font_color", Color(0.0, 1.0, 0.0))
			signed_label.add_theme_font_size_override("font_size", 18)
			h_box.add_child(signed_label)

		sponsor_list.add_child(card)

# ---------------- GET SELECTED ----------------
func get_selected():
	var arr = []
	for card in sponsor_list.get_children():
		var cb = card.get_node("HBoxContainer/CheckBox")
		if cb and cb.button_pressed and not cb.disabled:
			arr.append(cb.get_meta("id"))
	return arr

# ---------------- SCORE ----------------
func get_score(id):
	var s = sponsor_defs[id]
	return (0.5 * s["contribution"]) + (0.4 * s["audience"]) - (0.1 * (s["logo"] + s["area"]))

func get_average_score(selected):
	if selected.is_empty():
		return 0.0

	var total = 0.0
	for id in selected:
		total += get_score(id)

	return total / selected.size()

# ---------------- CONFLICT ----------------
func has_conflict(selected):
	for i in range(selected.size()):
		for j in range(i + 1, selected.size()):
			if selected[j] in sponsor_defs[selected[i]]["conflicts"]:
				return true
	return false

# ---------------- CHECK BUTTON ----------------
func _on_check_pressed():

	if GameState.sponsor_attempts_left <= 0:
		result_label.text = "No attempts left!"
		return

	var selected = get_selected()

	if selected.is_empty():
		result_label.text = "Select at least one sponsor to negotiate!"
		return

	# conflict check
	if has_conflict(selected):
		result_label.text = "Conflict detected between selected sponsors!"
		return

	# score check
	var avg = get_average_score(selected)
	if avg < 2:
		result_label.text = "Deal rejected! Average sponsor score must be > 2.0 (Current: " + str(snapped(avg, 0.1)) + ")"
		return

	var results = GameState.process_sponsor_acceptance(selected, sponsor_defs)
	var accepted = results["accepted"]
	var rejected = results["rejected"]

	if accepted.size() > 0:
		result_label.text = "Deal successful! Signed: " + str(accepted)
		if rejected.size() > 0:
			result_label.text += "\nRejected: " + str(rejected)
	else:
		result_label.text = "All negotiations failed! Try different ones."

	result_label.text += "\nAttempts left: " + str(GameState.sponsor_attempts_left)

	create_sponsors()
	refresh_ui()

# ---------------- UI REFRESH ----------------
func refresh_ui():
	money_label.text = "Budget: " + str(GameState.money) + " TL"

# ---------------- BACK ----------------
func _on_back_pressed():
	hide()
	GameState.complete_activity("sponsor_management")
	if get_parent().has_node("ActivityBoard"):
		get_parent().get_node("ActivityBoard").show()
		get_parent().get_node("ActivityBoard").refresh_board()
