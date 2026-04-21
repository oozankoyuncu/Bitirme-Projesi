extends Control

@onready var email_box: PanelContainer = $MarginContainer/HBox/EmailSide/EmailBox
@onready var body_label: Label = $MarginContainer/HBox/EmailSide/EmailBox/Margin/Content/BodyLabel
@onready var accept_button: Button = $MarginContainer/HBox/EmailSide/EmailBox/Margin/Content/AcceptButton
@onready var charter_panel: Control = get_parent().get_node("CharterPanel")

# Character Nodes
@onready var character_container: VBoxContainer = $MarginContainer/HBox/CharacterContainer
@onready var welcome_bubble: PanelContainer = $MarginContainer/HBox/CharacterContainer/Bubble
@onready var mentor_character: TextureRect = $MarginContainer/HBox/CharacterContainer/MentorCharacterContainer/MentorCharacter

var full_text: String = ""
var typing_speed: float = 0.02
var is_typing: bool = false

func _ready() -> void:
	accept_button.pressed.connect(_on_accept_pressed)
	full_text = body_label.text
	body_label.text = ""
	accept_button.modulate.a = 0
	accept_button.disabled = true
	
	_setup_styles()
	
	# Initial states for animations
	character_container.modulate.a = 0
	welcome_bubble.scale = Vector2.ZERO
	
	_start_onboarding_sequence()

func _setup_styles() -> void:
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.05, 0.07, 0.1, 0.4)
	add_theme_stylebox_override("panel", bg_style)

	var box_style = StyleBoxFlat.new()
	box_style.bg_color = Color(0.12, 0.15, 0.18, 0.92)
	box_style.border_width_left = 4
	box_style.border_color = Color(0.15, 0.55, 0.9)
	box_style.set_corner_radius_all(12)
	box_style.shadow_color = Color(0, 0, 0, 0.5)
	box_style.shadow_size = 20
	email_box.add_theme_stylebox_override("panel", box_style)
	
	var bubble_style = StyleBoxFlat.new()
	bubble_style.bg_color = Color(0.15, 0.55, 0.9)
	bubble_style.set_corner_radius_all(15)
	welcome_bubble.add_theme_stylebox_override("panel", bubble_style)

func _start_onboarding_sequence() -> void:
	# 1. Character Entry
	var char_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	char_tween.tween_property(character_container, "modulate:a", 1.0, 1.0)
	
	# 2. Bubble Pop
	char_tween.chain().tween_property(welcome_bubble, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	
	# 3. Start Typing Email
	char_tween.chain().tween_callback(_start_typing)
	
	# 4. Start Idle Animation
	_start_idle_animation()

func _start_idle_animation() -> void:
	var idle_tween = create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	# Subtle floating
	idle_tween.tween_property(mentor_character, "position:y", mentor_character.position.y - 10, 2.0)
	idle_tween.tween_property(mentor_character, "position:y", mentor_character.position.y, 2.0)

func _start_typing() -> void:
	is_typing = true
	var tween = create_tween()
	for i in range(full_text.length() + 1):
		tween.tween_callback(func(): body_label.text = full_text.substr(0, i)).set_delay(typing_speed)
	
	tween.chain().tween_property(accept_button, "modulate:a", 1.0, 0.5)
	tween.chain().tween_callback(func(): 
		accept_button.disabled = false
		is_typing = false
	)

func _on_accept_pressed() -> void:
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	
	tween.chain().tween_callback(func():
		self.hide()
		charter_panel.show()
		charter_panel.modulate.a = 0
		charter_panel.scale = Vector2(0.9, 0.9)
	)
