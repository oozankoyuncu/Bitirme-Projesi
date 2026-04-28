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

func _ready() -> void:
	accept_button.pressed.connect(_on_accept_pressed)
	tab_container.tab_changed.connect(_on_tab_changed)
	_setup_styles()
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

func _initialize_kpi_styles() -> void:
	for key in kpi_bars:
		var bar = kpi_bars[key]
		bar.value = bar.max_value
		bar.set_meta("target_val", bar.value)
		var fill_style = StyleBoxFlat.new()
		fill_style.set_corner_radius_all(10)
		
		# Set color based on value (Gradient: Red -> Yellow -> Green)
		var val = bar.value
		var fill_color = Color.RED
		if val > 80:
			fill_color = Color(0.2, 0.8, 0.2) # Green
		elif val > 50:
			fill_color = Color(1.0, 0.8, 0.2) # Gold/Amber
		elif val > 30:
			fill_color = Color(1.0, 0.5, 0.0) # Orange
			
		fill_style.bg_color = fill_color
		bar.add_theme_stylebox_override("fill", fill_style)
		
		var bg_style = StyleBoxFlat.new()
		bg_style.bg_color = Color(0.1, 0.1, 0.1, 1.0)
		bg_style.set_corner_radius_all(10)
		bar.add_theme_stylebox_override("background", bg_style)

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
		_animate_bars()

func _animate_bars() -> void:
	for key in kpi_bars:
		var bar = kpi_bars[key]
		var target_val = bar.get_meta("target_val")
		bar.value = 0
		var tween = create_tween().set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
		tween.tween_property(bar, "value", target_val, 1.2).set_delay(randf() * 0.3)

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
