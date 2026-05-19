import os

GD_FILE = "/Users/zeynepgokmen/Desktop/Bitirme-Projesi/scripts/team_assignment_panel.gd"

new_content = """extends Panel

@onready var member_list: GridContainer = $MarginContainer/VBoxContainer/MainContent/LeftScroll/MemberList
@onready var confirm_button: Button = $MarginContainer/VBoxContainer/MainContent/RightPanel/ConfirmButton
@onready var main_panel: Panel = self
@onready var stats_sidebar: PanelContainer = $MarginContainer/VBoxContainer/MainContent/RightPanel/StatsPanel
@onready var title_label: Label = $MarginContainer/VBoxContainer/Header/TitleLabel
@onready var subtitle_label: Label = $MarginContainer/VBoxContainer/Header/SubTitleLabel
@onready var left_scroll: ScrollContainer = $MarginContainer/VBoxContainer/MainContent/LeftScroll
@onready var right_panel: VBoxContainer = $MarginContainer/VBoxContainer/MainContent/RightPanel

var right_panel_bars: Dictionary = {}
var current_phase: int = 1 # 1: Team Selection, 2: Work Assignment

# Work assignment vars
var activity_list: VBoxContainer
var workload_stats_container: VBoxContainer
var capacity_labels: Dictionary = {}
var activity_dropdowns: Dictionary = {}

var extra_hires_count: int = 0
var outsourced_activities: Array = []
var member_boosts: Dictionary = {}
var current_assignments: Dictionary = {}

func _ready() -> void:
	if has_node("MarginContainer/VBoxContainer/MainContent/RightPanel/CostPanel"):
		get_node("MarginContainer/VBoxContainer/MainContent/RightPanel/CostPanel").hide()
	
	_init_right_panel_stats()
	
	confirm_button.pressed.connect(_on_confirm_pressed)
	_setup_ui_styles()
	create_member_cards()
	update_stats_display()


func _setup_ui_styles() -> void:
	var main_style = StyleBoxFlat.new()
	main_style.bg_color = Color(0.05, 0.07, 0.1, 0.95)
	main_style.border_width_left = 4
	main_style.border_color = Color(0.1, 0.4, 0.7)
	main_panel.add_theme_stylebox_override("panel", main_style)
	
	var sidebar_style = StyleBoxFlat.new()
	sidebar_style.bg_color = Color(0.1, 0.12, 0.15, 0.8)
	sidebar_style.corner_radius_top_left = 10
	sidebar_style.corner_radius_top_right = 10
	sidebar_style.corner_radius_bottom_right = 10
	sidebar_style.corner_radius_bottom_left = 10
	sidebar_style.border_width_left = 1
	sidebar_style.border_width_top = 1
	sidebar_style.border_width_right = 1
	sidebar_style.border_width_bottom = 1
	sidebar_style.border_color = Color(0.2, 0.3, 0.4)
	stats_sidebar.add_theme_stylebox_override("panel", sidebar_style)
	
	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = Color(0.2, 0.5, 0.8)
	btn_style.corner_radius_top_left = 5
	btn_style.corner_radius_top_right = 5
	btn_style.corner_radius_bottom_right = 5
	btn_style.corner_radius_bottom_left = 5
	confirm_button.add_theme_stylebox_override("normal", btn_style)
	
	var btn_hover = btn_style.duplicate()
	btn_hover.bg_color = Color(0.3, 0.6, 0.9)
	confirm_button.add_theme_stylebox_override("hover", btn_hover)


func create_member_cards() -> void:
	for child in member_list.get_children():
		child.queue_free()

	if GameState.all_team_members.is_empty():
		GameState.load_team_members()

	for member in GameState.all_team_members:
		var card = create_card_ui(member)
		member_list.add_child(card)

func create_card_ui(member: Dictionary) -> PanelContainer:
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(380, 280)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	card.set_meta("member_data", member)
	card.set_meta("selected", false)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	card.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	margin.add_child(vbox)
	
	var header = HBoxContainer.new()
	vbox.add_child(header)
	
	var name_label = Label.new()
	name_label.text = member["name"]
	name_label.add_theme_font_size_override("font_size", 22)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(name_label)
	
	var stats_grid = GridContainer.new()
	stats_grid.columns = 2
	stats_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stats_grid.add_theme_constant_override("h_separation", 15)
	stats_grid.add_theme_constant_override("v_separation", 10)
	vbox.add_child(stats_grid)
	
	add_stat_row(stats_grid, "Communication", member["communication"])
	add_stat_row(stats_grid, "Speed", member["speed"])
	add_stat_row(stats_grid, "Operations", member["operations"])
	add_stat_row(stats_grid, "Reliability", member["reliability"])
	add_stat_row(stats_grid, "Teamwork", member["teamwork"])
	add_stat_row(stats_grid, "Stress Tol.", member["stress_tolerance"])
	add_stat_row(stats_grid, "Creativity", member["creativity"])
	add_stat_row(stats_grid, "Experience", member["experience_level"])
	add_stat_row(stats_grid, "Workload Cap.", member["workload_capacity"])
	
	var btn = Button.new()
	btn.flat = true
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.set_anchors_preset(Control.PRESET_FULL_RECT)
	card.add_child(btn)
	
	btn.pressed.connect(_on_card_pressed.bind(card))
	
	update_card_style(card)
	
	return card

func add_stat_row(parent: Control, label_text: String, value: float) -> void:
	var stat_container = VBoxContainer.new()
	stat_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(stat_container)
	
	var label_hbox = HBoxContainer.new()
	stat_container.add_child(label_hbox)
	
	var lbl = Label.new()
	lbl.text = label_text
	lbl.add_theme_font_size_override("font_size", 18)
	lbl.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label_hbox.add_child(lbl)
	
	var percent_lbl = Label.new()
	percent_lbl.text = "%d%%" % (value * 20)
	percent_lbl.add_theme_font_size_override("font_size", 18)
	percent_lbl.add_theme_color_override("font_color", Color(1, 1, 1))
	label_hbox.add_child(percent_lbl)
	
	var bar = ProgressBar.new()
	bar.max_value = 5
	bar.value = value
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 10)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var style = StyleBoxFlat.new()
	if value >= 4:
		style.bg_color = Color(0.2, 0.8, 0.2)
	elif value >= 3:
		style.bg_color = Color(0.8, 0.8, 0.2)
	else:
		style.bg_color = Color(0.8, 0.2, 0.2)
	
	style.corner_radius_top_left = 2
	style.corner_radius_top_right = 2
	style.corner_radius_bottom_right = 2
	style.corner_radius_bottom_left = 2
	
	bar.add_theme_stylebox_override("fill", style)
	stat_container.add_child(bar)

func update_card_style(card: PanelContainer) -> void:
	var is_selected = card.get_meta("selected")
	var style = StyleBoxFlat.new()
	
	if is_selected:
		style.bg_color = Color(0.2, 0.4, 0.6, 0.4)
		style.border_width_left = 2
		style.border_width_top = 2
		style.border_width_right = 2
		style.border_width_bottom = 2
		style.border_color = Color(0.4, 0.8, 1.0)
		style.shadow_size = 5
		style.shadow_color = Color(0, 0, 0, 0.3)
	else:
		style.bg_color = Color(0.15, 0.15, 0.15, 0.6)
		style.border_width_left = 1
		style.border_width_top = 1
		style.border_width_right = 1
		style.border_width_bottom = 1
		style.border_color = Color(0.3, 0.3, 0.3)
	
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 8
	style.corner_radius_bottom_left = 8
	
	card.add_theme_stylebox_override("panel", style)

func _on_card_pressed(card: PanelContainer) -> void:
	var is_selected = card.get_meta("selected")
	var selected_count = get_selected_members().size()
	
	if not is_selected and selected_count >= 8:
		return # Cannot select more than 8
		
	card.set_meta("selected", !is_selected)
	update_card_style(card)
	update_stats_display()
	
	var cur_count = get_selected_members().size()
	if cur_count == 8:
		confirm_button.text = "NEXT: WORK ASSIGNATION"
	else:
		confirm_button.text = "SELECT 8 MEMBERS (%d/8)" % cur_count


func get_selected_members() -> Array:
	var selected: Array = []
	for child in member_list.get_children():
		if child is PanelContainer and child.get_meta("selected"):
			selected.append(child.get_meta("member_data"))
	return selected

func _init_right_panel_stats() -> void:
	var right_stats_container = $MarginContainer/VBoxContainer/MainContent/RightPanel/StatsPanel/MarginContainer/VBoxContainer
	for child in right_stats_container.get_children():
		child.queue_free()
	
	var stats_grid = GridContainer.new()
	stats_grid.columns = 1
	stats_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stats_grid.add_theme_constant_override("h_separation", 10)
	stats_grid.add_theme_constant_override("v_separation", 8)
	right_stats_container.add_child(stats_grid)
	
	var stat_keys = [
		{"key": "communication", "label": "Communication"},
		{"key": "speed", "label": "Speed"},
		{"key": "operations", "label": "Operations"},
		{"key": "reliability", "label": "Reliability"},
		{"key": "teamwork", "label": "Teamwork"},
		{"key": "stress_tolerance", "label": "Stress Tol."},
		{"key": "creativity", "label": "Creativity"},
		{"key": "experience_level", "label": "Experience"},
		{"key": "workload_capacity", "label": "Workload Cap."}
	]
	
	for stat in stat_keys:
		var bar = _add_right_panel_stat_row(stats_grid, stat["label"])
		right_panel_bars[stat["key"]] = bar

func _add_right_panel_stat_row(parent: Control, label_text: String) -> ProgressBar:
	var stat_container = VBoxContainer.new()
	stat_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(stat_container)
	
	var label_hbox = HBoxContainer.new()
	stat_container.add_child(label_hbox)
	
	var lbl = Label.new()
	lbl.text = label_text
	lbl.add_theme_font_size_override("font_size", 18)
	lbl.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label_hbox.add_child(lbl)
	
	var percent_lbl = Label.new()
	percent_lbl.text = "0%"
	percent_lbl.add_theme_font_size_override("font_size", 18)
	percent_lbl.add_theme_color_override("font_color", Color(1, 1, 1))
	label_hbox.add_child(percent_lbl)
	
	var bar = ProgressBar.new()
	bar.max_value = 5
	bar.value = 0
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 8)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.8, 0.2, 0.2)
	style.corner_radius_top_left = 2
	style.corner_radius_top_right = 2
	style.corner_radius_bottom_right = 2
	style.corner_radius_bottom_left = 2
	bar.add_theme_stylebox_override("fill", style)
	stat_container.add_child(bar)
	
	bar.set_meta("percent_lbl", percent_lbl)
	return bar

func update_stats_display() -> void:
	var selected := get_selected_members()

	var totals = {
		"communication": 0.0,
		"speed": 0.0,
		"operations": 0.0,
		"reliability": 0.0,
		"teamwork": 0.0,
		"stress_tolerance": 0.0,
		"creativity": 0.0,
		"experience_level": 0.0,
		"workload_capacity": 0.0
	}

	var count := selected.size()
	if count > 0:
		for member in selected:
			for key in totals.keys():
				totals[key] += member[key]
		for key in totals.keys():
			totals[key] /= count

	for key in totals.keys():
		var val = totals[key]
		var bar: ProgressBar = right_panel_bars[key]
		bar.value = val
		var percent_lbl: Label = bar.get_meta("percent_lbl")
		percent_lbl.text = "%d%%" % (val * 20)
		
		var style = bar.get_theme_stylebox("fill").duplicate() as StyleBoxFlat
		if val >= 4.0:
			style.bg_color = Color(0.2, 0.8, 0.2)
		elif val >= 3.0:
			style.bg_color = Color(0.8, 0.8, 0.2)
		else:
			style.bg_color = Color(0.8, 0.2, 0.2)
		bar.add_theme_stylebox_override("fill", style)

# ==============================================================
# PHASE 2: WORK ASSIGNATION
# ==============================================================

func _on_confirm_pressed() -> void:
	if current_phase == 1:
		var selected := get_selected_members()
		if selected.size() != 8:
			print("You must select exactly 8 members!")
			return
		
		GameState.selected_team = selected
		if not GameState.completed_activities.has("team_assignment"):
			GameState.completed_activities.append("team_assignment")
			
		transition_to_work_assignation()
	else:
		finalize_work_assignation()


func transition_to_work_assignation() -> void:
	current_phase = 2
	title_label.text = "WORK ASSIGNATION"
	subtitle_label.text = "Assign your team members to the remaining activities."
	
	# Clear left scroll contents
	for child in left_scroll.get_children():
		child.queue_free()
		
	activity_list = VBoxContainer.new()
	activity_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	activity_list.add_theme_constant_override("separation", 10)
	left_scroll.add_child(activity_list)
	
	# Populate activities (excluding team_assignment, final mapping, festival day)
	var valid_activities = []
	for act in GameState.activities:
		if act["id"] not in ["team_assignment", "work_assignment", "initial_festival_layout_mapping", "final_festival_layout_mapping", "festival_day"]:
			valid_activities.append(act)
	
	for act in valid_activities:
		_create_activity_row(act)
		
	# Setup right panel for phase 2
	_setup_work_assignment_right_panel()


func _create_activity_row(act: Dictionary) -> void:
	var row = PanelContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.15, 0.6)
	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 5
	style.corner_radius_bottom_right = 5
	style.corner_radius_bottom_left = 5
	row.add_theme_stylebox_override("panel", style)
	
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 20)
	row.add_child(hbox)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 15)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(margin)
	
	var name_lbl = Label.new()
	name_lbl.text = act["name"]
	name_lbl.add_theme_font_size_override("font_size", 18)
	margin.add_child(name_lbl)
	
	var dropdown = OptionButton.new()
	dropdown.custom_minimum_size = Vector2(250, 0)
	dropdown.add_theme_font_size_override("font_size", 16)
	dropdown.add_item("Select Member...", 0)
	
	var i = 1
	for member in GameState.selected_team:
		dropdown.add_item(member["name"], i)
		dropdown.set_item_metadata(i, member["id"])
		i += 1
		
	# For extra hires (9th member etc)
	for member in GameState.all_team_members:
		if GameState.hired_extra_members.has(member["id"]):
			dropdown.add_item(member["name"] + " (Hired)", i)
			dropdown.set_item_metadata(i, member["id"])
			i += 1
			
	dropdown.add_item("Outsourced", i)
	dropdown.set_item_metadata(i, "outsourced")
	
	dropdown.item_selected.connect(_on_activity_assigned.bind(act["id"], dropdown))
	
	var drop_margin = MarginContainer.new()
	drop_margin.add_theme_constant_override("margin_right", 15)
	drop_margin.add_theme_constant_override("margin_top", 5)
	drop_margin.add_theme_constant_override("margin_bottom", 5)
	drop_margin.add_child(dropdown)
	
	hbox.add_child(drop_margin)
	
	activity_dropdowns[act["id"]] = dropdown
	activity_list.add_child(row)

func _setup_work_assignment_right_panel() -> void:
	# Clear existing right panel contents except the confirm button
	for child in right_panel.get_children():
		if child != confirm_button:
			child.queue_free()
			
	var stats_panel = PanelContainer.new()
	stats_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.12, 0.15, 0.8)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_right = 10
	style.corner_radius_bottom_left = 10
	style.border_width_all = 1
	style.border_color = Color(0.2, 0.3, 0.4)
	stats_panel.add_theme_stylebox_override("panel", style)
	
	right_panel.add_child(stats_panel)
	right_panel.move_child(stats_panel, 0)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 15)
	margin.add_theme_constant_override("margin_right", 15)
	margin.add_theme_constant_override("margin_top", 15)
	margin.add_theme_constant_override("margin_bottom", 15)
	stats_panel.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	margin.add_child(vbox)
	
	var title = Label.new()
	title.text = "WORKLOAD CAPACITY"
	title.add_theme_font_size_override("font_size", 20)
	vbox.add_child(title)
	
	var warning_lbl = Label.new()
	warning_lbl.text = "Exceeding capacity will highlight red!"
	warning_lbl.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
	warning_lbl.add_theme_font_size_override("font_size", 14)
	vbox.add_child(warning_lbl)
	
	workload_stats_container = VBoxContainer.new()
	workload_stats_container.add_theme_constant_override("separation", 8)
	vbox.add_child(workload_stats_container)
	
	# Extra options box
	var extra_box = VBoxContainer.new()
	extra_box.add_theme_constant_override("separation", 10)
	vbox.add_child(extra_box)
	
	var hire_btn = Button.new()
	hire_btn.text = "Hire Extra Member ($15,000)"
	hire_btn.pressed.connect(_on_hire_extra_pressed)
	extra_box.add_child(hire_btn)
	
	var outsource_lbl = Label.new()
	outsource_lbl.text = "Outsource (Select from dropdown) - $10,000"
	outsource_lbl.add_theme_font_size_override("font_size", 14)
	extra_box.add_child(outsource_lbl)
	
	var boost_lbl = Label.new()
	boost_lbl.text = "Scope Warning: Extra Hires reduce Overall Score!"
	boost_lbl.add_theme_color_override("font_color", Color(1, 0.4, 0.4))
	boost_lbl.add_theme_font_size_override("font_size", 14)
	extra_box.add_child(boost_lbl)
	
	confirm_button.text = "CONFIRM ASSIGNMENTS"
	
	_update_capacity_display()

func _update_capacity_display() -> void:
	for child in workload_stats_container.get_children():
		child.queue_free()
		
	capacity_labels.clear()
	
	var all_members = GameState.selected_team.duplicate()
	for m_id in GameState.hired_extra_members:
		for member in GameState.all_team_members:
			if member["id"] == m_id:
				all_members.append(member)
				break
				
	for member in all_members:
		var hbox = HBoxContainer.new()
		var name_lbl = Label.new()
		name_lbl.text = member["name"]
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(name_lbl)
		
		var cap_lbl = Label.new()
		var assigned = _count_assigned(member["id"])
		var total_cap = member.get("workload_capacity", 1) + member_boosts.get(member["id"], 0)
		cap_lbl.text = "%d / %d" % [assigned, total_cap]
		
		if assigned > total_cap:
			cap_lbl.add_theme_color_override("font_color", Color(1, 0.3, 0.3)) # Red
		elif assigned == total_cap:
			cap_lbl.add_theme_color_override("font_color", Color(0.3, 1, 0.3)) # Green
		else:
			cap_lbl.add_theme_color_override("font_color", Color(1, 1, 1))
			
		hbox.add_child(cap_lbl)
		
		# Boost button
		var boost_btn = Button.new()
		boost_btn.text = "+ ($8k)"
		boost_btn.add_theme_font_size_override("font_size", 12)
		boost_btn.pressed.connect(_on_boost_pressed.bind(member["id"]))
		hbox.add_child(boost_btn)
		
		workload_stats_container.add_child(hbox)
		capacity_labels[member["id"]] = cap_lbl

func _count_assigned(member_id: String) -> int:
	var count = 0
	for act_id in current_assignments:
		if current_assignments[act_id] == member_id:
			count += 1
	return count

func _on_activity_assigned(index: int, act_id: String, dropdown: OptionButton) -> void:
	var selected_id = dropdown.get_item_metadata(index)
	if selected_id == null or selected_id == "":
		current_assignments.erase(act_id)
	else:
		current_assignments[act_id] = selected_id
		
	if selected_id == "outsourced":
		if not outsourced_activities.has(act_id):
			outsourced_activities.append(act_id)
	else:
		if outsourced_activities.has(act_id):
			outsourced_activities.erase(act_id)
			
	_update_capacity_display()

func _on_hire_extra_pressed() -> void:
	# Show a popup to select an extra member
	# For simplicity, we can just randomly pick a non-selected member
	var available = []
	var selected_ids = []
	for m in GameState.selected_team:
		selected_ids.append(m["id"])
	selected_ids.append_array(GameState.hired_extra_members)
	
	for m in GameState.all_team_members:
		if not selected_ids.has(m["id"]):
			available.append(m)
			
	if available.size() > 0:
		if GameState.money >= GameState.HIRE_EXTRA_COST:
			var hired = available[0]
			GameState.hired_extra_members.append(hired["id"])
			print("Hired " + hired["name"])
			_refresh_dropdowns()
			_update_capacity_display()
		else:
			print("Not enough budget!")

func _refresh_dropdowns() -> void:
	for act_id in activity_dropdowns:
		var dropdown = activity_dropdowns[act_id]
		var selected_idx = dropdown.selected
		var selected_meta = dropdown.get_item_metadata(selected_idx)
		
		dropdown.clear()
		dropdown.add_item("Select Member...", 0)
		var i = 1
		for member in GameState.selected_team:
			dropdown.add_item(member["name"], i)
			dropdown.set_item_metadata(i, member["id"])
			i += 1
		
		for m_id in GameState.hired_extra_members:
			var m_name = ""
			for am in GameState.all_team_members:
				if am["id"] == m_id: m_name = am["name"]
			dropdown.add_item(m_name + " (Hired)", i)
			dropdown.set_item_metadata(i, m_id)
			i += 1
			
		dropdown.add_item("Outsourced", i)
		dropdown.set_item_metadata(i, "outsourced")
		
		# Restore selection
		if selected_meta != null:
			for idx in range(dropdown.item_count):
				if dropdown.get_item_metadata(idx) == selected_meta:
					dropdown.select(idx)
					break

func _on_boost_pressed(member_id: String) -> void:
	if GameState.money >= GameState.CAPACITY_BOOST_COST:
		var cur = member_boosts.get(member_id, 0)
		member_boosts[member_id] = cur + 1
		_update_capacity_display()
	else:
		print("Not enough budget!")

func finalize_work_assignation() -> void:
	# Validation: ensure all activities assigned
	var valid_activities = 0
	for act in GameState.activities:
		if act["id"] not in ["team_assignment", "work_assignment", "initial_festival_layout_mapping", "final_festival_layout_mapping", "festival_day"]:
			valid_activities += 1
			
	if current_assignments.size() < valid_activities:
		print("You must assign all activities!")
		return
		
	# Validation: check capacity
	for member_id in capacity_labels.keys():
		var assigned = _count_assigned(member_id)
		var m_dict = null
		for m in GameState.all_team_members:
			if m["id"] == member_id: m_dict = m
			
		var total_cap = m_dict.get("workload_capacity", 1) + member_boosts.get(member_id, 0)
		if assigned > total_cap:
			print("Capacity exceeded for " + m_dict["name"] + "! Adjust assignments or boost capacity.")
			return
			
	# Calculate total cost
	var extra_cost = 0
	extra_cost += GameState.hired_extra_members.size() * GameState.HIRE_EXTRA_COST
	extra_cost += outsourced_activities.size() * GameState.OUTSOURCE_COST
	for boost in member_boosts.values():
		extra_cost += boost * GameState.CAPACITY_BOOST_COST
		
	GameState.finalize_work_assignment(current_assignments, GameState.hired_extra_members, outsourced_activities, member_boosts, extra_cost)
	
	hide()
	var parent_node = get_parent()
	if parent_node.has_node("ActivityBoard"):
		var activity_board = parent_node.get_node("ActivityBoard")
		activity_board.show()
		activity_board.refresh_board()

"""

with open(GD_FILE, "w", encoding="utf-8") as f:
    f.write(new_content)
    
print("Successfully replaced team_assignment_panel.gd")
