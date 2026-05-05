extends Control

@export var game_scene: PackedScene

func _ready():
	$CenterContainer/VBoxContainer/Label.add_theme_font_size_override("font_size", 64)
	$CenterContainer/VBoxContainer/StartButton.custom_minimum_size = Vector2(400, 80)
	$CenterContainer/VBoxContainer/StartButton.add_theme_font_size_override("font_size", 32)
	$CenterContainer/VBoxContainer/StartButton.pressed.connect(_on_start_pressed)
	
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

func _on_start_pressed():
	GameState.skip_onboarding = false
	# Eğer Inspector’dan game_scene set etmediysen fallback:
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
