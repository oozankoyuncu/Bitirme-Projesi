extends Control



@onready var activity_board = $ActivityBoard
@onready var team_assignment_panel: Panel = $TeamAssignmentPanel
@onready var initial_facility_layout_panel: Panel = $InitialFacilityLayoutPanel
@onready var emergency_training_panel: Panel = $EmergencyTrainingPanel
@onready var sponsor_management_panel: Panel = $SponsorManagementPanel
@onready var entertainment_lineup_panel: Panel = $EntertainmentLineupPanel
@onready var promotion_strategy_panel: Panel = $PromotionStrategyPanel
@onready var ticket_pricing_panel: Panel = $TicketPricingPanel
@onready var volunteer_club_panel: Panel = $VolunteerClubPanel
@onready var stage_setup_choices_panel: Panel = $StageSetupChoicesPanel
@onready var email_panel: Panel = $EmailPanel
@onready var charter_panel: Panel = $CharterPanel

@onready var week_label: Label = $TopBar/Margin/HBox/Stats/WeekBox/Label
@onready var budget_label: Label = $TopBar/Margin/HBox/Stats/BudgetBox/Label
@onready var time_label_hud: Label = $TopBar/Margin/HBox/Stats/TimeBox/Label

func _ready() -> void:
	GameState.load_team_members()
	GameState.time_changed.connect(_on_time_changed)
	
	_apply_global_ui_improvements()
	
	# Hide all sub-panels
	team_assignment_panel.hide()
	initial_facility_layout_panel.hide()
	emergency_training_panel.hide()
	sponsor_management_panel.hide()
	entertainment_lineup_panel.hide()
	promotion_strategy_panel.hide()
	ticket_pricing_panel.hide()
	volunteer_club_panel.hide()
	stage_setup_choices_panel.hide()
	
	# TopBar enhancements
	week_label.add_theme_font_size_override("font_size", 24)
	budget_label.add_theme_font_size_override("font_size", 24)
	time_label_hud.add_theme_font_size_override("font_size", 24)
	
	week_label.add_theme_constant_override("outline_size", 4)
	budget_label.add_theme_constant_override("outline_size", 4)
	time_label_hud.add_theme_constant_override("outline_size", 4)

	var stats = $TopBar/Margin/HBox/Stats
	if stats is BoxContainer:
		stats.add_theme_constant_override("separation", 80) # Increased separation
	
	# Create Clock
	var clock = Control.new()
	clock.custom_minimum_size = Vector2(40, 40)
	
	var clock_script = GDScript.new()
	clock_script.source_code = """
extends Control
func _process(delta):
	queue_redraw()
func _draw():
	var center = size / 2.0
	var radius = min(size.x, size.y) / 2.0 - 2.0
	var total_time = 240.0
	var current_time = fmod(GameState.game_seconds, total_time)
	var angle_to = (current_time / total_time) * TAU - PI / 2.0
	
	draw_circle(center, radius, Color(0.1, 0.1, 0.1, 0.8))
	
	if current_time > 0:
		var pts = PackedVector2Array()
		pts.append(center)
		var num_pts = 32
		var start_angle = -PI / 2.0
		for i in range(num_pts + 1):
			var a = lerp(start_angle, angle_to, float(i) / num_pts)
			pts.append(center + Vector2(cos(a), sin(a)) * radius)
		pts.append(center)
		if pts.size() >= 3:
			draw_polygon(pts, PackedColorArray([Color(0.229, 0.0, 0.911, 1.0)]))
	
	draw_arc(center, radius, 0, TAU, 32, Color(1, 1, 1, 0.5), 2.0, true)
"""
	clock_script.reload()
	clock.set_script(clock_script)
	clock.set_process(true)
	
	stats.add_child(clock)
	# Move the clock before TimeBox (which is usually the first or last depending on design)
	# We can just put it at index 0
	stats.move_child(clock, 0)
	
	# Initial Onboarding Sequence
	if GameState.skip_onboarding:
		activity_board.show()
		charter_panel.hide()
		email_panel.hide()
		if GameState.has_method("start_game_timer"):
			GameState.start_game_timer()
	else:
		charter_panel.hide()
		activity_board.hide()
		email_panel.show()
	
	_update_hud()
	_setup_persistent_hud()

func _on_time_changed() -> void:
	_update_hud()

func _update_hud() -> void:
	week_label.text = "Week: " + str(GameState.week)
	budget_label.text = "Budget: " + str(GameState.money) + " TL"
	
	var total := int(GameState.game_seconds)
	var hours := total / 3600
	var minutes := (total % 3600) / 60
	var seconds := total % 60
	time_label_hud.text = "%02d:%02d:%02d" % [hours, minutes, seconds]

func _setup_persistent_hud() -> void:
	# Ensure HUD is always on top
	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 100
	add_child(canvas_layer)
	
	var top_bar = $TopBar
	top_bar.reparent(canvas_layer)
	
	# Center the stats in the TopBar
	var hbox = top_bar.get_node("Margin/HBox")
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	
	# Increase font sizes for HUD labels
	var labels = [week_label, budget_label, time_label_hud]
	for lbl in labels:
		lbl.add_theme_font_size_override("font_size", 32)
		lbl.add_theme_color_override("font_color", Color(1, 1, 1)) # White for clarity
		
		# Also find the icons next to them
		var parent = lbl.get_parent()
		if parent is HBoxContainer:
			for child in parent.get_children():
				if child is Label and child != lbl:
					child.add_theme_font_size_override("font_size", 36)

func _apply_global_ui_improvements() -> void:
	# List of all potential sub-panels
	var panels = [
		team_assignment_panel, initial_facility_layout_panel, emergency_training_panel,
		sponsor_management_panel, entertainment_lineup_panel, promotion_strategy_panel,
		ticket_pricing_panel, volunteer_club_panel, stage_setup_choices_panel,
		$FoodVendorSelectionPanel, $SoundSystemChoicesPanel, $TransportCoordinationPanel,
		$DecorationThemePanel, $FestivalCleaningSecurityPanel, $FinalFacilityLayoutPanel
	]
	
	for panel in panels:
		if not panel: continue
		
		# Make panels larger and centered
		panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		
		# Add a nice background style
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.05, 0.07, 0.1, 0.98)
		style.border_width_top = 80 # Leave space for the TopBar HUD
		style.border_color = Color(0, 0, 0, 0)
		panel.add_theme_stylebox_override("panel", style)
		
		# Recursively increase font sizes inside the panel
		_enlarge_fonts_recursive(panel)

func _enlarge_fonts_recursive(node: Node) -> void:
	if node is Label:
		var current_size = node.get_theme_font_size("font_size")
		if current_size < 24:
			node.add_theme_font_size_override("font_size", 24)
		elif current_size < 32:
			node.add_theme_font_size_override("font_size", 32)
			
	if node is Button:
		node.custom_minimum_size.y = max(node.custom_minimum_size.y, 60)
		node.add_theme_font_size_override("font_size", 24)
		
	for child in node.get_children():
		_enlarge_fonts_recursive(child)
