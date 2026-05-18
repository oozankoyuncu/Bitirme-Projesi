extends Control

# ---------------- DATA ----------------
var cleaning_crews = {}
var security_teams = {}

# ---------------- UI REFS ----------------
@onready var cleaning_list: VBoxContainer = $MarginContainer/VBoxContainer/MainContent/LeftPalette/LeftScroll/CleaningList
@onready var security_list: VBoxContainer = $MarginContainer/VBoxContainer/MainContent/RightPalette/RightScroll/SecurityList
@onready var selected_teams_list: GridContainer = $MarginContainer/VBoxContainer/MainContent/CenterDashboard/VBoxContainer/SelectedTeamsScroll/CenterContainer/SelectedTeamsList

@onready var result_label: Label = $MarginContainer/VBoxContainer/MainContent/CenterDashboard/VBoxContainer/ResultLabel
@onready var score_label: Label = $MarginContainer/VBoxContainer/MainContent/CenterDashboard/VBoxContainer/ScoreLabel
@onready var money_label: Label = $MarginContainer/VBoxContainer/Footer/MoneyBox/MoneyLabel
@onready var space_label: Label = $MarginContainer/VBoxContainer/Footer/SpaceBox/SpaceLabel
@onready var space_bar: ProgressBar = $MarginContainer/VBoxContainer/Footer/SpaceBox/SpaceBar
@onready var confirm_btn: Button = $MarginContainer/VBoxContainer/Footer/ConfirmButton
@onready var back_btn: Button = $MarginContainer/VBoxContainer/Footer/BackButton

@onready var info_btn: Button = $MarginContainer/VBoxContainer/Header/InfoButton
@onready var guide_panel: PanelContainer = $GuidePanel
@onready var guide_label: Label = $GuidePanel/MarginContainer/VBoxContainer/ScrollContainer/GuideLabel
@onready var close_guide_btn: Button = $GuidePanel/MarginContainer/VBoxContainer/Header/CloseGuideButton

var selected_cleaning_ids: Array = []
var selected_security_ids: Array = []

# ---------------- LOGIC ----------------

func _ready() -> void:
	_load_data()
	confirm_btn.pressed.connect(_on_confirm_pressed)
	back_btn.pressed.connect(_on_back_pressed)
	info_btn.pressed.connect(func(): guide_panel.show())
	close_guide_btn.pressed.connect(func(): guide_panel.hide())

	_setup_guide_text()
	_setup_ui_styles()
	
	_create_team_cards()
	_refresh_ui()

func _load_data() -> void:
	var file = FileAccess.open("res://data/cleaning_security.json", FileAccess.READ)
	if file == null:
		print("ERROR: cleaning_security.json could not be opened")
		return
	
	var content = file.get_as_text()
	file.close()
	
	var data = JSON.parse_string(content)
	if data == null:
		print("ERROR: Failed to parse cleaning_security.json")
		return
	
	if data.has("cleaning_crews"):
		cleaning_crews = data["cleaning_crews"]
	if data.has("security_teams"):
		security_teams = data["security_teams"]
	print("Cleaning/Security loaded: ", cleaning_crews.size(), " crews, ", security_teams.size(), " teams")

func _process(_delta: float) -> void:
	_update_live_stats()

func _setup_ui_styles() -> void:
	var main_style = StyleBoxFlat.new()
	main_style.bg_color = Color(0.05, 0.08, 0.12, 0.95)
	main_style.border_width_left = 4
	main_style.border_color = Color(1.0, 0.5, 0.0) # Operations Orange
	add_theme_stylebox_override("panel", main_style)

	var dash_style = StyleBoxFlat.new()
	dash_style.bg_color = Color(0.1, 0.15, 0.2, 0.8)
	dash_style.border_width_top = 2
	dash_style.border_color = Color(0.3, 0.5, 0.7)
	$MarginContainer/VBoxContainer/MainContent/CenterDashboard.add_theme_stylebox_override("panel", dash_style)

func _create_team_cards() -> void:
	for c in cleaning_list.get_children(): c.queue_free()
	for c in security_list.get_children(): c.queue_free()

	# Sort keys to maintain order
	var clean_keys = cleaning_crews.keys()
	clean_keys.sort()
	for id in clean_keys:
		cleaning_list.add_child(_create_card(id, cleaning_crews[id], true))
	
	var sec_keys = security_teams.keys()
	sec_keys.sort()
	for id in sec_keys:
		security_list.add_child(_create_card(id, security_teams[id], false))

func _create_card(id: String, team: Dictionary, is_cleaning: bool) -> PanelContainer:
	var card = PanelContainer.new()
	# Size boosted significantly for better visibility
	card.custom_minimum_size = Vector2(0, 180)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.2, 0.25, 0.8)
	style.border_width_left = 6 
	style.border_color = Color(0.0, 0.8, 1.0)
	card.add_theme_stylebox_override("panel", style)

	var hbox = HBoxContainer.new()
	card.add_child(hbox)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	hbox.add_child(margin)

	var cb = CheckBox.new()
	cb.name = "CheckBox"
	cb.toggled.connect(func(pressed): _on_team_toggled(id, pressed, is_cleaning, card))
	cb.scale = Vector2(1.5, 1.5) # Bigger checkbox
	margin.add_child(cb)

	var v_info = VBoxContainer.new()
	v_info.size_flags_horizontal = SIZE_EXPAND_FILL
	v_info.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_child(v_info)

	var name_lbl = Label.new()
	name_lbl.text = team["name"]
	name_lbl.add_theme_font_size_override("font_size", 28) # Much larger font
	v_info.add_child(name_lbl)

	var stats_lbl = Label.new()
	stats_lbl.text = "Speed: %d | Reliability: %d | Space: %d sqm" % [int(team["speed"]), int(team["reliability"]), int(team["space"])]
	stats_lbl.add_theme_font_size_override("font_size", 18)
	stats_lbl.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	v_info.add_child(stats_lbl)

	var score_lbl = Label.new()
	score_lbl.text = "Score: " + str(snapped(team.get("score", 0.0), 0.01))
	score_lbl.add_theme_font_size_override("font_size", 18)
	score_lbl.add_theme_color_override("font_color", Color(0.5, 0.9, 1.0))
	v_info.add_child(score_lbl)

	var cost_lbl = Label.new()
	cost_lbl.text = "Daily Cost: " + str(int(team["cost"])) + " TL"
	cost_lbl.add_theme_font_size_override("font_size", 18)
	cost_lbl.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
	v_info.add_child(cost_lbl)

	return card

func _on_team_toggled(id: String, pressed: bool, is_cleaning: bool, card: PanelContainer) -> void:
	var list = selected_cleaning_ids if is_cleaning else selected_security_ids
	if pressed:
		if not list.has(id): list.append(id)
		card.get_theme_stylebox("panel").bg_color = Color(0.1, 0.4, 0.3, 0.9)
	else:
		list.erase(id)
		card.get_theme_stylebox("panel").bg_color = Color(0.15, 0.2, 0.25, 0.8)
	
	_refresh_ui()

func _update_live_stats() -> void:
	money_label.text = "Available Budget: " + str(GameState.money) + " TL"
	
	var total_space = 0
	for id in selected_cleaning_ids: total_space += int(cleaning_crews[id]["space"])
	for id in selected_security_ids: total_space += int(security_teams[id]["space"])
	
	space_label.text = "On-Site Footprint: %d / %d Units" % [total_space, GameState.max_site_space]
	space_bar.max_value = GameState.max_site_space
	space_bar.value = total_space
	
	if total_space > GameState.max_site_space:
		space_label.add_theme_color_override("font_color", Color.RED)
	else:
		space_label.add_theme_color_override("font_color", Color.WHITE)

func _refresh_ui() -> void:
	# Refresh selected teams list in the center
	for child in selected_teams_list.get_children():
		child.queue_free()
	
	for id in selected_cleaning_ids:
		_add_selected_entry(cleaning_crews[id]["name"], "Cleaning", Color(0.4, 1.0, 0.4))
	for id in selected_security_ids:
		_add_selected_entry(security_teams[id]["name"], "Security", Color(0.4, 0.7, 1.0))

	var total_cost = 0
	var avg_speed = 0.0
	var avg_rel = 0.0
	var total_space = 0.0
	var count = selected_cleaning_ids.size() + selected_security_ids.size()

	for id in selected_cleaning_ids:
		var t = cleaning_crews[id]
		total_cost += int(t["cost"])
		avg_speed += t["speed"]
		avg_rel += t["reliability"]
		total_space += int(t["space"])

	for id in selected_security_ids:
		var t = security_teams[id]
		total_cost += int(t["cost"])
		avg_speed += t["speed"]
		avg_rel += t["reliability"]
		total_space += int(t["space"])

	if count > 0:
		avg_speed /= count
		avg_rel /= count
		var score = (avg_speed * 0.5 + avg_rel * 0.5) / (total_space * 0.1 / count if total_space > 0 else 1.0)
		score_label.text = "Deployment Excellence Score: " + str(snapped(score, 0.1))
	else:
		score_label.text = "Deployment Excellence Score: 0.0"

	_validate_requirements()

func _add_selected_entry(team_name: String, type: String, color: Color) -> void:
	var entry = PanelContainer.new()
	# Center cards boosted to be much larger ("biraz da büyüt")
	entry.custom_minimum_size = Vector2(240, 160)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.15, 0.2, 0.95)
	style.border_width_bottom = 5
	style.border_color = color
	style.set_corner_radius_all(8)
	entry.add_theme_stylebox_override("panel", style)
	
	var v_box = VBoxContainer.new()
	v_box.alignment = BoxContainer.ALIGNMENT_CENTER
	entry.add_child(v_box)
	
	var name_lbl = Label.new()
	name_lbl.text = team_name
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 22)
	v_box.add_child(name_lbl)
	
	var type_lbl = Label.new()
	type_lbl.text = type.to_upper()
	type_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	type_lbl.add_theme_color_override("font_color", color)
	type_lbl.add_theme_font_size_override("font_size", 18)
	v_box.add_child(type_lbl)
	
	selected_teams_list.add_child(entry)

func _validate_requirements() -> void:
	var has_clean = selected_cleaning_ids.size() >= 1
	var has_sec = selected_security_ids.size() >= 1
	var total_space = 0
	for id in selected_cleaning_ids: total_space += int(cleaning_crews[id]["space"])
	for id in selected_security_ids: total_space += int(security_teams[id]["space"])
	
	var space_ok = total_space <= GameState.max_site_space
	
	var msg = ""
	if not has_clean: msg += "• Minimum 1 Cleaning Crew required.\n"
	if not has_sec: msg += "• Minimum 1 Security Team required.\n"
	if not space_ok: msg += "• SITE AREA CRITICAL: Footprint exceeds limits!\n"
	
	if msg == "":
		result_label.text = "Status: READY FOR DEPLOYMENT"
		result_label.add_theme_color_override("font_color", Color.GREEN)
		confirm_btn.disabled = false
	else:
		result_label.text = "Status: OPERATIONS BLOCKED\n" + msg
		result_label.add_theme_color_override("font_color", Color.CORAL)
		confirm_btn.disabled = true

func _on_confirm_pressed() -> void:
	GameState.selected_cleaning_teams = selected_cleaning_ids.duplicate()
	GameState.selected_security_teams = selected_security_ids.duplicate()
	GameState.complete_activity("festival_cleaning_security")
	_on_back_pressed()

func _on_back_pressed() -> void:
	hide()
	if get_parent().has_node("ActivityBoard"):
		get_parent().get_node("ActivityBoard").show()
		get_parent().get_node("ActivityBoard").refresh_board()

func _setup_guide_text() -> void:
	guide_label.text = "\n\nACTIVITY GUIDE: FESTIVAL CLEANING & SECURITY\n\n" + \
		"Activity Overview:\n" + \
		"Select the teams responsible for maintenance and safety during the festival.\n\n" + \
		"Your Objective:\n" + \
		"• Maintain a clean and safe environment.\n" + \
		"• Balance performance with cost and space constraints.\n\n" + \
		"How Calculations Work:\n" + \
		"• Higher speed and reliability increase the score.\n" + \
		"• Higher space occupation and costs reduce total efficiency.\n\n" + \
		"Attributes:\n" + \
		"• Service Speed: How quickly tasks are completed.\n" + \
		"• Reliability: Consistency and lack of failures.\n" + \
		"• Space Needs: Physical footprint on-site.\n\n" + \
		"Key Constraints:\n" + \
		"• MUST select at least 1 Cleaning Crew and 1 Security Team.\n" + \
		"• Total Space must stay within " + str(GameState.max_site_space) + " units.\n" + \
		"• Total Cost must be within budget."
