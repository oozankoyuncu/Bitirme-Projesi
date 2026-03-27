extends Control

@export var game_scene: PackedScene

func _ready():
	$CenterContainer/VBoxContainer/StartButton.pressed.connect(_on_start_pressed)
	# Quit butonu varsa:
	if has_node("CenterContainer/VBoxContainer/QuitButton"):
		$CenterContainer/VBoxContainer/QuitButton.pressed.connect(_on_quit_pressed)

func _on_start_pressed():
	# Eğer Inspector’dan game_scene set etmediysen fallback:
	if game_scene == null:
		if GameState.has_method("reset"):
			GameState.reset()

		get_tree().change_scene_to_file("res://Game.tscn")
	else:
		get_tree().change_scene_to_packed(game_scene)

func _on_quit_pressed():
	get_tree().quit()
