extends Control

# ---------------- SPONSORS ----------------
var sponsor_defs = {
	"techcorp": {
		"display_name": "TechCorp",
		"price": 5000,
		"contribution": 5,
		"audience": 4,
		"logo": 3,
		"area": 2,
		"acceptance": 0.8,
		"conflicts": ["soundmax"]
	},
	"soundmax": {
		"display_name": "SoundMax",
		"price": 4500,
		"contribution": 4,
		"audience": 5,
		"logo": 4,
		"area": 3,
		"acceptance": 0.6,
		"conflicts": ["techcorp"]
	},
	"greenbite": {
		"display_name": "GreenBite",
		"price": 2500,
		"contribution": 3,
		"audience": 5,
		"logo": 1,
		"area": 1,
		"acceptance": 0.9,
		"conflicts": []
	}
}

# ---------------- UI ----------------
@onready var sponsor_list = $MarginContainer/VBoxContainer/SponsorList
@onready var result_label = $MarginContainer/VBoxContainer/ResultLabel
@onready var money_label = $MarginContainer/VBoxContainer/MoneyLabel
@onready var check_button = $MarginContainer/VBoxContainer/CheckButton
@onready var back_button = $MarginContainer/VBoxContainer/BackButton

# ---------------- READY ----------------
func _ready():
	create_sponsors()
	check_button.pressed.connect(_on_check_pressed)
	back_button.pressed.connect(_on_back_pressed)
	refresh_ui()

# ---------------- CREATE UI ----------------
func create_sponsors():
	for c in sponsor_list.get_children():
		c.queue_free()

	for id in sponsor_defs.keys():
		var cb = CheckBox.new()

		var score = get_score(id)

		cb.text = sponsor_defs[id]["display_name"] + \
		" | $" + str(sponsor_defs[id]["price"]) + \
		" | Score: " + str(snapped(score, 0.1))

		cb.set_meta("id", id)
		cb.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		# LOCK accepted sponsors
		if id in GameState.accepted_sponsors:
			cb.button_pressed = true
			cb.disabled = true

		sponsor_list.add_child(cb)

# ---------------- GET SELECTED ----------------
func get_selected():
	var arr = []
	for c in sponsor_list.get_children():
		if c is CheckBox and c.button_pressed:
			arr.append(c.get_meta("id"))
	return arr

# ---------------- SCORE ----------------
func get_score(id):
	var s = sponsor_defs[id]
	return (0.5 * s["contribution"]) + (0.4 * s["audience"]) - (0.1 * (s["logo"] + s["area"]))

func get_average_score(selected):
	if selected.is_empty():
		return 0.0

	var total = 0.0
	for id in selected:
		total += get_score(id)

	return total / selected.size()

# ---------------- CONFLICT ----------------
func has_conflict(selected):
	for i in range(selected.size()):
		for j in range(i + 1, selected.size()):
			if selected[j] in sponsor_defs[selected[i]]["conflicts"]:
				return true
	return false

# ---------------- CHECK BUTTON ----------------
func _on_check_pressed():

	if GameState.sponsor_attempts_left <= 0:
		result_label.text = "No attempts left!"
		return

	var selected = get_selected()

	if selected.is_empty():
		result_label.text = "Select at least one sponsor!"
		return

	# conflict check
	if has_conflict(selected):
		result_label.text = "Conflict detected!"
		return

	# score check
	var avg = get_average_score(selected)
	if avg < 2:
		result_label.text = "Average score must be > 2 (Now: " + str(snapped(avg,0.1)) + ")"
		return

	var accepted = []
	var rejected = []

	for id in selected:

		if id in GameState.accepted_sponsors:
			continue

		if randf() <= sponsor_defs[id]["acceptance"]:
			accepted.append(id)
			GameState.accepted_sponsors.append(id)
			GameState.money += sponsor_defs[id]["price"]
		else:
			rejected.append(id)

	GameState.sponsor_attempts_left -= 1

	result_label.text = "Accepted: " + str(accepted) + \
	"\nRejected: " + str(rejected) + \
	"\nAttempts left: " + str(GameState.sponsor_attempts_left)

	create_sponsors()
	refresh_ui()

# ---------------- UI REFRESH ----------------
func refresh_ui():
	money_label.text = "Money: $" + str(GameState.money)

# ---------------- BACK ----------------
func _on_back_pressed():
	hide()
	get_parent().get_node("ActivityBoard").show()
	get_parent().get_node("ActivityBoard").refresh_board()
