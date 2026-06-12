extends Control

@export var game_scene: PackedScene

var video_overlay: ColorRect
var video_player: VideoStreamPlayer
var close_btn: Button

# Playback kontrolleri
var play_pause_btn: Button
var rewind_btn: Button
var forward_btn: Button
var seek_slider: HSlider
var time_label: Label
var controls_bar: PanelContainer
var is_slider_dragging: bool = false
var SEEK_STEP: float = 10.0

func _ready():
	$CenterContainer/VBoxContainer/Label.add_theme_font_size_override("font_size", 64)
	$CenterContainer/VBoxContainer/StartButton.custom_minimum_size = Vector2(400, 80)
	$CenterContainer/VBoxContainer/StartButton.add_theme_font_size_override("font_size", 32)
	$CenterContainer/VBoxContainer/StartButton.pressed.connect(_on_start_pressed)

	# --- How to Play butonu ---
	var how_to_play_btn = Button.new()
	how_to_play_btn.text = "How to Play"
	how_to_play_btn.custom_minimum_size = Vector2(400, 80)
	how_to_play_btn.add_theme_font_size_override("font_size", 32)
	how_to_play_btn.pressed.connect(_on_how_to_play_pressed)
	# StartButton'dan hemen sonra ekle
	var start_idx = $CenterContainer/VBoxContainer/StartButton.get_index()
	$CenterContainer/VBoxContainer.add_child(how_to_play_btn)
	$CenterContainer/VBoxContainer.move_child(how_to_play_btn, start_idx + 1)

	# --- Skip butonu ---
	var skip_btn = Button.new()
	skip_btn.text = "Direct to Activity Board"
	skip_btn.custom_minimum_size = Vector2(400, 80)
	skip_btn.add_theme_font_size_override("font_size", 32)
	skip_btn.pressed.connect(_on_skip_pressed)

	# Quit butonu varsa:
	if has_node("CenterContainer/VBoxContainer/QuitButton"):
		var quit_btn = $CenterContainer/VBoxContainer/QuitButton
		quit_btn.pressed.connect(_on_quit_pressed)
		$CenterContainer/VBoxContainer.add_child(skip_btn)
		$CenterContainer/VBoxContainer.move_child(skip_btn, quit_btn.get_index())
	else:
		$CenterContainer/VBoxContainer.add_child(skip_btn)

	# --- Video overlay (başta gizli) ---
	_create_video_overlay()
	set_process(false)

func _process(_delta):
	if not video_overlay.visible or video_player.stream == null:
		return
	var length = video_player.get_stream_length()
	var pos = video_player.stream_position
	# Slider'ı güncelle (kullanıcı sürüklemiyorsa)
	if not is_slider_dragging and length > 0:
		seek_slider.value = pos / length * 100.0
	# Zaman etiketini güncelle
	time_label.text = _format_time(pos) + " / " + _format_time(length)

func _create_video_overlay():
	# Yarı-saydam siyah arka plan
	video_overlay = ColorRect.new()
	video_overlay.color = Color(0, 0, 0, 0.95)
	video_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	video_overlay.visible = false
	video_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(video_overlay)

	# Video oynatıcı – ekranı kaplar (alt kısımda kontrol çubuğuna yer bırak)
	video_player = VideoStreamPlayer.new()
	video_player.set_anchors_preset(Control.PRESET_FULL_RECT)
	video_player.anchor_bottom = 1.0
	video_player.offset_bottom = -80
	video_player.expand = true
	video_player.finished.connect(_on_video_finished)
	video_overlay.add_child(video_player)

	# Kapat / Geri butonu (sağ üst köşe)
	close_btn = Button.new()
	close_btn.text = "✕  Close"
	close_btn.add_theme_font_size_override("font_size", 24)
	close_btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	close_btn.position = Vector2(-160, 12)
	close_btn.custom_minimum_size = Vector2(140, 44)
	close_btn.pressed.connect(_on_close_video_pressed)
	video_overlay.add_child(close_btn)

	# ====== Alt Kontrol Çubuğu ======
	controls_bar = PanelContainer.new()
	controls_bar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	controls_bar.anchor_top = 1.0
	controls_bar.anchor_bottom = 1.0
	controls_bar.offset_top = -80
	controls_bar.offset_bottom = 0
	# Koyu yarı-saydam arka plan stili
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.12, 0.9)
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	controls_bar.add_theme_stylebox_override("panel", style)
	video_overlay.add_child(controls_bar)

	# Ana yatay konteyner
	var main_vbox = VBoxContainer.new()
	main_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_vbox.add_theme_constant_override("separation", 4)
	controls_bar.add_child(main_vbox)

	# --- Üst satır: Seek slider ---
	seek_slider = HSlider.new()
	seek_slider.min_value = 0.0
	seek_slider.max_value = 100.0
	seek_slider.step = 0.1
	seek_slider.value = 0.0
	seek_slider.custom_minimum_size = Vector2(0, 24)
	seek_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	seek_slider.drag_started.connect(_on_slider_drag_started)
	seek_slider.drag_ended.connect(_on_slider_drag_ended)
	main_vbox.add_child(seek_slider)

	# --- Alt satır: Butonlar + zaman ---
	var btn_row = HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 16)
	main_vbox.add_child(btn_row)

	# 10 saniye geri
	rewind_btn = Button.new()
	rewind_btn.text = "⏪ 10s"
	rewind_btn.add_theme_font_size_override("font_size", 22)
	rewind_btn.custom_minimum_size = Vector2(100, 38)
	rewind_btn.pressed.connect(_on_rewind_pressed)
	btn_row.add_child(rewind_btn)

	# Oynat / Duraklat
	play_pause_btn = Button.new()
	play_pause_btn.text = "⏸ Pause"
	play_pause_btn.add_theme_font_size_override("font_size", 22)
	play_pause_btn.custom_minimum_size = Vector2(120, 38)
	play_pause_btn.pressed.connect(_on_play_pause_pressed)
	btn_row.add_child(play_pause_btn)

	# 10 saniye ileri
	forward_btn = Button.new()
	forward_btn.text = "10s ⏩"
	forward_btn.add_theme_font_size_override("font_size", 22)
	forward_btn.custom_minimum_size = Vector2(100, 38)
	forward_btn.pressed.connect(_on_forward_pressed)
	btn_row.add_child(forward_btn)

	# Zaman etiketi
	time_label = Label.new()
	time_label.text = "00:00 / 00:00"
	time_label.add_theme_font_size_override("font_size", 20)
	time_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	btn_row.add_child(time_label)

# ========== Video kontrol fonksiyonları ==========

func _on_how_to_play_pressed():
	var stream = load("res://Project Report and Documents/howtoplay.ogv")
	if stream == null:
		push_error("howtoplay.ogv yüklenemedi!")
		return
	video_player.stream = stream
	video_overlay.visible = true
	video_player.play()
	play_pause_btn.text = "⏸ Pause"
	set_process(true)

func _on_play_pause_pressed():
	if video_player.paused:
		video_player.paused = false
		play_pause_btn.text = "⏸ Pause"
	else:
		video_player.paused = true
		play_pause_btn.text = "▶ Play"

func _on_rewind_pressed():
	var new_pos = max(0.0, video_player.stream_position - SEEK_STEP)
	video_player.stream_position = new_pos

func _on_forward_pressed():
	var length = video_player.get_stream_length()
	var new_pos = min(length, video_player.stream_position + SEEK_STEP)
	video_player.stream_position = new_pos

func _on_slider_drag_started():
	is_slider_dragging = true

func _on_slider_drag_ended(value_changed: bool):
	is_slider_dragging = false
	if value_changed:
		var length = video_player.get_stream_length()
		video_player.stream_position = seek_slider.value / 100.0 * length

func _on_video_finished():
	_close_video()

func _on_close_video_pressed():
	_close_video()

func _close_video():
	video_player.stop()
	video_overlay.visible = false
	set_process(false)
	seek_slider.value = 0
	time_label.text = "00:00 / 00:00"

func _format_time(seconds: float) -> String:
	var mins = int(seconds) / 60
	var secs = int(seconds) % 60
	return "%02d:%02d" % [mins, secs]

# ========== Menü fonksiyonları ==========

func _on_start_pressed():
	GameState.skip_onboarding = false
	# Eğer Inspector'dan game_scene set etmediysen fallback:
	if game_scene == null:
		if GameState.has_method("reset"):
			GameState.reset()

		get_tree().change_scene_to_file("res://Game.tscn")
	else:
		get_tree().change_scene_to_packed(game_scene)

func _on_skip_pressed():
	GameState.skip_onboarding = true
	if game_scene == null:
		if GameState.has_method("reset"):
			GameState.reset()

		get_tree().change_scene_to_file("res://Game.tscn")
	else:
		get_tree().change_scene_to_packed(game_scene)

func _on_quit_pressed():
	get_tree().quit()
