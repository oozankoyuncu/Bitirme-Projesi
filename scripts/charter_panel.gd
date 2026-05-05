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
	# Enlarge the main container
	if margin_container:
		margin_container.custom_minimum_size = Vector2(1100, 750)
	
	# Increase Header Font Sizes
	var header_paths = [
		"MarginContainer/TabContainer/Success/Margin/VBox/Header",
		"MarginContainer/TabContainer/Overview/Margin/VBox/Header/Title" # Fixed path
	]
	for path in header_paths:
		var h = get_node_or_null(path)
		if h and h.has_method("add_theme_font_size_override"):
			h.add_theme_font_size_override("font_size", 42)
	
	# Increase Subtitles
	var sub_paths = [
		"MarginContainer/TabContainer/Success/Margin/VBox/OFSFormula",
		"MarginContainer/TabContainer/Success/Margin/VBox/Sub",
		"MarginContainer/TabContainer/Overview/Margin/VBox/ConstraintHeader/ConstraintTitle"
	]
	for path in sub_paths:
		var s = get_node_or_null(path)
		if s and s.has_method("add_theme_font_size_override"):
			s.add_theme_font_size_override("font_size", 28) # Increased from 24
		
	# Adjust Tab Bar Scaling
	if tab_container:
		tab_container.add_theme_font_size_override("font_size", 22)
	
	# Adjust KPI List Container
	var kpi_list = get_node_or_null("MarginContainer/TabContainer/Success/Margin/VBox/TabContent/KPI_List")
	if kpi_list:
		kpi_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		kpi_list.add_theme_constant_override("separation", 25) 

func _add_ofs_explanation() -> void:
	var ofs_formula_label = get_node_or_null("MarginContainer/TabContainer/Success/Margin/VBox/OFSFormula")
	if not ofs_formula_label: return
	
	var explanation = Label.new()
	explanation.text = "Overall Festival Score (OFS) is the final success score of the project. It is calculated based on Participant Satisfaction (PS) and Event Quality (EQ). A higher OFS means the festival was managed more successfully."
	explanation.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	explanation.custom_minimum_size = Vector2(800, 0)
	explanation.add_theme_font_size_override("font_size", 22) # Increased from 18
	explanation.modulate = Color(0.8, 0.9, 1.0, 1.0) # Brighter
	
	var parent = ofs_formula_label.get_parent()
	var idx = ofs_formula_label.get_index()
	parent.add_child(explanation)
	parent.move_child(explanation, idx + 1)
	
	# Add some spacing
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 10)
	parent.add_child(spacer)
	parent.move_child(spacer, idx + 2)
	
	# Add Budget Warning Note
	var budget_warning = Label.new()
	budget_warning.text = "⚠️ FAILURE CONDITION: If the budget drops to -300,000 TL or below, the project is terminated immediately."
	budget_warning.add_theme_font_size_override("font_size", 22)
	budget_warning.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4)) # Reddish for warning
	budget_warning.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	budget_warning.custom_minimum_size = Vector2(800, 0)
	
	parent.add_child(budget_warning)
	parent.move_child(budget_warning, idx + 3)
	
	var spacer2 = Control.new()
	spacer2.custom_minimum_size = Vector2(0, 20)
	parent.add_child(spacer2)
	parent.move_child(spacer2, idx + 4)

func _create_ofs_metric() -> void:
	var kpi_list = get_node_or_null("MarginContainer/TabContainer/Success/Margin/VBox/TabContent/KPI_List")
	if not kpi_list: return
	
	# Create a separator
	var sep = HSeparator.new()
	sep.add_theme_constant_override("separation", 20)
	kpi_list.add_child(sep)
	
	# Create OFS KPI entry
	var ofs_vbox = VBoxContainer.new()
	ofs_vbox.name = "OFSKPI"
	kpi_list.add_child(ofs_vbox)
	
	var hbox = HBoxContainer.new()
	ofs_vbox.add_child(hbox)
	
	var label = Label.new()
	label.text = "OVERALL FESTIVAL SCORE (OFS)"
	label.add_theme_font_size_override("font_size", 26) # Increased from 22
	label.add_theme_color_override("font_color", Color(0.15, 0.55, 0.9))
	hbox.add_child(label)
	
	var spacer = Control.new()
	spacer.custom_minimum_size.x = 30 # Slightly more gap
	hbox.add_child(spacer)
	
	var bar = ProgressBar.new()
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.custom_minimum_size = Vector2(0, 30) # Slightly thinner for balance
	bar.show_percentage = false
	hbox.add_child(bar)
	
	kpi_bars["OFS"] = bar

func _initialize_kpi_styles() -> void:
	for key in kpi_bars:
		var bar = kpi_bars[key]
		bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bar.custom_minimum_size.y = 25 # Slightly thinner for balance
		bar.value = 100
		bar.set_meta("target_val", bar.value)
		
		var hbox = bar.get_parent()
		if hbox is HBoxContainer:
			hbox.add_theme_constant_override("separation", 25)
			
			var name_label = hbox.get_child(0)
			if name_label is Label:
				name_label.add_theme_font_size_override("font_size", 24) # Increased from 20
				name_label.custom_minimum_size.x = 280 # Wider for longer names/bigger font
			
			for child in hbox.get_children():
				if child is Control and not child is Label and not child is ProgressBar:
					child.custom_minimum_size.x = 30
		
		var val_label = Label.new()
		val_label.name = "ValueLabel"
		val_label.text = str(int(bar.value)) + " / 100"
		val_label.custom_minimum_size = Vector2(120, 0)
		val_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		val_label.add_theme_font_size_override("font_size", 24) # Increased from 20
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
