extends VBoxContainer

@onready var hud: Label = $HUD
var hbox: HBoxContainer
var clock: Control

func _ready():
	GameState.time_changed.connect(_refresh_time)
	
	# Set font size and spacing properties
	hud.add_theme_font_size_override("font_size", 24) # ~2 points bigger usually, or just noticeably bigger
	hud.add_theme_constant_override("outline_size", 4)
	
	# Reparent HUD and add Clock
	hbox = HBoxContainer.new()
	add_child(hbox)
	move_child(hbox, 0)
	
	# Create a custom drawn control for the clock
	clock = Control.new()
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
			draw_polygon(pts, PackedColorArray([Color(0.4, 0.7, 1.0, 0.8)]))
	
	draw_arc(center, radius, 0, TAU, 32, Color(1, 1, 1, 0.5), 2.0, true)
	
	# Minute hand
	var minute_angle = (current_time / 60.0) * TAU - PI / 2.0
	var minute_hand_end = center + Vector2(cos(minute_angle), sin(minute_angle)) * (radius * 0.8)
	draw_line(center, minute_hand_end, Color(1.0, 1.0, 1.0), 1.5, true)
	
	# Hour hand
	var hour_angle = (current_time / 240.0) * TAU - PI / 2.0
	var hour_hand_end = center + Vector2(cos(hour_angle), sin(hour_angle)) * (radius * 0.5)
	draw_line(center, hour_hand_end, Color(1.0, 1.0, 1.0), 2.5, true)
"""
	clock_script.reload()
	clock.set_script(clock_script)
	clock.set_process(true)
	
	# Add spacing control to slightly offset the clock from text
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(10, 0)
	
	remove_child(hud)
	hbox.add_child(clock)
	hbox.add_child(spacer)
	hbox.add_child(hud)
	
	_refresh_time()

func _refresh_time():
	hud.text = GameState.get_hud_text()
