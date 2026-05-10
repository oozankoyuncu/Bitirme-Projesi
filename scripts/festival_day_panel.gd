extends Panel

@onready var container = $MarginContainer/VBoxContainer
@onready var active_scenarios_container = $MarginContainer/VBoxContainer/ScrollContainer/ScenariosList
@onready var detail_panel = $DetailPanel
@onready var detail_title = $DetailPanel/MarginContainer/VBoxContainer/TitleLabel
@onready var detail_desc = $DetailPanel/MarginContainer/VBoxContainer/DescLabel
@onready var detail_actions = $DetailPanel/MarginContainer/VBoxContainer/ActionsContainer
@onready var start_button = $MarginContainer/VBoxContainer/StartFestivalButton

var scenarios = [
	{
		"id": "power_outage_main",
		"title": "Main Stage Power Outage",
		"desc": "CRITICAL: The festival has reached its peak, and the main stage just went dark! Your team must respond immediately to restore power before the crowd panics.",
		"type": "member_assignment",
		"required_members": 2,
		"training_type": "electrical_failure_response",
		"active": false,
		"completed": false,
		"assigned": [],
		"color": Color(0.8, 0.1, 0.1) # Red
	},
	{
		"id": "power_outage_food",
		"title": "Food Vendor Power Failure",
		"desc": "During peak hours, 3 food vendors suddenly lose electricity. Long queues are forming and people are getting impatient.",
		"type": "member_assignment",
		"required_members": 3,
		"training_type": "electrical_failure_response",
		"active": false,
		"completed": false,
		"assigned": [],
		"color": Color(0.9, 0.5, 0.1) # Orange
	},
	{
		"id": "overcrowding",
		"title": "Overcrowding Near Main Stage",
		"desc": "The area near the main stage has become dangerously crowded. Movement has slowed down. Dispatch a team to redirect the crowd safely.",
		"type": "member_assignment",
		"required_members": 2,
		"training_type": "crowd_control",
		"active": false,
		"completed": false,
		"assigned": [],
		"color": Color(0.8, 0.1, 0.1)
	},
	{
		"id": "partial_evacuation",
		"title": "Partial Area Evacuation",
		"desc": "An unexpected issue forces the evacuation of a specific zone. Guide the crowd efficiently to prevent a stampede.",
		"type": "member_assignment",
		"required_members": 2,
		"training_type": "crowd_control",
		"active": false,
		"completed": false,
		"assigned": [],
		"color": Color(0.9, 0.3, 0.1)
	},
	{
		"id": "participant_collapse",
		"title": "Participant Collapse",
		"desc": "A participant suddenly collapsed due to exhaustion. Immediate medical attention is required.",
		"type": "member_assignment",
		"required_members": 1,
		"training_type": "medical_first_response",
		"active": false,
		"completed": false,
		"assigned": [],
		"color": Color(0.8, 0.1, 0.1)
	},
	{
		"id": "multiple_minor_injuries",
		"title": "Multiple Minor Injuries",
		"desc": "Multiple participants report minor injuries like slips and falls. Medical response system needs support.",
		"type": "member_assignment",
		"required_members": 2,
		"training_type": "medical_first_response",
		"active": false,
		"completed": false,
		"assigned": [],
		"color": Color(0.8, 0.5, 0.1)
	},
	{
		"id": "vip_complaint",
		"title": "VIP/Sponsor Complaint",
		"desc": "A major sponsor reports a serious issue regarding their experience. This is a severe reputational risk.",
		"type": "member_assignment",
		"required_members": 1,
		"training_type": "crisis_management",
		"active": false,
		"completed": false,
		"assigned": [],
		"color": Color(0.6, 0.1, 0.8) # Purple
	},
	{
		"id": "weather_disruption",
		"title": "Sudden Weather Disruption",
		"desc": "Heavy rain has unexpectedly started affecting parts of the festival. You need to reorganize areas and communicate with the crowd.",
		"type": "member_assignment",
		"required_members": 2,
		"training_type": "crisis_management",
		"active": false,
		"completed": false,
		"assigned": [],
		"color": Color(0.2, 0.4, 0.8) # Blue
	},
	{
		"id": "stage_delivery_accident",
		"title": "Logistics: Truck Accident",
		"desc": "The truck carrying equipment was involved in an accident. Without it, performances will halt.",
		"type": "decision",
		"options": [
			{"text": "Send Replacement Truck (Cost: 15,000 TL)", "cost": 15000, "impact": "No delay, performance maintained"},
			{"text": "Wait for resolution", "cost": 0, "impact": "Delay occurs, risk increases"}
		],
		"active": false,
		"completed": false,
		"color": Color(0.9, 0.5, 0.1)
	},
	{
		"id": "team_motivation_drop",
		"title": "Team Motivation Drop",
		"desc": "Your team is showing clear signs of extreme fatigue. Efficiency is declining.",
		"type": "decision",
		"options": [
			{"text": "Hold a quick team meeting", "cost": 0, "impact": "Improves communication, slight time loss"},
			{"text": "Provide incentives (Cost: 5,000 TL)", "cost": 5000, "impact": "Strong boost in motivation"},
			{"text": "Reorganize task distribution", "cost": 0, "impact": "Improves workload balance"},
			{"text": "Push the team to continue", "cost": 0, "impact": "Motivation drops further"}
		],
		"active": false,
		"completed": false,
		"color": Color(0.8, 0.5, 0.1)
	}
]

var active_scenario_ids = []
var selected_scenario_id = ""

var is_festival_running = false
var festival_duration = 240.0 # Festival runs for 4 minutes (240 seconds)
var festival_timer = 0.0

var queued_scenarios = []
var next_spawn_time = 0.0

var top_header = null
var pulse_tween: Tween = null
var clock_label: Label = null

func _ready() -> void:
	randomize()
	hide()
	detail_panel.hide()
	_apply_theme()
	_setup_custom_header()
	
	# Make Close button big and red
	$MarginContainer.add_theme_constant_override("margin_top", 80) # Prevent overlap with global top bar
	
	var close_btn = $MarginContainer/VBoxContainer/HBoxContainer/CloseButton
	if close_btn:
		close_btn.custom_minimum_size = Vector2(250, 80)
		close_btn.add_theme_font_size_override("font_size", 36)
		close_btn.text = "CLOSE"
		var st = StyleBoxFlat.new()
		st.bg_color = Color(0.8, 0.2, 0.2)
		st.corner_radius_top_left = 12
		st.corner_radius_top_right = 12
		st.corner_radius_bottom_right = 12
		st.corner_radius_bottom_left = 12
		close_btn.add_theme_stylebox_override("normal", st)

func _apply_theme() -> void:
	var bg_tex = TextureRect.new()
	var img = Image.new()
	if img.load("res://assets/images/sabanci_map_bg.png") == OK:
		bg_tex.texture = ImageTexture.create_from_image(img)
	bg_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg_tex.modulate = Color(0.4, 0.6, 0.8, 0.15) # Tactical blue tint, very subtle (15% opacity)
	bg_tex.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg_tex)
	move_child(bg_tex, 0)

	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.05, 0.07, 0.1, 1.0) # Solid dark background so dashboard doesn't bleed through
	bg_style.border_width_top = 4
	bg_style.border_color = Color(0.9, 0.3, 0.2)
	add_theme_stylebox_override("panel", bg_style)
	
	var modal_style = StyleBoxFlat.new()
	modal_style.bg_color = Color(0.1, 0.12, 0.16, 0.95)
	modal_style.corner_radius_top_left = 12
	modal_style.corner_radius_top_right = 12
	modal_style.corner_radius_bottom_right = 12
	modal_style.corner_radius_bottom_left = 12
	modal_style.border_width_left = 2
	modal_style.border_width_top = 2
	modal_style.border_width_right = 2
	modal_style.border_width_bottom = 2
	modal_style.border_color = Color(0.4, 0.4, 0.5)
	detail_panel.add_theme_stylebox_override("panel", modal_style)

func _setup_custom_header() -> void:
	var title = $MarginContainer/VBoxContainer/HBoxContainer/TitleLabel
	title.text = "FESTIVAL OPERATIONS CENTER"
	title.add_theme_color_override("font_color", Color(0.8, 0.8, 0.9))
	
	start_button.add_theme_color_override("font_color", Color.WHITE)
	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = Color(0.2, 0.6, 0.3)
	btn_style.corner_radius_top_left = 8
	btn_style.corner_radius_bottom_right = 8
	btn_style.corner_radius_top_right = 8
	btn_style.corner_radius_bottom_left = 8
	start_button.add_theme_stylebox_override("normal", btn_style)
	
	var hover = btn_style.duplicate()
	hover.bg_color = Color(0.3, 0.8, 0.4)
	start_button.add_theme_stylebox_override("hover", hover)

func _process(delta: float) -> void:
	if not is_festival_running:
		return
		
	festival_timer += delta
	
	festival_timer += delta
	
	# Spawn scenarios
	if festival_timer >= next_spawn_time and queued_scenarios.size() > 0:
		_spawn_scenario(queued_scenarios.pop_front())
		if queued_scenarios.size() > 0:
			next_spawn_time = festival_timer + randf_range(15.0, 30.0)
			
	# Update time on active cards
	for child in active_scenarios_container.get_children():
		if child.has_method("update_time"):
			child.update_time(GameState.game_seconds)
			
	# Check completion
	if queued_scenarios.size() == 0 and active_scenario_ids.size() > 0:
		var all_done = true
		for sc in scenarios:
			if sc["active"] and not sc["completed"]:
				all_done = false
				break
		if all_done:
			_finish_festival()

func _on_close_pressed() -> void:
	hide()
	var board = get_parent().get_node("ActivityBoard")
	if board:
		board.show()
		if board.has_method("refresh_board"):
			board.refresh_board()

func _on_start_festival_pressed() -> void:
	start_button.hide()
	is_festival_running = true
	festival_timer = 0.0
	
	# Prepare random scenarios
	scenarios.shuffle()
	queued_scenarios = scenarios.slice(0, 8) # Pick 8 events
	next_spawn_time = randf_range(5.0, 10.0)
	
	# Add a LIVE pulse
	var live_label = Label.new()
	live_label.text = "🔴 LIVE"
	live_label.add_theme_font_size_override("font_size", 42)
	live_label.add_theme_color_override("font_color", Color(1, 0.2, 0.2))
	$MarginContainer/VBoxContainer/HBoxContainer.add_child(live_label)
	
	pulse_tween = create_tween().set_loops()
	pulse_tween.tween_property(live_label, "modulate:a", 0.3, 0.8).set_trans(Tween.TRANS_SINE)
	pulse_tween.tween_property(live_label, "modulate:a", 1.0, 0.8).set_trans(Tween.TRANS_SINE)

func _spawn_scenario(sc: Dictionary) -> void:
	sc["active"] = true
	sc["start_time"] = GameState.game_seconds
	active_scenario_ids.append(sc["id"])
	
	# Create interactive card
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 100)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.18, 0.9)
	style.border_width_left = 6
	style.border_color = sc["color"]
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 8
	card.add_theme_stylebox_override("panel", style)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_top", 15)
	margin.add_theme_constant_override("margin_bottom", 15)
	card.add_child(margin)
	
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 20)
	margin.add_child(hbox)
	
	var icon = Label.new()
	icon.text = "⚠️" if sc["type"] == "member_assignment" else "❓"
	icon.add_theme_font_size_override("font_size", 48)
	hbox.add_child(icon)
	
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(vbox)
	
	var title = Label.new()
	title.text = sc["title"]
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", sc["color"].lightened(0.5))
	vbox.add_child(title)
	
	var time_lbl = Label.new()
	time_lbl.text = "Waiting: 0 sec"
	time_lbl.modulate = Color(0.6, 0.6, 0.6)
	time_lbl.add_theme_font_size_override("font_size", 24)
	vbox.add_child(time_lbl)
	
	var btn = Button.new()
	btn.text = "RESPOND"
	btn.custom_minimum_size = Vector2(200, 0)
	btn.add_theme_font_size_override("font_size", 28)
	btn.pressed.connect(func(): _on_scenario_selected(sc["id"]))
	
	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = sc["color"].darkened(0.5)
	btn_style.set_border_width_all(2)
	btn_style.border_color = sc["color"]
	btn.add_theme_stylebox_override("normal", btn_style)
	
	hbox.add_child(btn)
	
	# Add a script/method dynamically to update time
	card.set_meta("sc_id", sc["id"])
	card.set_meta("start", sc["start_time"])
	card.set_script(_get_card_script())
	card.call("setup", time_lbl)
	
	active_scenarios_container.add_child(card)
	active_scenarios_container.move_child(card, 0)
	
	# Slide in animation
	card.position.x = 800
	card.modulate.a = 0
	var tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(card, "position:x", 0, 0.6)
	tw.tween_property(card, "modulate:a", 1.0, 0.6)

func _get_card_script() -> Script:
	var gd = GDScript.new()
	gd.source_code = """
extends PanelContainer
var lbl: Label
func setup(l): lbl = l
func update_time(cur: float):
	var elapsed = int(cur - get_meta('start'))
	lbl.text = "Waiting: " + str(elapsed) + " sec"
	if elapsed > 10: lbl.modulate = Color(1.0, 0.4, 0.4)
"""
	gd.reload()
	return gd

func _on_scenario_selected(sc_id: String) -> void:
	selected_scenario_id = sc_id
	var sc = _get_scenario(sc_id)
	
	detail_title.text = "INCIDENT: " + sc["title"]
	detail_title.add_theme_color_override("font_color", sc["color"].lightened(0.5))
	detail_title.add_theme_font_size_override("font_size", 36)
	detail_desc.text = sc["desc"]
	detail_desc.add_theme_font_size_override("font_size", 28)
	
	for child in detail_actions.get_children():
		child.queue_free()
		
	if sc["type"] == "decision":
		var info = Label.new()
		info.text = "Select an executive action:"
		info.add_theme_font_size_override("font_size", 28)
		info.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
		detail_actions.add_child(info)
		
		for opt in sc["options"]:
			var btn = Button.new()
			var budget_warn = "" if GameState.money >= opt["cost"] else " (INSUFFICIENT FUNDS)"
			btn.text = opt["text"] + budget_warn + "\nImpact: " + opt["impact"]
			btn.custom_minimum_size = Vector2(0, 70)
			btn.add_theme_font_size_override("font_size", 24)
			btn.disabled = GameState.money < opt["cost"]
			
			var st = StyleBoxFlat.new()
			st.bg_color = Color(0.2, 0.2, 0.25)
			if GameState.money < opt["cost"]: st.bg_color = Color(0.1, 0.1, 0.1)
			st.border_width_left = 4
			st.border_color = sc["color"]
			btn.add_theme_stylebox_override("normal", st)
			
			btn.pressed.connect(func(): _make_decision(sc, opt))
			detail_actions.add_child(btn)
			
	elif sc["type"] == "member_assignment":
		var info = Label.new()
		info.text = "Assign Team Members (Required: %d) - Needed Skill: %s" % [sc["required_members"], sc["training_type"].capitalize().replace("_", " ")]
		info.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
		info.add_theme_font_size_override("font_size", 28)
		detail_actions.add_child(info)
		
		var grid = GridContainer.new()
		grid.columns = 2
		grid.add_theme_constant_override("h_separation", 15)
		grid.add_theme_constant_override("v_separation", 15)
		
		var trained_count = 0
		for member in GameState.selected_team:
			var has_skill = member.get(sc["training_type"], 0) > 0
			if not has_skill:
				continue # Sadece egitim alanlari goster
				
			trained_count += 1
			var is_assigned = sc["assigned"].has(member["id"])
			
			var m_btn = Button.new()
			var skill_text = " (Trained)"
			m_btn.text = member["name"] + skill_text
			if is_assigned: m_btn.text += " [ASSIGNED]"
			m_btn.disabled = is_assigned
			m_btn.custom_minimum_size = Vector2(250, 60)
			m_btn.add_theme_font_size_override("font_size", 24)
			
			var bst = StyleBoxFlat.new()
			bst.bg_color = Color(0.1, 0.3, 0.1)
			bst.border_width_bottom = 2
			m_btn.add_theme_stylebox_override("normal", bst)
			
			m_btn.pressed.connect(func(): _assign_member(sc, member["id"]))
			grid.add_child(m_btn)
			
		if trained_count == 0:
			var no_member_lbl = Label.new()
			no_member_lbl.text = "No team members have the required training!"
			no_member_lbl.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
			no_member_lbl.add_theme_font_size_override("font_size", 24)
			grid.add_child(no_member_lbl)
			
		detail_actions.add_child(grid)
		
		# Warnings for insufficient members
		if trained_count > 0:
			if trained_count < sc["required_members"]:
				var warn1 = Label.new()
				warn1.text = "⚠️ INSUFFICIENT STAFF: You only have " + str(trained_count) + " trained member(s). Required: " + str(sc["required_members"]) + ". Dispatching an incomplete team will reduce your score!"
				warn1.add_theme_color_override("font_color", Color(1.0, 0.5, 0.2))
				warn1.add_theme_font_size_override("font_size", 22)
				warn1.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				detail_actions.add_child(warn1)
			elif sc["assigned"].size() > 0 and sc["assigned"].size() < sc["required_members"]:
				var warn2 = Label.new()
				warn2.text = "⚠️ WARNING: You have assigned fewer members than required. Dispatching now will reduce your score."
				warn2.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))
				warn2.add_theme_font_size_override("font_size", 22)
				warn2.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				detail_actions.add_child(warn2)
		
		var resolve_btn = Button.new()
		resolve_btn.custom_minimum_size = Vector2(0, 60)
		resolve_btn.add_theme_font_size_override("font_size", 32)
		
		if trained_count == 0:
			resolve_btn.text = "FAIL INCIDENT (NO STAFF)"
			var rs = StyleBoxFlat.new()
			rs.bg_color = Color(0.6, 0.1, 0.1)
			resolve_btn.add_theme_stylebox_override("normal", rs)
			resolve_btn.pressed.connect(func(): _fail_assignment(sc))
		else:
			resolve_btn.text = "DISPATCH TEAM"
			resolve_btn.disabled = sc["assigned"].size() == 0 # Disabled until team member is assigned
			var rs = StyleBoxFlat.new()
			rs.bg_color = sc["color"].darkened(0.2)
			if sc["assigned"].size() == 0:
				rs.bg_color = Color(0.3, 0.3, 0.3) # Dim color while disabled
			resolve_btn.add_theme_stylebox_override("normal", rs)
			resolve_btn.pressed.connect(func(): _resolve_assignment(sc))
			
		detail_actions.add_child(resolve_btn)
		
	var close_btn = Button.new()
	close_btn.text = "Cancel"
	close_btn.custom_minimum_size = Vector2(0, 60)
	close_btn.add_theme_font_size_override("font_size", 28)
	close_btn.pressed.connect(func(): detail_panel.hide())
	detail_actions.add_child(close_btn)
	
	detail_panel.modulate.a = 0
	detail_panel.show()
	create_tween().tween_property(detail_panel, "modulate:a", 1.0, 0.2)

func _assign_member(sc: Dictionary, member_id: String) -> void:
	sc["assigned"].append(member_id)
	_on_scenario_selected(sc["id"])

func _fail_assignment(sc: Dictionary) -> void:
	sc["completed"] = true
	detail_panel.hide()
	GameState.event_quality_score -= 10.0 # Heavy penalty for failing to assign anyone
	_remove_card(sc["id"])

func _resolve_assignment(sc: Dictionary) -> void:
	sc["completed"] = true
	detail_panel.hide()
	
	var time_taken = max(1.0, GameState.game_seconds - sc.get("start_time", GameState.game_seconds))
	var time_score = clamp(1.0 / time_taken, 0.0, 1.0)
	
	var training_match = 0.0
	var assigned_count = sc["assigned"].size()
	if assigned_count > 0:
		var trained_members = 0
		for member_id in sc["assigned"]:
			for m in GameState.selected_team:
				if m["id"] == member_id:
					if m.get(sc["training_type"], 0) > 0:
						trained_members += 1
		training_match = float(trained_members) / float(assigned_count)
	
	var ratio = float(assigned_count) / float(sc["required_members"]) if sc["required_members"] > 0 else 1.0
	var score = (training_match * 0.5) + (time_score * 0.3) + (clamp(ratio, 0.0, 1.0) * 0.2)
	
	GameState.event_quality_score += score * 10.0
	_remove_card(sc["id"])

func _make_decision(sc: Dictionary, opt: Dictionary) -> void:
	if GameState.money >= opt["cost"]:
		GameState.money -= opt["cost"]
		sc["completed"] = true
		detail_panel.hide()
		
		var score = 0.0
		if sc["id"] == "stage_delivery_accident":
			var decision_quality = 1.0 if opt["cost"] > 0 else 0.5
			var delay_impact = 1.0 if opt["cost"] > 0 else 5.0
			score = (decision_quality * 0.6) + ((1.0 / delay_impact) * 0.4)
		elif sc["id"] == "team_motivation_drop":
			var decision_quality = 0.8
			if opt["cost"] > 0: decision_quality = 1.0
			var team_mot = GameState.team_motivation / 100.0
			var op_eff = 0.8
			score = (decision_quality * 0.5) + (team_mot * 0.3) + (op_eff * 0.2)
			
		GameState.event_quality_score += score * 10.0
		_remove_card(sc["id"])

func _remove_card(sc_id: String) -> void:
	for child in active_scenarios_container.get_children():
		if child.has_meta("sc_id") and child.get_meta("sc_id") == sc_id:
			# Shrink out animation
			var tw = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
			tw.tween_property(child, "scale", Vector2(0, 0), 0.3)
			tw.tween_callback(child.queue_free)

func _finish_festival() -> void:
	is_festival_running = false
	if pulse_tween: pulse_tween.kill()
	
	var overlay = ColorRect.new()
	overlay.color = Color(0,0,0, 0.8)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)
	
	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 50)
	center.add_child(vbox)
	
	var lbl = Label.new()
	lbl.text = "FESTIVAL CONCLUDED\nSuccessfully Managed All Incidents!"
	lbl.add_theme_font_size_override("font_size", 48)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(lbl)
	
	var btn = Button.new()
	btn.text = "RETURN TO DASHBOARD"
	btn.custom_minimum_size = Vector2(400, 80)
	btn.add_theme_font_size_override("font_size", 32)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	
	var st = StyleBoxFlat.new()
	st.bg_color = Color(0.2, 0.6, 0.3)
	st.corner_radius_top_left = 12
	st.corner_radius_top_right = 12
	st.corner_radius_bottom_right = 12
	st.corner_radius_bottom_left = 12
	btn.add_theme_stylebox_override("normal", st)
	
	btn.pressed.connect(func():
		GameState.complete_activity("festival_day")
		_on_close_pressed()
	)
	vbox.add_child(btn)

func _get_scenario(id: String) -> Dictionary:
	for sc in scenarios:
		if sc["id"] == id: return sc
	return {}
