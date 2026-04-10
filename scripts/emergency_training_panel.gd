extends Panel

var selected_training_type: String = ""

var training_defs = {
	"electrical_failure_response": {
		"display_name": "Electrical Failure Response",
		"duration": 5.0,
		"cost_per_member": 100
	},
	"crowd_control": {
		"display_name": "Crowd Control",
		"duration": 120.0,
		"cost_per_member": 80
	},
	"medical_first_response": {
		"display_name": "Medical First Response",
		"duration": 150.0,
		"cost_per_member": 90
	},
	"severe_weather_protocols": {
		"display_name": "Severe Weather Protocols",
		"duration": 200.0,
		"cost_per_member": 110
	}
}


@onready var time_label: Label = $MarginContainer/VBoxContainer/TimeRemainingLabel
@onready var money_label: Label = $MarginContainer/VBoxContainer/MoneyLabel
@onready var selected_training_label: Label = $MarginContainer/VBoxContainer/SelectedTrainingLabel
@onready var active_trainings_label: Label = $MarginContainer/VBoxContainer/ActiveTrainingsLabel
@onready var start_button: Button = $MarginContainer/VBoxContainer/StartTrainingButton
@onready var back_button: Button = $MarginContainer/VBoxContainer/BackButton
@onready var member_list: VBoxContainer = $MarginContainer/VBoxContainer/MemberList

func _ready() -> void:
	$MarginContainer/VBoxContainer/TrainingButtons/ElectricalButton.pressed.connect(func(): _select_training("electrical_failure_response"))
	$MarginContainer/VBoxContainer/TrainingButtons/CrowdButton.pressed.connect(func(): _select_training("crowd_control"))
	$MarginContainer/VBoxContainer/TrainingButtons/MedicalButton.pressed.connect(func(): _select_training("medical_first_response"))
	$MarginContainer/VBoxContainer/TrainingButtons/WeatherButton.pressed.connect(func(): _select_training("severe_weather_protocols"))

	start_button.pressed.connect(_on_start_training_pressed)
	back_button.pressed.connect(_on_back_pressed)


	if not GameState.emergency_training_phase_active:
		GameState.start_emergency_training_phase()
	

	_refresh_ui()

func _process(_delta: float) -> void:
	_refresh_ui()

func create_member_checkboxes() -> void:
	print("member_list = ", member_list)
	print("selected_team = ", GameState.selected_team)

	for child in member_list.get_children():
		child.queue_free()

	for member in GameState.selected_team:
		var checkbox := CheckBox.new()
		checkbox.text = member["name"]
		checkbox.set_meta("member_data", member)
		member_list.add_child(checkbox)
		print("eklendi: ", checkbox.text)

	print("child count = ", member_list.get_child_count())

func get_selected_member() -> Dictionary:
	for child in member_list.get_children():
		if child is CheckBox and child.button_pressed:
			return child.get_meta("member_data")
	return {}

func _select_training(training_type: String) -> void:
	selected_training_type = training_type
	selected_training_label.text = "Selected Training: " + training_defs[training_type]["display_name"]

func _on_start_training_pressed() -> void:
	var member := get_selected_member()

	if member.is_empty():
		print("Bir üye seç")
		return

	if selected_training_type == "":
		print("Bir eğitim seç")
		return

	var training = training_defs[selected_training_type]
	var ok = GameState.start_member_training(
		member,
		selected_training_type,
		training["duration"],
		training["cost_per_member"]
	)

	if not ok:
		print("Eğitim başlatılamadı")
		return

	_refresh_ui()

func _refresh_ui() -> void:
	var remaining := GameState.get_emergency_training_remaining_time()
	time_label.text = "Remaining Time: %.1f sec" % remaining
	money_label.text = "Money: $" + str(GameState.money)

	var text := "Active Trainings:\n"
	for training in GameState.active_trainings:
		var left = max(0.0, training["end_time"] - GameState.game_seconds)
		text += training["member_name"] + " - " + training_defs[training["training_type"]]["display_name"] + " (" + str(snapped(left, 0.1)) + "s)\n"

	active_trainings_label.text = text

func _on_back_pressed() -> void:
	GameState.complete_activity("emergency_training")
	hide()
	get_parent().get_node("ActivityBoard").show()
	get_parent().get_node("ActivityBoard").refresh_board()
