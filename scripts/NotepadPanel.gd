extends CanvasLayer

# Dynamic nodes
var main_container: Control
var dim_bg: ColorRect
var center_container: CenterContainer
var notepad_box: PanelContainer
var text_edit: TextEdit
var close_btn: Button
var save_btn: Button

var is_open: bool = false
var is_animating: bool = false

func _ready() -> void:
	layer = 150 # Make sure it is on top of HUD (layer 100) and other layers
	
	# Create full screen main container
	main_container = Control.new()
	main_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(main_container)
	
	# Create Dim background
	dim_bg = ColorRect.new()
	dim_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim_bg.color = Color(0.0, 0.0, 0.0, 0.5)
	main_container.add_child(dim_bg)
	
	# Handle clicking dim_bg to close notepad
	dim_bg.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			close_notepad()
	)
	
	# Create Center Container
	center_container = CenterContainer.new()
	center_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	main_container.add_child(center_container)
	
	# Create Notepad PanelContainer
	notepad_box = PanelContainer.new()
	notepad_box.custom_minimum_size = Vector2(900, 700)
	notepad_box.pivot_offset = Vector2(450, 350)
	center_container.add_child(notepad_box)
	
	# Create Margin Container inside Notepad
	var margin_container = MarginContainer.new()
	margin_container.add_theme_constant_override("margin_left", 25)
	margin_container.add_theme_constant_override("margin_right", 25)
	margin_container.add_theme_constant_override("margin_top", 25)
	margin_container.add_theme_constant_override("margin_bottom", 25)
	notepad_box.add_child(margin_container)
	
	# Create VBoxContainer inside Margin Container
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	margin_container.add_child(vbox)
	
	# Header
	var header = HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	vbox.add_child(header)
	
	var title_lbl = Label.new()
	title_lbl.text = "🗒️ STRATEGIC PLANNING NOTES"
	title_lbl.add_theme_font_size_override("font_size", 24)
	title_lbl.add_theme_color_override("font_color", Color(0.15, 0.55, 0.9)) # Electric blue
	header.add_child(title_lbl)
	
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)
	
	close_btn = Button.new()
	close_btn.text = "  X  "
	close_btn.custom_minimum_size = Vector2(45, 45)
	close_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	header.add_child(close_btn)
	
	# TextEdit
	text_edit = TextEdit.new()
	text_edit.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(text_edit)
	
	# Footer
	var footer = HBoxContainer.new()
	vbox.add_child(footer)
	
	var tip_lbl = Label.new()
	tip_lbl.text = "Press 'N' to open/close | Press ESC to close | Auto-saved"
	tip_lbl.add_theme_font_size_override("font_size", 16)
	tip_lbl.modulate = Color(0.6, 0.6, 0.6)
	footer.add_child(tip_lbl)
	
	var footer_spacer = Control.new()
	footer_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(footer_spacer)
	
	save_btn = Button.new()
	save_btn.text = " Save & Close "
	save_btn.custom_minimum_size = Vector2(160, 45)
	save_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	footer.add_child(save_btn)
	
	# Hide by default
	hide_panel_instant()
	_setup_styles()
	
	# Connect signals
	text_edit.text_changed.connect(_on_text_changed)

func _setup_styles() -> void:
	# Notepad panel styling
	var box_style = StyleBoxFlat.new()
	box_style.bg_color = Color(0.08, 0.1, 0.14, 0.96)
	box_style.set_corner_radius_all(16)
	box_style.border_width_left = 2
	box_style.border_width_top = 2
	box_style.border_width_right = 2
	box_style.border_width_bottom = 2
	box_style.border_color = Color(0.15, 0.55, 0.9, 0.8)
	box_style.shadow_size = 30
	box_style.shadow_color = Color(0, 0, 0, 0.6)
	notepad_box.add_theme_stylebox_override("panel", box_style)
	
	# TextEdit styling
	text_edit.placeholder_text = "Write your plans, strategies, or reminders here...\nThese notes will be deleted when the game ends."
	text_edit.add_theme_font_size_override("font_size", 20)
	text_edit.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95))
	text_edit.caret_blink = true
	text_edit.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	
	var te_style_normal = StyleBoxFlat.new()
	te_style_normal.bg_color = Color(0.04, 0.06, 0.08, 1.0)
	te_style_normal.set_corner_radius_all(12)
	te_style_normal.border_width_left = 1
	te_style_normal.border_width_top = 1
	te_style_normal.border_width_right = 1
	te_style_normal.border_width_bottom = 1
	te_style_normal.border_color = Color(0.2, 0.25, 0.3)
	te_style_normal.content_margin_left = 12
	te_style_normal.content_margin_right = 12
	te_style_normal.content_margin_top = 12
	te_style_normal.content_margin_bottom = 12
	text_edit.add_theme_stylebox_override("normal", te_style_normal)
	
	var te_style_focus = StyleBoxFlat.new()
	te_style_focus.bg_color = Color(0.04, 0.06, 0.08, 1.0)
	te_style_focus.set_corner_radius_all(12)
	te_style_focus.border_width_left = 2
	te_style_focus.border_width_top = 2
	te_style_focus.border_width_right = 2
	te_style_focus.border_width_bottom = 2
	te_style_focus.border_color = Color(0.15, 0.55, 0.9, 0.8)
	te_style_focus.content_margin_left = 12
	te_style_focus.content_margin_right = 12
	te_style_focus.content_margin_top = 12
	te_style_focus.content_margin_bottom = 12
	text_edit.add_theme_stylebox_override("focus", te_style_focus)
	
	# Close button styling
	var close_btn_normal = StyleBoxFlat.new()
	close_btn_normal.bg_color = Color(0.2, 0.2, 0.2, 0.5)
	close_btn_normal.set_corner_radius_all(8)
	
	var close_btn_hover = StyleBoxFlat.new()
	close_btn_hover.bg_color = Color(0.8, 0.2, 0.2, 0.8)
	close_btn_hover.set_corner_radius_all(8)
	
	close_btn.add_theme_stylebox_override("normal", close_btn_normal)
	close_btn.add_theme_stylebox_override("hover", close_btn_hover)
	close_btn.add_theme_font_size_override("font_size", 18)
	close_btn.pressed.connect(close_notepad)
	
	# Save button styling
	var save_btn_normal = StyleBoxFlat.new()
	save_btn_normal.bg_color = Color(0.15, 0.55, 0.9)
	save_btn_normal.set_corner_radius_all(8)
	
	var save_btn_hover = StyleBoxFlat.new()
	save_btn_hover.bg_color = Color(0.2, 0.65, 1.0)
	save_btn_hover.set_corner_radius_all(8)
	
	save_btn.add_theme_stylebox_override("normal", save_btn_normal)
	save_btn.add_theme_stylebox_override("hover", save_btn_hover)
	save_btn.add_theme_font_size_override("font_size", 18)
	save_btn.pressed.connect(close_notepad)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_N:
			# If TextEdit doesn't have focus, toggle
			if not text_edit.has_focus():
				toggle_notepad()
				get_viewport().set_input_as_handled()
		elif event.keycode == KEY_ESCAPE:
			if is_open:
				close_notepad()
				get_viewport().set_input_as_handled()

func toggle_notepad() -> void:
	if is_open:
		close_notepad()
	else:
		open_notepad()

func open_notepad() -> void:
	if is_animating: return
	
	# Load notes from GameState
	text_edit.text = GameState.player_notes
	
	is_open = true
	is_animating = true
	main_container.visible = true
	
	# Reset state before animating
	notepad_box.scale = Vector2(0.9, 0.9)
	main_container.modulate.a = 0.0
	
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	tween.tween_property(main_container, "modulate:a", 1.0, 0.25)
	tween.tween_property(notepad_box, "scale", Vector2(1.0, 1.0), 0.25)
	
	tween.chain().tween_callback(func():
		is_animating = false
		text_edit.grab_focus()
		var last_line = text_edit.get_line_count() - 1
		text_edit.set_caret_line(last_line)
		text_edit.set_caret_column(text_edit.get_line_width(last_line))
	)

func close_notepad() -> void:
	if not is_open or is_animating: return
	
	is_open = false
	is_animating = true
	
	# Save notes
	GameState.player_notes = text_edit.text
	
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	tween.tween_property(main_container, "modulate:a", 0.0, 0.2)
	tween.tween_property(notepad_box, "scale", Vector2(0.9, 0.9), 0.2)
	
	tween.chain().tween_callback(func():
		main_container.visible = false
		is_animating = false
	)

func hide_panel_instant() -> void:
	main_container.visible = false
	main_container.modulate.a = 0.0
	notepad_box.scale = Vector2(0.9, 0.9)
	is_open = false
	is_animating = false

func _on_text_changed() -> void:
	GameState.player_notes = text_edit.text

func clear_ui_notes() -> void:
	text_edit.text = ""
	GameState.player_notes = ""
	hide_panel_instant()
