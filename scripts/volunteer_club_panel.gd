extends Control

var club_options = {
	"art_club": {
		"display_name": "University Art Club",
		"activity_type": "Artistic",
		"engagement_level": 10,
		"space_requirement": 50,
		"operational_needs": "Covered Tent"
	},
	"esports_club": {
		"display_name": "E-Sports Society",
		"activity_type": "Interactive",
		"engagement_level": 20,
		"space_requirement": 60,
		"operational_needs": "Electricity, Internet"
	},
	"dance_troupe": {
		"display_name": "Modern Dance Troupe",
		"activity_type": "Performance",
		"engagement_level": 15,
		"space_requirement": 80,
		"operational_needs": "Open Floor, Audio"
	},
	"tech_club": {
		"display_name": "Tech Innovators",
		"activity_type": "Informational",
		"engagement_level": 5,
		"space_requirement": 40,
		"operational_needs": "Electricity"
	},
	"sports_team": {
		"display_name": "Athletics Mini-Games",
		"activity_type": "Competitive",
		"engagement_level": 15,
		"space_requirement": 100,
		"operational_needs": "Open Space"
	}
}

# PLACEHOLDER: Maximum space allowed for volunteer/club booths.
# Update this to match real area capacities when fully designed.
const MAX_SPACE: int = 200

@onready var club_list: VBoxContainer = $MarginContainer/VBoxContainer/ContentPanel/MarginContainer/ClubList
@onready var capacity_label: Label = $MarginContainer/VBoxContainer/HeaderPanel/VBoxContainer/CapacityLabel
@onready var summary_label: Label = $MarginContainer/VBoxContainer/SummaryPanel/VBoxContainer/SummaryLabel
@onready var confirm_button: Button = $MarginContainer/VBoxContainer/ButtonRow/ConfirmButton

var option_checkboxes: Array = []

func _ready() -> void:
	confirm_button.pressed.connect(_on_confirm_pressed)
	create_options()
	refresh_ui()

func create_options() -> void:
	for c in club_list.get_children():
		c.queue_free()
	option_checkboxes.clear()

	for id in club_options.keys():
		var c_data = club_options[id]
		
		var card = PanelContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		var margin = MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 15)
		margin.add_theme_constant_override("margin_top", 10)
		margin.add_theme_constant_override("margin_right", 15)
		margin.add_theme_constant_override("margin_bottom", 10)
		card.add_child(margin)
		
		var hbox = HBoxContainer.new()
		margin.add_child(hbox)
		
		var cb = CheckBox.new()
		cb.text = "  " + c_data["display_name"]
		cb.set_meta("id", id)
		cb.toggled.connect(_on_option_toggled)
		
		if GameState.volunteer_club_completed:
			cb.disabled = true
			if GameState.selected_volunteer_clubs.has(id):
				cb.button_pressed = true
		
		option_checkboxes.append(cb)
		hbox.add_child(cb)
		
		var spacer = Control.new()
		spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(spacer)
		
		var details_label = Label.new()
		details_label.text = "Type: " + c_data["activity_type"] + " | Space: " + str(c_data["space_requirement"]) + " sqm | Engage: +" + str(c_data["engagement_level"]) + " | Needs: " + c_data["operational_needs"]
		details_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		hbox.add_child(details_label)
		
		club_list.add_child(card)

func _on_option_toggled(_toggled_on: bool) -> void:
	refresh_ui()

func get_totals() -> Dictionary:
	var selected_ids = []
	var total_space = 0
	var total_engagement = 0
	var types = []
	
	for cb in option_checkboxes:
		if cb.button_pressed:
			var id = cb.get_meta("id")
			selected_ids.append(id)
			var c_data = club_options[id]
			total_space += c_data["space_requirement"]
			total_engagement += c_data["engagement_level"]
			
			if not types.has(c_data["activity_type"]):
				types.append(c_data["activity_type"])
				
	var diversity_effect = types.size()
	
	# Base impact from engagement, scaled down
	var quality_impact = (total_engagement / 10.0)
	
	# Bonus impact from variety
	quality_impact += (diversity_effect * 0.5)
	
	var space_penalty = 0.0
	
	if total_space > MAX_SPACE:
		space_penalty = -2.0 # Fixed penalty if exceeding limits
		quality_impact += space_penalty
		
	return {
		"selected_ids": selected_ids,
		"space": total_space,
		"engagement": total_engagement,
		"diversity_effect": diversity_effect,
		"quality_impact": quality_impact,
		"space_exceeded": total_space > MAX_SPACE
	}

func refresh_ui() -> void:
	capacity_label.text = "Total Space Available: " + str(MAX_SPACE) + " sqm"
	var data = get_totals()
	
	if GameState.volunteer_club_completed:
		confirm_button.text = "Back to Board"
		confirm_button.disabled = false
		summary_label.text = "Selection Fixed! Selected: " + str(data["selected_ids"].size()) + " | Used Space: " + str(data["space"]) + "/" + str(MAX_SPACE) + " | Engagement: +" + str(data["engagement"])
	else:
		confirm_button.text = "Confirm Selection"
		
		var warning = ""
		if data["space_exceeded"]:
			warning = "[WARNING: OVER CAPACITY! Penalty applied] "
			
		summary_label.text = warning + "Selected: " + str(data["selected_ids"].size()) + " | Space: " + str(data["space"]) + " / " + str(MAX_SPACE) + " | Total Engagement: " + str(data["engagement"]) + " | Types: " + str(data["diversity_effect"])
		
		# Allow submitting even if over capacity to trigger the penalty, as requested
		confirm_button.disabled = false 

func _on_confirm_pressed() -> void:
	if GameState.volunteer_club_completed:
		go_back()
		return
		
	var data = get_totals()
	GameState.finalize_volunteer_club(data["selected_ids"], data["space"], data["engagement"], data["diversity_effect"], data["quality_impact"])
	go_back()

func go_back() -> void:
	hide()
	get_parent().get_node("ActivityBoard").show()
	get_parent().get_node("ActivityBoard").refresh_board()
