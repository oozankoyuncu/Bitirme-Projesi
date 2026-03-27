extends Node


signal time_changed

# ---- Varsayılan başlangıç değerleri ----
const START_MONEY: int = 1000
const START_WEEK: int = 1
const START_TIME_SECONDS: float = 0.0

# ---- Oyun state ----
var money: int = START_MONEY
var week: int = START_WEEK
var game_seconds: float = START_TIME_SECONDS

var activities = []
var completed_activities: Array[String] = []
var selected_team: Array = []
var all_team_members: Array = []

var layout_plan: Dictionary = {}

# Week artışı için tick kontrolü
var last_week_tick: int = -1

#emergency training için değişkenler
var emergency_training_phase_active: bool = false
var emergency_training_phase_start_time: float = 0.0
var emergency_training_phase_duration: float = 240.0 # 4 dakika = 240 saniye
var emergency_training_phase_end_time: float = 0.0

var active_trainings: Array = []

# Hız: 1.0 = gerçek zaman, 60.0 = 1 saniyede 1 dakika gibi
@export var time_scale: float = 1.0

var is_running: bool = true

func reset() -> void:
	money = START_MONEY
	week = START_WEEK
	game_seconds = START_TIME_SECONDS
	is_running = true

	last_week_tick = -1
	
	

	emit_signal("time_changed")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not is_running:
		return
	
	game_seconds += delta * time_scale
	_update_active_trainings()
	
	# Her 4 saniyede bir week++ (sadece 1 kere)
	var tick := int(game_seconds) / 4
	if tick != last_week_tick:
		last_week_tick = tick
		if tick > 0:
			week += 1
	emit_signal("time_changed")



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	GameState.load_activities()
	
#func to print the HUD text
func get_hud_text() -> String:
	var total := int(game_seconds)

	var hours := total / 3600
	var minutes := (total % 3600) / 60
	var seconds := total % 60

	# 02:05:09 gibi
	return "%02d:%02d:%02d" % [hours, minutes, seconds] + " Week: " + str(week) + "  Budget: " + str(money) +" TL"
	
	
	# Her 4 saniyede week 1 artacak (deneme)

	
	
	


func load_activities():
	var file = FileAccess.open("res://data/activities.json", FileAccess.READ)
	var json_text = file.get_as_text()

	var data = JSON.parse_string(json_text)

	activities = data["activities"]
	
func load_team_members():
	var file = FileAccess.open("res://data/team_members.json", FileAccess.READ)
	var json_text = file.get_as_text()
	var data = JSON.parse_string(json_text)
	all_team_members = data["members"]

func complete_activity(activity_id: String):
	if not completed_activities.has(activity_id):
		completed_activities.append(activity_id)
		
		
		
func start_emergency_training_phase() -> void:
	emergency_training_phase_active = true
	emergency_training_phase_start_time = game_seconds
	emergency_training_phase_end_time = game_seconds + emergency_training_phase_duration
	
func get_emergency_training_remaining_time() -> float:
	if not emergency_training_phase_active:
		return 0.0
	return max(0.0, emergency_training_phase_end_time - game_seconds)
	
func start_member_training(member: Dictionary, training_type: String, duration: float, cost: int) -> bool:
	if not emergency_training_phase_active:
		return false

	if member.get("is_in_training", false):
		return false

	if get_emergency_training_remaining_time() < duration:
		return false

	if money < cost:
		return false

	money -= cost
	member["is_in_training"] = true

	active_trainings.append({
		"member_id": member["id"],
		"member_name": member["name"],
		"training_type": training_type,
		"end_time": game_seconds + duration
	})

	return true
	
func _update_active_trainings() -> void:
	var finished = []

	for training in active_trainings:
		if game_seconds >= training["end_time"]:
			finished.append(training)

	for training in finished:
		_complete_training(training)
		active_trainings.erase(training)
		
func _complete_training(training: Dictionary) -> void:
	for member in selected_team:
		if member["id"] == training["member_id"]:
			member["is_in_training"] = false
			member[training["training_type"]] = 1
			break
	
