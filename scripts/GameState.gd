extends Node


signal time_changed

# ---- Varsayılan başlangıç değerleri ----
const START_MONEY: int = 400000
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
var team_motivation: float = 80.0
var skip_onboarding: bool = false
var player_notes: String = ""
var notepad_popup_shown: bool = false

# ---- Scenarios ----
var active_scenarios: Array = []
var possible_scenarios = [
	"missing_team_members",
	"extra_workload_capacity",
	"mandatory_emergency_training",
	"rival_free_festival",
	"artist_dropout",
	"stage_setup_event",
	"headliner_decoration_veto",
	"cleaning_security_space_event"
]
var triggered_scenarios: Array = []
var vetoed_decoration_theme_id: String = ""

# Work Assignment
var work_assignment_completed: bool = false
var work_assignments: Dictionary = {}  # activity_id -> member_id
var hired_extra_members: Array = []     # 9th+ person hires (scope penalty)
var outsourced_activities: Array = []   # activity IDs outsourced to external
var capacity_boosts: Dictionary = {}    # member_id -> extra capacity added
var work_assignment_scope_penalty: float = 0.0  # score penalty for going out of scope
const HIRE_EXTRA_COST: int = 15000
const OUTSOURCE_COST: int = 10000
const CAPACITY_BOOST_COST: int = 8000
const SCOPE_PENALTY_PER_EXTRA: float = 5.0

var layout_plan: Dictionary = {}
var layout_plans: Array = []
var layout_active_plan_index: int = 0
var final_layout_picky_facilities: Dictionary = {}

var final_layout_plan: Dictionary = {}
var final_layout_completed: bool = false

# Week artışı için tick kontrolü
var last_week_tick: int = -1

#emergency training için değişkenler
var emergency_training_phase_active: bool = false
var emergency_training_phase_start_time: float = 0.0
var emergency_training_phase_duration: float = 240.0 # 4 dakika = 240 saniye
var emergency_training_phase_end_time: float = 0.0


var active_trainings: Array = []

#sponsor

var sponsor_phase_active: bool = false
var sponsor_phase_start_time: float = 0.0
var sponsor_phase_duration: float = 480.0 # 8 dakika
var sponsor_phase_end_time: float = 0.0

var accepted_sponsors: Array = []
var rejected_sponsors: Array = []
var sponsor_attempts_left: int = 3
var sponsor_intelligence_bought: bool = false

#Entertainment Line-up
var available_artists: Array = []
var selected_headliners: Array = []
var selected_supporting_artists: Array = []

var entertainment_lineup_phase_active: bool = false
var entertainment_lineup_completed: bool = false
var entertainment_total_cost: int = 0

var university_debt_limit: int = -300000

# Promotion Strategy
var promotion_phase_completed: bool = false
var promotion_intelligence_bought: bool = false
var promotion_total_actual_reach: float = 0.0
var promotion_total_cost: int = 0

# Ticket Pricing
var ticket_pricing_completed: bool = false
var final_attendance: float = 0.0
var chosen_ticket_price: float = 0.0
var total_revenue: float = 0.0
var event_quality_score: float = 0.0

# Ticket Pricing Strategy
var ticket_consulting_purchased: bool = false
const TICKET_CONSULTING_COST: int = 10000

# Volunteer / Club Recruitment
var volunteer_club_completed: bool = false
var selected_volunteer_clubs: Array = []
var volunteer_club_space_used: int = 0
var volunteer_club_engagement: int = 0
var volunteer_club_diversity_effect: int = 0
var volunteer_club_quality_impact: float = 0.0

# Food Vendor Selection
var food_vendor_completed: bool = false
var selected_food_vendors: Array = []
var total_food_capacity: int = 0
var average_hygiene: float = 0.0
var total_food_cost: int = 0
var participant_satisfaction: float = 0.0

#Stage Setup
var stage_setup_defs: Array = []
var selected_stage_setup: Dictionary = {}
var stage_setup_score: float = 0.0

#Sound System Setup
var sound_system_defs: Array = []
var selected_sound_system: Dictionary = {}
var sound_system_score: float = 0.0

# Transport Coordination
var transport_delivery_defs: Array = []
var transport_schedule: Dictionary = {}

# Decoration Theme
var decoration_theme_defs: Array = []
var selected_decoration_theme: Dictionary = {}
var decoration_theme_score: float = 0.0

# Festival Cleaning & Security
var cleaning_security_completed: bool = false
var selected_cleaning_teams: Array = []
var selected_security_teams: Array = []
var max_site_space: int = 100 # Increased limit for larger teams
var used_site_space: int = 0
var cleaning_security_total_cost: int = 0

# Hız: 1.0 = gerçek zaman, 60.0 = 1 saniyede 1 dakika gibi
@export var time_scale: float = 1.0

var is_running: bool = false

func reset() -> void:
	money = START_MONEY
	week = START_WEEK
	game_seconds = START_TIME_SECONDS
	is_running = false
	player_notes = ""
	notepad_popup_shown = false
	layout_plans = []
	layout_active_plan_index = 0
	layout_plan = {}
	max_site_space = 100
	final_layout_picky_facilities = {}
	
	vetoed_decoration_theme_id = ""
	_initialize_scenarios()
	

	last_week_tick = -1
	
	

	emit_signal("time_changed")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not is_running:
		return
	
	game_seconds += delta * time_scale
	_update_active_trainings()
	
	# Her 4 saniyede bir week++ (sadece 1 kere)
	var tick := int(game_seconds) / 240
	if tick != last_week_tick:
		last_week_tick = tick
		if tick > 0:
			week += 1
	emit_signal("time_changed")

func start_game_timer() -> void:
	is_running = true
	last_week_tick = int(game_seconds) / 4



func _ready() -> void:
	load_activities()
	load_artists()
	load_stage_setups()
	load_sound_systems()
	load_transport_deliveries()
	load_decoration_themes()
	
	_initialize_scenarios()

func _initialize_scenarios() -> void:
	active_scenarios.clear()
	triggered_scenarios.clear()
	
	# Tüm senaryolar her oyunda aktif olacak
	for sc in possible_scenarios:
		active_scenarios.append(sc)
	
#func to print the HUD text
func get_hud_text() -> String:
	var total := int(game_seconds)

	var hours := total / 3600
	var minutes := (total % 3600) / 60
	var seconds := total % 60

	# 02:05:09 gibi
	return "%02d:%02d:%02d" % [hours, minutes, seconds] + "   |   Week: " + str(week) + "   |   Budget: " + str(money) +" TL"
	
	
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

func finalize_work_assignment(assignments: Dictionary, extra_hires: Array, outsourced: Array, boosts: Dictionary, total_extra_cost: int) -> void:
	work_assignments = assignments.duplicate(true)
	hired_extra_members = extra_hires.duplicate(true)
	outsourced_activities = outsourced.duplicate(true)
	capacity_boosts = boosts.duplicate(true)
	money -= total_extra_cost
	# Scope penalty: each extra hired member costs score points
	work_assignment_scope_penalty = extra_hires.size() * SCOPE_PENALTY_PER_EXTRA
	event_quality_score -= work_assignment_scope_penalty
	work_assignment_completed = true
	complete_activity("work_assignment")

func get_member_assigned_count(member_id: String) -> int:
	var count := 0
	for activity_id in work_assignments:
		if work_assignments[activity_id] == member_id:
			count += 1
	for activity_id in outsourced_activities:
		pass  # outsourced don't count toward member capacity
	return count

func get_effective_capacity(member: Dictionary) -> int:
	var base = int(member.get("workload_capacity", 1))
	var boost = capacity_boosts.get(member["id"], 0)
	return base + boost

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
		
	var total_so_far = member.get("total_training_time", 0.0)
	if total_so_far + duration > 240.0:
		return false

	if get_emergency_training_remaining_time() < duration:
		return false

	if money < cost:
		return false

	money -= cost
	member["is_in_training"] = true
	member["total_training_time"] = total_so_far + duration

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
	
func start_sponsor_phase() -> void:
	sponsor_phase_active = true
	sponsor_phase_start_time = game_seconds
	sponsor_phase_end_time = game_seconds + sponsor_phase_duration

	sponsor_attempts_left = 3
	accepted_sponsors.clear()
	rejected_sponsors.clear()
	
func get_sponsor_remaining_time() -> float:
	if not sponsor_phase_active:
		return 0.0
	return max(0.0, sponsor_phase_end_time - game_seconds)
	
func process_sponsor_acceptance(selection: Array, sponsor_defs: Dictionary) -> Dictionary:
	var accepted = []
	var rejected = []

	for id in selection:
		if id in accepted_sponsors:
			continue

		var chance = sponsor_defs[id]["acceptance"]

		if randf() <= chance:
			accepted.append(id)
			accepted_sponsors.append(id)
			money += int(sponsor_defs[id]["price"])
		else:
			rejected.append(id)

	rejected_sponsors = rejected
	sponsor_attempts_left -= 1

	return {
		"accepted": accepted,
		"rejected": rejected
	}
	
	#Entertainment Line-up
	
func load_artists() -> void:
	var file = FileAccess.open("res://data/artists.json", FileAccess.READ)
	
	if file == null:
		print("ERROR: artists.json could not be opened")
		return
	
	var content = file.get_as_text()
	file.close()

	var json = JSON.new()
	var result = json.parse(content)

	if result != OK:
		print("ERROR: Failed to parse artists.json")
		return

	var data = json.data

	if not data.has("artists"):
		print("ERROR: No 'artists' key in JSON")
		return

	available_artists = data["artists"]
	print("Artists loaded: ", available_artists.size())
	
func get_total_lineup_cost() -> int:
	var total := 0
	for artist in selected_headliners:
		total += artist["cost"]
	for artist in selected_supporting_artists:
		total += artist["cost"]
	return total
	
func get_attendance_from_appeal(appeal: String) -> int:
	match appeal:
		"Very High":
			return 1000
		"High":
			return 800
		"Medium-High":
			return 600
		"Medium":
			return 400
		"Niche":
			return 200
		_:
			return 0

func get_total_expected_attendance() -> int:
	var total := 0
	for artist in selected_headliners:
		total += get_attendance_from_appeal(artist["crowd_appeal"])
	for artist in selected_supporting_artists:
		total += get_attendance_from_appeal(artist["crowd_appeal"])
	return total

func get_average_lineup_popularity() -> float:
	var all_artists := selected_headliners + selected_supporting_artists
	if all_artists.is_empty():
		return 0.0
	
	var total := 0
	for artist in all_artists:
		total += artist["popularity"]
	return float(total) / all_artists.size()

func can_finalize_lineup() -> bool:
	return selected_headliners.size() >= 1 and selected_supporting_artists.size() >= 2
	
func can_afford_artist(artist_cost: int) -> bool:
	return money - artist_cost >= -300000

func finalize_promotion_strategy(selected: Array, total_cost: int, total_reach: float) -> void:
	money -= total_cost
	promotion_total_cost = total_cost
	promotion_total_actual_reach = total_reach
	promotion_phase_completed = true
	complete_activity("promotion_strategy")

func finalize_ticket_pricing(attendance: float, price: float, revenue: float, quality_impact: float) -> void:
	final_attendance = attendance
	chosen_ticket_price = price
	total_revenue = revenue
	event_quality_score += quality_impact
	ticket_pricing_completed = true
	complete_activity("ticket_pricing")

func finalize_volunteer_club(selected: Array, space: int, engagement: int, diversity_effect: int, quality_impact: float) -> void:
	selected_volunteer_clubs = selected
	volunteer_club_space_used = space
	volunteer_club_engagement = engagement
	volunteer_club_diversity_effect = diversity_effect
	volunteer_club_quality_impact = quality_impact
	event_quality_score += quality_impact
	volunteer_club_completed = true
	complete_activity("volunteer_club_recruitment")

func finalize_food_vendor_selection(selected: Array, capacity: int, avg_hygiene: float, total_cost: int, satisfaction_impact: float, quality_impact: float) -> void:
	selected_food_vendors = selected
	total_food_capacity = capacity
	average_hygiene = avg_hygiene
	total_food_cost = total_cost
	money -= total_cost
	
	participant_satisfaction += satisfaction_impact
	event_quality_score += quality_impact
	
	food_vendor_completed = true
	complete_activity("food_vendor_selection")

func finalize_final_layout(plan: Dictionary) -> void:
	final_layout_plan = plan.duplicate(true)
	final_layout_completed = true
	complete_activity("final_festival_layout_mapping")
	
func load_stage_setups() -> void:
	var file = FileAccess.open("res://data/stage_setups.json", FileAccess.READ)
	if file == null:
		print("stage_setups.json açılamadı")
		return

	var json_text = file.get_as_text()
	var data = JSON.parse_string(json_text)

	if data == null or not data.has("stage_setups"):
		print("stage_setups.json parse edilemedi")
		return

	stage_setup_defs = data["stage_setups"]
	
func calculate_stage_impact(stage_data: Dictionary) -> float:
	return (
		stage_data["stage_size"] * 0.5 +
		stage_data["lighting_complexity"] * 0.3 +
		stage_data["operation_features"] * 0.2
	)

func choose_stage_setup(stage_data: Dictionary) -> bool:
	var cost: int = stage_data["cost"]

	if money < cost:
		return false

	money -= cost
	selected_stage_setup = stage_data.duplicate(true)
	stage_setup_score = calculate_stage_impact(stage_data)

	return true

func load_sound_systems() -> void:
	var file = FileAccess.open("res://data/sound_systems.json", FileAccess.READ)
	if file == null:
		print("sound_systems.json açılamadı")
		return

	var json_text = file.get_as_text()
	var data = JSON.parse_string(json_text)

	if data == null or not data.has("sound_systems"):
		print("sound_systems.json parse edilemedi")
		return

	sound_system_defs = data["sound_systems"]

func calculate_sound_system_impact(system_data: Dictionary) -> float:
	return (system_data["sound_quality"] * 0.7) / (system_data["technical_skill_level"] * 0.1 + system_data["electricity_consumption"] * 0.1)

func choose_sound_system(system_data: Dictionary) -> bool:
	var cost: int = system_data["cost"]

	if money < cost:
		return false

	money -= cost
	selected_sound_system = system_data.duplicate(true)
	sound_system_score = calculate_sound_system_impact(system_data)

	return true

func load_transport_deliveries() -> void:
	var file = FileAccess.open("res://data/transport_deliveries.json", FileAccess.READ)
	if file == null: return
	var text = file.get_as_text()
	var data = JSON.parse_string(text)
	if data and data.has("deliveries"):
		transport_delivery_defs = data["deliveries"]

func save_transport_schedule(schedule: Dictionary) -> void:
	transport_schedule = schedule.duplicate(true)
	complete_activity("transport_coordination")

func load_decoration_themes() -> void:
	var file = FileAccess.open("res://data/decoration_themes.json", FileAccess.READ)
	if file == null: return
	var text = file.get_as_text()
	var data = JSON.parse_string(text)
	if data and data.has("decoration_themes"):
		decoration_theme_defs = data["decoration_themes"]

func calculate_decoration_theme_impact(theme: Dictionary) -> float:
	return (theme["satisfaction_impact"] * 0.6) / ((theme["complexity"] + theme["space_impact"]) * 0.4)

func choose_decoration_theme(theme: Dictionary) -> bool:
	var cost: int = theme["cost"]

	money -= cost
	selected_decoration_theme = theme.duplicate(true)
	decoration_theme_score = calculate_decoration_theme_impact(theme)

	return true

# ---- UI Scaling Helpers ----
# These are optional helpers for DPI-aware scaling.
# The canvas_items stretch mode in project.godot handles resolution scaling automatically.
# Use these for additional fine-tuning if needed.

## Returns a DPI-aware scale factor (1.0 = standard 96 DPI)
static func ui_scale() -> float:
	var screen_dpi = DisplayServer.screen_get_dpi()
	return clamp(screen_dpi / 96.0, 0.75, 2.0)

## Returns a font size scaled by UI scale factor
static func scaled_font(base_size: int) -> int:
	return int(base_size * ui_scale())

## Returns a Vector2 scaled by UI scale factor
static func scaled_size(base: Vector2) -> Vector2:
	var s = ui_scale()
	return Vector2(base.x * s, base.y * s)
