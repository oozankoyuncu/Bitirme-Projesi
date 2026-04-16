extends Control

@onready var activity_list: VBoxContainer = $MarginContainer/VBoxContainer/ActivityList


func _ready() -> void:
	refresh_board()

func refresh_board() -> void:
	# Önce eski elemanları temizle
	for child in activity_list.get_children():
		child.queue_free()

	# Tüm aktiviteleri sırayla ekle
	for activity in GameState.activities:
		var button = Button.new()

		var status = get_activity_status(activity)
		button.text = activity["name"] + " | Cost: " + str(activity["cost"]) + " | Duration: " + str(activity["duration"]) + " | " + status

		if status != "Available":
			button.disabled = true

		button.pressed.connect(func(): start_activity(activity))
		activity_list.add_child(button)
		
		
		
		
		
func get_activity_status(activity: Dictionary) -> String:
	var activity_id = activity["id"]

	if activity_id == "sponsor_management":
		if GameState.week < 2:
			return "Locked"
		#if GameState.week > 3:
			#return "Expired"

	if GameState.completed_activities.has(activity_id):
		return "Completed"

	if activity_id == "promotion_strategy":
		if GameState.week < 4:
			return "Locked"
			
	if activity_id == "ticket_pricing":
		if GameState.week < 4:
			return "Locked"
			
	if activity_id == "sound_system_choices":
		if GameState.week < 7:
			return "Locked"

	if activity_id == "transport_coordination":
		if GameState.week < 7:
			return "Locked"

	if activity_id == "decoration_theme_decision":
		if GameState.week < 8:
			return "Locked"

	if not dependencies_completed(activity):
		return "Locked"

	return "Available"

func dependencies_completed(activity: Dictionary) -> bool:
	for dep in activity["dependencies"]:
		if not GameState.completed_activities.has(dep):
			return false
	return true
	
	
func start_activity(activity: Dictionary) -> void:
	var activity_id = activity["id"]

	if activity_id == "team_assignment":
		get_parent().get_node("TeamAssignmentPanel").show()
		hide()
		return
	if activity_id == "initial_festival_layout_mapping":
		get_parent().get_node("InitialFacilityLayoutPanel").show()
		hide()
		return
		
	if activity_id == "emergency_training":
		var panel = get_parent().get_node("EmergencyTrainingPanel")
		panel.show()
		panel.create_member_checkboxes()
		hide()
		return
	
	if activity_id == "sponsor_management":
		var panel = get_parent().get_node("SponsorManagementPanel")
		panel.show()
		hide()
		return
		
	if activity_id == "entertainment_lineup":
		var panel = get_parent().get_node("EntertainmentLineupPanel")
		panel.show()
		hide()
		return
		
	if activity_id == "promotion_strategy":
		var panel = get_parent().get_node("PromotionStrategyPanel")
		panel.show()
		hide()
		return
		
	if activity_id == "ticket_pricing":
		var panel = get_parent().get_node("TicketPricingPanel")
		panel.show()
		hide()
		return

	if activity_id == "volunteer_club_recruitment":
		var panel = get_parent().get_node("VolunteerClubPanel")
		panel.show()
		hide()
		return

	if activity_id == "food_vendor_selection":
		var panel = get_parent().get_node("FoodVendorSelectionPanel")
		panel.show()
		hide()
		return
		
	if activity_id == "stage_setup_choices":
		var panel = get_parent().get_node("StageSetupChoicesPanel")
		panel.show()
		hide()
		return
		
	if activity_id == "sound_system_choices":
		var panel = get_parent().get_node("SoundSystemChoicesPanel")
		panel.show()
		hide()
		return
		
	if activity_id == "transport_coordination":
		var panel = get_parent().get_node("TransportCoordinationPanel")
		panel.show()
		hide()
		return

	if activity_id == "decoration_theme_decision":
		var panel = get_parent().get_node("DecorationThemePanel")
		panel.show()
		hide()
		return

	print("Başlatıldı: ", activity["name"])
	GameState.completed_activities.append(activity_id)
	refresh_board()
