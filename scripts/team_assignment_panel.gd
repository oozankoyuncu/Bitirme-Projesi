extends Panel


@onready var member_list: VBoxContainer = $MarginContainer/VBoxContainer/MemberList

@onready var confirm_button: Button = $ConfirmButton

@onready var comm_label: Label = $MarginContainer/VBoxContainer/VBoxContainer/CommLabel
@onready var comm_bar: ProgressBar = $MarginContainer/VBoxContainer/VBoxContainer/CommBar

@onready var speed_label: Label = $MarginContainer/VBoxContainer/VBoxContainer/SpeedLabel
@onready var speed_bar: ProgressBar = $MarginContainer/VBoxContainer/VBoxContainer/SpeedBar

@onready var reliability_label: Label = $MarginContainer/VBoxContainer/VBoxContainer/ReliabilityLabel
@onready var reliability_bar: ProgressBar = $MarginContainer/VBoxContainer/VBoxContainer/ReliabilityBar

func _ready() -> void:
	confirm_button.pressed.connect(_on_confirm_pressed)

	create_member_checkboxes()
	update_stats_display()


func create_member_checkboxes() -> void:
	# Eski checkboxları temizle
	for child in member_list.get_children():
		child.queue_free()

	# GameState içinde yüklenmediyse yüklemeyi dene
	if GameState.all_team_members.is_empty():
		GameState.load_team_members()

	for member in GameState.all_team_members:
		var checkbox := CheckBox.new()
		checkbox.text = member["name"] + \
			" | Comm: " + str(member["communication"]) + \
			" | Speed: " + str(member["speed"]) + \
			" | Rel: " + str(member["reliability"])

		checkbox.set_meta("member_data", member)
		checkbox.toggled.connect(_on_selection_changed)

		member_list.add_child(checkbox)


func get_selected_members() -> Array:
	var selected: Array = []

	for child in member_list.get_children():
		if child is CheckBox and child.button_pressed:
			selected.append(child.get_meta("member_data"))

	return selected


func update_stats_display() -> void:
	var selected := get_selected_members()

	if selected.is_empty():
		comm_label.text = "Communication: 0.0"
		speed_label.text = "Speed: 0.0"
		reliability_label.text = "Reliability: 0.0"

		comm_bar.value = 0
		speed_bar.value = 0
		reliability_bar.value = 0
		return

	var total_comm: float = 0.0
	var total_speed: float = 0.0
	var total_reliability: float = 0.0

	for member in selected:
		total_comm += member["communication"]
		total_speed += member["speed"]
		total_reliability += member["reliability"]

	var count := selected.size()

	var avg_comm := total_comm / count
	var avg_speed := total_speed / count
	var avg_reliability := total_reliability / count

	comm_label.text = "Communication: %.1f" % avg_comm
	speed_label.text = "Speed: %.1f" % avg_speed
	reliability_label.text = "Reliability: %.1f" % avg_reliability

	comm_bar.value = avg_comm
	speed_bar.value = avg_speed
	reliability_bar.value = avg_reliability


func _on_selection_changed(_pressed: bool) -> void:
	update_stats_display()


func _on_confirm_pressed() -> void:
	var selected := get_selected_members()

	if selected.is_empty():
		print("En az bir üye seçmelisin")
		return

	GameState.selected_team = selected
	for member in selected:
		GameState.money -= member["cost"]
	if not GameState.completed_activities.has("team_assignment"):
		GameState.completed_activities.append("team_assignment")
	for member in GameState.selected_team:
		print(member["name"])
	hide()
	get_parent().get_node("ActivityBoard").show()
	get_parent().get_node("ActivityBoard").refresh_board()
