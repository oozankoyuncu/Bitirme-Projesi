extends Control

@onready var margin_container: MarginContainer = $MarginContainer
@onready var tab_container: TabContainer = $MarginContainer/TabContainer
@onready var accept_button: Button = $MarginContainer/TabContainer/Success/Margin/VBox/Footer/AcceptCharterButton
@onready var activity_board: Control = get_parent().get_node("ActivityBoard")
@onready var time_label: CanvasLayer = get_parent().get_node("TimeLabel")

# KPI Progress Bars
@onready var kpi_bars = {
	"Time": $MarginContainer/TabContainer/Success/Margin/VBox/TabContent/KPI_List/TimeKPI/HBox/Bar,
	"Budget": $MarginContainer/TabContainer/Success/Margin/VBox/TabContent/KPI_List/BudgetKPI/HBox/Bar,
	"Scope": $MarginContainer/TabContainer/Success/Margin/VBox/TabContent/KPI_List/ScopeKPI/HBox/Bar,
	"Motivation": $MarginContainer/TabContainer/Success/Margin/VBox/TabContent/KPI_List/MotivationKPI/HBox/Bar,
	"Satisfaction": $MarginContainer/TabContainer/Success/Margin/VBox/TabContent/KPI_List/SatisfactionKPI/HBox/Bar,
	"Quality": $MarginContainer/TabContainer/Success/Margin/VBox/TabContent/KPI_List/QualityKPI/HBox/Bar
}

var value_labels = {}

func _ready() -> void:
	accept_button.pressed.connect(_on_accept_pressed)
	tab_container.tab_changed.connect(_on_tab_changed)
	_setup_styles()
	_apply_ui_scaling()
	_add_ofs_explanation()
	_create_ofs_metric()
	_initialize_kpi_styles()
	_setup_gantt_chart_tab()
	
	# Initial state for animation
	self.modulate.a = 0
	self.scale = Vector2(0.95, 0.95)

func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED:
		if is_visible_in_tree():
			_play_entry_animation()

func _setup_styles() -> void:
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.05, 0.07, 0.1, 0.4)
	add_theme_stylebox_override("panel", bg_style)

	var tab_panel_style = StyleBoxFlat.new()
	tab_panel_style.bg_color = Color(0.12, 0.15, 0.18, 0.95)
	tab_panel_style.set_corner_radius_all(12)
	tab_panel_style.shadow_color = Color(0, 0, 0, 0.4)
	tab_panel_style.shadow_size = 30
	tab_container.add_theme_stylebox_override("panel", tab_panel_style)
	
	# Tab bar styling
	var tab_bg = StyleBoxFlat.new()
	tab_bg.bg_color = Color(0.18, 0.22, 0.25, 1.0)
	tab_bg.set_corner_radius_all(8)
	tab_bg.content_margin_left = 20
	tab_bg.content_margin_right = 20
	tab_container.add_theme_stylebox_override("tab_unselected", tab_bg)
	
	var tab_selected = StyleBoxFlat.new()
	tab_selected.bg_color = Color(0.15, 0.55, 0.9)
	tab_selected.set_corner_radius_all(8)
	tab_selected.content_margin_left = 25
	tab_selected.content_margin_right = 25
	tab_container.add_theme_stylebox_override("tab_selected", tab_selected)
	
	# Constraint Header Style
	var constraint_style = StyleBoxFlat.new()
	constraint_style.bg_color = Color(1.0, 0.7, 0.0, 0.15) # Transparent Gold
	constraint_style.border_width_left = 5
	constraint_style.border_color = Color(1.0, 0.7, 0.0, 1.0) # Solid Gold
	constraint_style.content_margin_left = 15
	constraint_style.content_margin_top = 8
	constraint_style.content_margin_bottom = 8
	get_node("MarginContainer/TabContainer/Overview/Margin/VBox/ConstraintHeader").add_theme_stylebox_override("panel", constraint_style)

func _apply_ui_scaling() -> void:
	# Ensure the main container fits within viewport
	if margin_container:
		margin_container.add_theme_constant_override("margin_top", 90)
		margin_container.add_theme_constant_override("margin_bottom", 10)
		margin_container.add_theme_constant_override("margin_left", 40)
		margin_container.add_theme_constant_override("margin_right", 40)
	
	# Wrap both tabs in ScrollContainers
	_wrap_success_in_scroll()
	_wrap_overview_in_scroll()
	
	# Header Font Sizes (reasonable for 1920x1080)
	var header_paths = [
		"MarginContainer/TabContainer/Success/Margin/ScrollContainer/VBox/Header",
		"MarginContainer/TabContainer/Overview/Margin/ScrollContainer/VBox/Header/Title"
	]
	for path in header_paths:
		var h = get_node_or_null(path)
		if h and h.has_method("add_theme_font_size_override"):
			h.add_theme_font_size_override("font_size", 32)
	
	# Subtitles
	var sub_paths = [
		"MarginContainer/TabContainer/Success/Margin/ScrollContainer/VBox/OFSFormula",
		"MarginContainer/TabContainer/Success/Margin/ScrollContainer/VBox/Sub",
		"MarginContainer/TabContainer/Overview/Margin/ScrollContainer/VBox/ConstraintHeader/ConstraintTitle"
	]
	for path in sub_paths:
		var s = get_node_or_null(path)
		if s and s.has_method("add_theme_font_size_override"):
			s.add_theme_font_size_override("font_size", 22)
		
	# Tab Bar Scaling
	if tab_container:
		tab_container.add_theme_font_size_override("font_size", 20)
	
	# KPI List Container
	var kpi_list = get_node_or_null("MarginContainer/TabContainer/Success/Margin/ScrollContainer/VBox/TabContent/KPI_List")
	if kpi_list:
		kpi_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		kpi_list.add_theme_constant_override("separation", 12)
	
	# Remove the mascot image to save vertical space
	var mascot = get_node_or_null("MarginContainer/TabContainer/Success/Margin/ScrollContainer/VBox/TabContent/SuccessMascot")
	if mascot:
		mascot.queue_free()
	
	# Reduce KPI description font sizes
	var kpi_descs = [
		"TimeKPI/Desc", "BudgetKPI/Desc", "ScopeKPI/Desc",
		"MotivationKPI/Desc", "SatisfactionKPI/Desc", "QualityKPI/Desc"
	]
	for desc_path in kpi_descs:
		var desc = get_node_or_null("MarginContainer/TabContainer/Success/Margin/ScrollContainer/VBox/TabContent/KPI_List/" + desc_path)
		if desc:
			desc.add_theme_font_size_override("font_size", 16)
	
	# Reduce Overview section font sizes
	_scale_overview_fonts()

func _wrap_success_in_scroll() -> void:
	var success_margin = get_node_or_null("MarginContainer/TabContainer/Success/Margin")
	if not success_margin: return
	
	var vbox = success_margin.get_node_or_null("VBox")
	if not vbox: return
	
	# Create ScrollContainer
	var scroll = ScrollContainer.new()
	scroll.name = "ScrollContainer"
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	
	# Reparent VBox into ScrollContainer
	success_margin.remove_child(vbox)
	scroll.add_child(vbox)
	success_margin.add_child(scroll)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL 

func _wrap_overview_in_scroll() -> void:
	var overview_margin = get_node_or_null("MarginContainer/TabContainer/Overview/Margin")
	if not overview_margin: return
	
	var vbox = overview_margin.get_node_or_null("VBox")
	if not vbox: return
	
	var scroll = ScrollContainer.new()
	scroll.name = "ScrollContainer"
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	
	overview_margin.remove_child(vbox)
	scroll.add_child(vbox)
	overview_margin.add_child(scroll)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

func _scale_overview_fonts() -> void:
	# Reduce Overview section title font sizes (from 32 to 24)
	var section_titles = [
		"MarginContainer/TabContainer/Overview/Margin/ScrollContainer/VBox/ObjectiveSection/Title",
		"MarginContainer/TabContainer/Overview/Margin/ScrollContainer/VBox/ScopeSection/Title",
	]
	for path in section_titles:
		var node = get_node_or_null(path)
		if node:
			node.add_theme_font_size_override("font_size", 24)
	
	# Reduce objective text (from 28 to 20)
	var obj_text = get_node_or_null("MarginContainer/TabContainer/Overview/Margin/ScrollContainer/VBox/ObjectiveSection/Text")
	if obj_text:
		obj_text.add_theme_font_size_override("font_size", 20)
	
	# Reduce scope list items (from 28 to 20)
	var scope_list = get_node_or_null("MarginContainer/TabContainer/Overview/Margin/ScrollContainer/VBox/ScopeSection/List")
	if scope_list:
		for child in scope_list.get_children():
			if child is Label:
				child.add_theme_font_size_override("font_size", 20)
	
	# Reduce constraint details (from 26/28 to 20/22)
	var grid = get_node_or_null("MarginContainer/TabContainer/Overview/Margin/ScrollContainer/VBox/Grid")
	if grid:
		for box in grid.get_children():
			if box is VBoxContainer:
				for child in box.get_children():
					if child is Label:
						var current = child.get_theme_font_size("font_size")
						if current >= 28:
							child.add_theme_font_size_override("font_size", 22)
						elif current >= 26:
							child.add_theme_font_size_override("font_size", 18)

func _add_ofs_explanation() -> void:
	var ofs_formula_label = get_node_or_null("MarginContainer/TabContainer/Success/Margin/ScrollContainer/VBox/OFSFormula")
	if not ofs_formula_label: return
	
	var explanation = Label.new()
	explanation.text = "The overall scoring system evaluates performance through a multi-dimensional structure integrating Participant Satisfaction, Event Quality, Overall Festival Success, Scope Adherence, and Budget Control."
	explanation.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	explanation.add_theme_font_size_override("font_size", 18)
	explanation.modulate = Color(0.8, 0.9, 1.0, 1.0)
	
	var parent = ofs_formula_label.get_parent()
	var idx = ofs_formula_label.get_index()
	parent.add_child(explanation)
	parent.move_child(explanation, idx + 1)
	
	# Budget Warning Note
	var budget_warning = Label.new()
	budget_warning.text = "⚠️ FAILURE: Budget drops to -300,000 TL → project terminated."
	budget_warning.add_theme_font_size_override("font_size", 18)
	budget_warning.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
	budget_warning.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	
	parent.add_child(budget_warning)
	parent.move_child(budget_warning, idx + 2)

	# Evaluation Note
	var eval_note = Label.new()
	eval_note.text = "ℹ️ Note: There is no single main overall score; you will be evaluated separately on each of the criteria shown on this screen."
	eval_note.add_theme_font_size_override("font_size", 18)
	eval_note.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))
	eval_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	
	parent.add_child(eval_note)
	parent.move_child(eval_note, idx + 3)

func _create_ofs_metric() -> void:
	var kpi_list = get_node_or_null("MarginContainer/TabContainer/Success/Margin/ScrollContainer/VBox/TabContent/KPI_List")
	if not kpi_list: return
	
	# Create a separator
	var sep = HSeparator.new()
	sep.add_theme_constant_override("separation", 10)
	kpi_list.add_child(sep)
	
	# Create OFS KPI entry
	var ofs_vbox = VBoxContainer.new()
	ofs_vbox.name = "OFSKPI"
	kpi_list.add_child(ofs_vbox)
	
	var hbox = HBoxContainer.new()
	ofs_vbox.add_child(hbox)
	
	var label = Label.new()
	label.text = "OVERALL FESTIVAL SCORE (OFS)"
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", Color(0.15, 0.55, 0.9))
	hbox.add_child(label)
	
	var spacer = Control.new()
	spacer.custom_minimum_size.x = 15
	hbox.add_child(spacer)
	
	var bar = ProgressBar.new()
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.custom_minimum_size = Vector2(0, 22)
	bar.show_percentage = false
	hbox.add_child(bar)
	
	kpi_bars["OFS"] = bar

func _initialize_kpi_styles() -> void:
	for key in kpi_bars:
		var bar = kpi_bars[key]
		bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bar.custom_minimum_size.y = 18
		bar.value = 100
		bar.set_meta("target_val", bar.value)
		
		var hbox = bar.get_parent()
		if hbox is HBoxContainer:
			hbox.add_theme_constant_override("separation", 15)
			
			var name_label = hbox.get_child(0)
			if name_label is Label:
				name_label.add_theme_font_size_override("font_size", 20)
				name_label.custom_minimum_size.x = 300
			
			for child in hbox.get_children():
				if child is Control and not child is Label and not child is ProgressBar:
					child.custom_minimum_size.x = 15
		
		var val_label = Label.new()
		val_label.name = "ValueLabel"
		val_label.text = str(int(bar.value)) + " / 100"
		val_label.custom_minimum_size = Vector2(90, 0)
		val_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		val_label.add_theme_font_size_override("font_size", 20)
		hbox.add_child(val_label)
		value_labels[key] = val_label
		
		_update_bar_style(key, bar.value)

func _update_bar_style(key: String, val: float) -> void:
	var bar = kpi_bars[key]
	var fill_style = StyleBoxFlat.new()
	fill_style.set_corner_radius_all(12)
	
	# Enhanced Color Gradient (Red -> Orange -> Yellow -> Green)
	var fill_color = Color(1.0, 0.2, 0.2) # Red
	if val > 85:
		fill_color = Color(0.1, 0.9, 0.2) # Bright Green
	elif val > 70:
		fill_color = Color(0.6, 0.9, 0.1) # Lime
	elif val > 50:
		fill_color = Color(1.0, 0.8, 0.1) # Yellow
	elif val > 30:
		fill_color = Color(1.0, 0.5, 0.0) # Orange
		
	fill_style.bg_color = fill_color
	# Add subtle gradient to the fill
	fill_style.bg_color.a = 0.9
	bar.add_theme_stylebox_override("fill", fill_style)
	
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.05, 0.05, 0.05, 1.0)
	bg_style.border_width_left = 2
	bg_style.border_width_top = 2
	bg_style.border_width_right = 2
	bg_style.border_width_bottom = 2
	bg_style.border_color = Color(0.2, 0.2, 0.2)
	bg_style.set_corner_radius_all(12)
	bar.add_theme_stylebox_override("background", bg_style)
	
	if value_labels.has(key):
		value_labels[key].text = str(int(val)) + " / 100"
		value_labels[key].modulate = fill_color.lerp(Color.WHITE, 0.5)

func _play_entry_animation() -> void:
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 1.0, 0.6)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.6)

func _on_tab_changed(tab_idx: int) -> void:
	# Subtle punch animation when switching tabs
	var content = tab_container.get_tab_control(tab_idx)
	content.modulate.a = 0
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tween.tween_property(content, "modulate:a", 1.0, 0.3)
	
	if tab_container.get_tab_title(tab_idx) == "Success":
		_update_current_values()
		_animate_bars()

func _update_current_values() -> void:
	# If we are at the end of the game, show real values. 
	# For the initial charter, keep them high as goals.
	if GameState.completed_activities.size() > 5: # Threshold to detect if we are in endgame
		var ps = GameState.participant_satisfaction
		var eq = GameState.event_quality_score
		var ofs = (0.6 * ps) + (0.4 * eq)
		
		kpi_bars["Satisfaction"].set_meta("target_val", clamp(ps, 0, 100))
		kpi_bars["Quality"].set_meta("target_val", clamp(eq, 0, 100))
		kpi_bars["OFS"].set_meta("target_val", clamp(ofs, 0, 100))
		
		# Motivation
		kpi_bars["Motivation"].set_meta("target_val", clamp(GameState.team_motivation, 0, 100))
		
		# Budget (Simplified mapping: START_MONEY = 100, 0 = 50, -300k = 0)
		var budget_pct = 50.0 + (GameState.money / 8000.0) # Very rough mapping
		kpi_bars["Budget"].set_meta("target_val", clamp(budget_pct, 0, 100))
	else:
		# Initial Goals View
		for key in kpi_bars:
			kpi_bars[key].set_meta("target_val", 100)

func _animate_bars() -> void:
	for key in kpi_bars:
		var bar = kpi_bars[key]
		var target_val = bar.get_meta("target_val")
		bar.value = 0
		var tween = create_tween().set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
		tween.tween_property(bar, "value", target_val, 1.2).set_delay(randf() * 0.3)
		
		# Update style and label during animation
		tween.parallel().tween_method(func(v): _update_bar_style(key, v), 0.0, target_val, 1.2)

func _on_accept_pressed() -> void:
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "modulate:a", 0.0, 0.4)
	tween.tween_property(self, "scale", Vector2(1.05, 1.05), 0.4)
	
	tween.chain().tween_callback(func():
		self.hide()
		activity_board.show()
		if GameState.has_method("start_game_timer"):
			GameState.start_game_timer()
	)

func _setup_gantt_chart_tab() -> void:
	# Create a MarginContainer for the tab
	var margin = MarginContainer.new()
	margin.name = "Gantt Chart"
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	
	# Wrap in a ScrollContainer so it scrolls nicely
	var scroll = ScrollContainer.new()
	scroll.name = "ScrollContainer"
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	margin.add_child(scroll)
	
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 25)
	scroll.add_child(vbox)
	
	# Header
	var header = Label.new()
	header.text = "PROJECT OPERATIONS GANTT CHART"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_font_size_override("font_size", 32)
	header.add_theme_color_override("font_color", Color(0.15, 0.55, 0.9))
	vbox.add_child(header)
	
	# Description Text (Immersive and beautiful)
	var desc = RichTextLabel.new()
	desc.bbcode_enabled = true
	desc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	desc.fit_content = true
	desc.add_theme_font_size_override("normal_font_size", 18)
	desc.add_theme_font_size_override("bold_font_size", 20)
	
	desc.text = "To guarantee a flawless Spring Festival execution, you must master the preparation operations and respect the operational dependencies between tasks.\n\n" + \
		"📅 Festival Day is scheduled to begin at the end of Week 10. Complete all critical preparations on time to ensure a successful launch.\n" + \
		"• [color=#ff334b][b]Critical Operations:[/b][/color] Activities with zero float (A, B, C, F, G, H, I, J, K, L, N, O). Delaying any of these will directly push back the final festival date!\n" + \
		"• [color=#3399ff][b]Non-critical activity:[/b][/color] Operations with float/flexibility (D, E, M) that can be rescheduled without affecting the critical path."
	vbox.add_child(desc)
	
	# Create a styled panel for the Gantt Chart
	var chart_panel = PanelContainer.new()
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.08, 0.1, 0.14, 0.75) # Dark glassmorphic background
	panel_style.border_width_left = 2
	panel_style.border_width_top = 2
	panel_style.border_width_right = 2
	panel_style.border_width_bottom = 2
	panel_style.border_color = Color(0.2, 0.3, 0.45, 0.8) # Light blue border
	panel_style.set_corner_radius_all(10)
	panel_style.content_margin_left = 15
	panel_style.content_margin_right = 15
	panel_style.content_margin_top = 15
	panel_style.content_margin_bottom = 15
	chart_panel.add_theme_stylebox_override("panel", panel_style)
	vbox.add_child(chart_panel)
	
	# Create a Gantt Chart layout container (HBox Container)
	var gantt_hbox = HBoxContainer.new()
	gantt_hbox.custom_minimum_size = Vector2(0, 800) # Large format!
	gantt_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chart_panel.add_child(gantt_hbox)
	
	# Left Column: Activity Labels
	var labels_vbox = VBoxContainer.new()
	labels_vbox.custom_minimum_size = Vector2(260, 0)
	labels_vbox.add_theme_constant_override("separation", 10)
	gantt_hbox.add_child(labels_vbox)
	
	# Right Column: Timeline Area (Control containing overlapping grid and rows)
	var timeline_area = Control.new()
	timeline_area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	timeline_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	gantt_hbox.add_child(timeline_area)
	
	# Grid Background first (drawn behind bars)
	var grid_bg = Control.new()
	grid_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	# Rows VBoxContainer (drawn over GridBG)
	var rows_vbox = VBoxContainer.new()
	rows_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	rows_vbox.add_theme_constant_override("separation", 10)
	timeline_area.add_child(rows_vbox)
	
	var activities = [
		{"name": "Team Assignment", "code": "A", "duration": 4, "es": 0, "ef": 4, "is_critical": true},
		{"name": "Initial Layout Mapping", "code": "B", "duration": 4, "es": 0, "ef": 4, "is_critical": true},
		{"name": "Emergency Plan Training", "code": "C", "duration": 4, "es": 4, "ef": 8, "is_critical": true},
		{"name": "Sponsor Management", "code": "D", "duration": 8, "es": 4, "ef": 12, "is_critical": false},
		{"name": "Entertainment Line-Up", "code": "F", "duration": 8, "es": 8, "ef": 16, "is_critical": true},
		{"name": "Promotion Strategy", "code": "E", "duration": 4, "es": 12, "ef": 16, "is_critical": false},
		{"name": "Ticket Pricing Strategy", "code": "G", "duration": 4, "es": 16, "ef": 20, "is_critical": true},
		{"name": "Volunteer/Club Recruitment", "code": "H", "duration": 4, "es": 16, "ef": 20, "is_critical": true},
		{"name": "Food Vendor Selection", "code": "I", "duration": 4, "es": 20, "ef": 24, "is_critical": true},
		{"name": "Stage Setup Choices", "code": "J", "duration": 4, "es": 24, "ef": 28, "is_critical": true},
		{"name": "Sound System Choices", "code": "K", "duration": 4, "es": 24, "ef": 28, "is_critical": true},
		{"name": "Transport Coordination", "code": "L", "duration": 4, "es": 24, "ef": 28, "is_critical": true},
		{"name": "Decoration Theme Decision", "code": "M", "duration": 2, "es": 28, "ef": 30, "is_critical": false},
		{"name": "Festival Cleaning & Security", "code": "N", "duration": 4, "es": 28, "ef": 32, "is_critical": true},
		{"name": "Facility Layout Mapping", "code": "O", "duration": 4, "es": 28, "ef": 32, "is_critical": true}
	]
	
	for act in activities:
		# Add Label to left column
		var lbl = Label.new()
		lbl.text = act["name"]
		lbl.custom_minimum_size = Vector2(0, 40)
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl.add_theme_font_size_override("font_size", 14)
		lbl.add_theme_color_override("font_color", Color(0.85, 0.85, 0.9))
		labels_vbox.add_child(lbl)
		
		# Add Timeline Row to right column
		var row = Control.new()
		row.custom_minimum_size = Vector2(0, 40)
		rows_vbox.add_child(row)
		
		# Draw the bar in the row
		var bar = Panel.new()
		bar.anchor_left = float(act["es"]) / 34.0
		bar.anchor_right = float(act["ef"]) / 34.0
		bar.anchor_top = 0.15
		bar.anchor_bottom = 0.85
		bar.offset_left = 0
		bar.offset_top = 0
		bar.offset_right = 0
		bar.offset_bottom = 0
		
		# Styling the bar
		var style = StyleBoxFlat.new()
		if act["is_critical"]:
			style.bg_color = Color(0.85, 0.15, 0.25, 0.9)
			style.border_color = Color(1.0, 0.45, 0.55)
		else:
			style.bg_color = Color(0.15, 0.45, 0.7, 0.9)
			style.border_color = Color(0.4, 0.7, 0.9)
			
		style.border_width_left = 1
		style.border_width_top = 1
		style.border_width_right = 1
		style.border_width_bottom = 1
		style.set_corner_radius_all(4)
		bar.add_theme_stylebox_override("panel", style)
		row.add_child(bar)
		
		# Code and duration inside the bar (e.g. A (4))
		var bar_lbl = Label.new()
		bar_lbl.text = act["code"] + " (" + str(act["duration"]) + ")"
		bar_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		bar_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		bar_lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
		bar_lbl.add_theme_font_size_override("font_size", 12)
		bar_lbl.add_theme_color_override("font_color", Color.WHITE)
		bar.add_child(bar_lbl)
		
		# Add ES and EF labels
		if act["es"] > 0:
			var es_lbl = Label.new()
			es_lbl.text = "ES=" + str(act["es"])
			es_lbl.anchor_left = float(act["es"]) / 34.0
			es_lbl.anchor_right = float(act["es"]) / 34.0
			es_lbl.offset_left = -45
			es_lbl.offset_right = -5
			es_lbl.anchor_top = 0.2
			es_lbl.anchor_bottom = 0.8
			es_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			es_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			es_lbl.add_theme_font_size_override("font_size", 10)
			es_lbl.modulate = Color(0.6, 0.6, 0.6)
			row.add_child(es_lbl)
			
		var ef_lbl = Label.new()
		ef_lbl.text = "EF=" + str(act["ef"])
		ef_lbl.anchor_left = float(act["ef"]) / 34.0
		ef_lbl.anchor_right = float(act["ef"]) / 34.0
		ef_lbl.offset_left = 5
		ef_lbl.offset_right = 45
		ef_lbl.anchor_top = 0.2
		ef_lbl.anchor_bottom = 0.8
		ef_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		ef_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		ef_lbl.add_theme_font_size_override("font_size", 10)
		ef_lbl.modulate = Color(0.6, 0.6, 0.6)
		row.add_child(ef_lbl)

	# Bottom axis row for labels_vbox
	var axis_title_lbl = Label.new()
	axis_title_lbl.text = "Timeline (Weeks):"
	axis_title_lbl.custom_minimum_size = Vector2(0, 40)
	axis_title_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	axis_title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	axis_title_lbl.add_theme_font_size_override("font_size", 14)
	axis_title_lbl.add_theme_color_override("font_color", Color(0.6, 0.7, 0.8))
	labels_vbox.add_child(axis_title_lbl)
	
	# Bottom axis row for rows_vbox
	var axis_row = Control.new()
	axis_row.custom_minimum_size = Vector2(0, 40)
	rows_vbox.add_child(axis_row)
	
	# Add week labels (0, 2, 4, ..., 34)
	for i in range(18):
		var week = i * 2
		var week_lbl = Label.new()
		week_lbl.text = str(week)
		week_lbl.anchor_left = float(week) / 34.0
		week_lbl.anchor_right = float(week) / 34.0
		week_lbl.offset_left = -15
		week_lbl.offset_right = 15
		week_lbl.anchor_top = 0.1
		week_lbl.anchor_bottom = 0.9
		week_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		week_lbl.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		week_lbl.add_theme_font_size_override("font_size", 12)
		week_lbl.add_theme_color_override("font_color", Color(0.7, 0.8, 0.9))
		axis_row.add_child(week_lbl)
		
	# Grid draw callback definition
	grid_bg.draw.connect(func():
		var steps = 17 # 34 / 2
		var col = Color(0.3, 0.35, 0.4, 0.15) # Very soft grid lines
		
		# Find the position of the axis row relative to grid_bg
		var base_y = grid_bg.size.y - 40
		if axis_row.is_inside_tree():
			base_y = axis_row.position.y - 5
			
		for i in range(steps + 1):
			var week = i * 2
			var x = (float(week) / 34.0) * grid_bg.size.x
			# Draw vertical grid line
			grid_bg.draw_line(Vector2(x, 0), Vector2(x, base_y), col, 1.0)
		
		# Draw horizontal baseline for the axis
		grid_bg.draw_line(Vector2(0, base_y), Vector2(grid_bg.size.x, base_y), Color(0.5, 0.5, 0.6, 0.4), 2.0)
	)
	timeline_area.add_child(grid_bg)
	
	# Move RowsVBox to draw over the grid background lines
	timeline_area.move_child(rows_vbox, timeline_area.get_child_count() - 1)
	
	# Footer Accept Button
	var footer = HBoxContainer.new()
	footer.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(footer)
	
	var accept_btn = Button.new()
	accept_btn.text = "Accept and Start Project"
	accept_btn.custom_minimum_size = Vector2(300, 60)
	accept_btn.add_theme_font_size_override("font_size", 22)
	accept_btn.pressed.connect(_on_accept_pressed)
	footer.add_child(accept_btn)
	
	tab_container.add_child(margin)
	tab_container.set_tab_title(margin.get_index(), "Gantt Chart")
