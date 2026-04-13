extends Panel

@onready var money_label: Label = $MarginContainer/VBoxContainer/MoneyLabel
@onready var requirements_label: Label = $MarginContainer/VBoxContainer/RequirementsLabel

@onready var available_artists_list: VBoxContainer = $MarginContainer/VBoxContainer/HBoxContainer/AvailableArtistsPanel/VBoxContainer/AvailableScroll/AvailableArtistsList
@onready var headliner_list: VBoxContainer = $MarginContainer/VBoxContainer/HBoxContainer/SelectedLineupPanel/VBoxContainer/HeadlinerScroll/HeadlinerList
@onready var supporting_list: VBoxContainer = $MarginContainer/VBoxContainer/HBoxContainer/SelectedLineupPanel/VBoxContainer/SupportingScroll/SupportingList

@onready var total_cost_label: Label = $MarginContainer/VBoxContainer/SummaryPanel/VBoxContainer/TotalCostLabel
@onready var total_popularity_label: Label = $MarginContainer/VBoxContainer/SummaryPanel/VBoxContainer/TotalPopularityLabel
@onready var total_attendance_label: Label = $MarginContainer/VBoxContainer/SummaryPanel/VBoxContainer/TotalAttendanceLabel
@onready var remaining_budget_label: Label = $MarginContainer/VBoxContainer/SummaryPanel/VBoxContainer/RemainingBudgetLabel

@onready var result_label: Label = $MarginContainer/VBoxContainer/ResultLabel
@onready var confirm_button: Button = $MarginContainer/VBoxContainer/ButtonRow/ConfirmButton
@onready var back_button: Button = $MarginContainer/VBoxContainer/ButtonRow/BackButton


func _ready() -> void:
	confirm_button.pressed.connect(_on_confirm_pressed)
	back_button.pressed.connect(_on_back_pressed)

	create_available_artist_list()
	refresh_selected_lists()
	refresh_summary()


func create_available_artist_list() -> void:
	for child in available_artists_list.get_children():
		child.queue_free()

	if GameState.available_artists.is_empty():
		result_label.text = "No artists loaded."
		return

	for artist in GameState.available_artists:
		var row := HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		row.custom_minimum_size = Vector2(0, 120)

		var label := Label.new()
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.size_flags_vertical = Control.SIZE_EXPAND_FILL
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

		var name_text: String = str(artist["name"])
		var role_text: String = str(artist["role"])
		var cost_text: String = str(artist["cost"])
		var popularity_text: String = str(artist["popularity"])
		var appeal_text: String = str(artist["crowd_appeal"])

		label.text = name_text + \
			"\nRole: " + role_text + \
			"\nCost: " + cost_text + \
			"\nPopularity: " + popularity_text + \
			"\nAppeal: " + appeal_text

		var add_button := Button.new()
		add_button.text = "Add"
		add_button.custom_minimum_size = Vector2(90, 40)
		add_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		add_button.set_meta("artist_data", artist)
		add_button.pressed.connect(func(): _on_add_artist_pressed(add_button.get_meta("artist_data")))

		row.add_child(label)
		row.add_child(add_button)
		available_artists_list.add_child(row)


func refresh_selected_lists() -> void:
	for child in headliner_list.get_children():
		child.queue_free()

	for child in supporting_list.get_children():
		child.queue_free()

	# Headliner
	if GameState.selected_headliners.is_empty():
		var empty_headliner := Label.new()
		empty_headliner.text = "No headliner selected."
		headliner_list.add_child(empty_headliner)
	else:
		for artist in GameState.selected_headliners:
			headliner_list.add_child(_create_selected_artist_row(artist))

	# Supporting
	if GameState.selected_supporting_artists.is_empty():
		var empty_supporting := Label.new()
		empty_supporting.text = "No supporting artists selected."
		supporting_list.add_child(empty_supporting)
	else:
		for artist in GameState.selected_supporting_artists:
			supporting_list.add_child(_create_selected_artist_row(artist))


func _create_selected_artist_row(artist: Dictionary) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.custom_minimum_size = Vector2(0, 110)

	var label := Label.new()
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	label.text = str(artist["name"]) + \
		"\nRole: " + str(artist["role"]) + \
		"\nCost: " + str(artist["cost"]) + \
		"\nPopularity: " + str(artist["popularity"]) + \
		"\nAppeal: " + str(artist["crowd_appeal"])

	var remove_button := Button.new()
	remove_button.text = "Remove"
	remove_button.custom_minimum_size = Vector2(90, 40)
	remove_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	remove_button.set_meta("artist_data", artist)
	remove_button.pressed.connect(func(): _on_remove_artist_pressed(remove_button.get_meta("artist_data")))

	row.add_child(label)
	row.add_child(remove_button)

	return row


func _on_add_artist_pressed(artist: Dictionary) -> void:
	if _artist_already_selected(artist):
		result_label.text = artist["name"] + " is already selected."
		return

	if not _can_add_artist_without_exceeding_debt_limit(artist):
		result_label.text = "You cannot go below -300000 TL."
		return

	var role := str(artist["role"])

	if role == "headliner":
		if GameState.selected_headliners.size() >= 1:
			result_label.text = "You can select only 1 main headliner."
			return
		GameState.selected_headliners.append(artist)

	elif role == "supporting":
		GameState.selected_supporting_artists.append(artist)

	else:
		result_label.text = "Unknown artist role: " + str(role)
		return

	result_label.text = artist["name"] + " added to lineup."
	refresh_selected_lists()
	refresh_summary()


func _on_remove_artist_pressed(artist: Dictionary) -> void:
	var role := str(artist["role"])

	if role == "headliner":
		for selected in GameState.selected_headliners:
			if selected["id"] == artist["id"]:
				GameState.selected_headliners.erase(selected)
				break

	elif role == "supporting":
		for selected in GameState.selected_supporting_artists:
			if selected["id"] == artist["id"]:
				GameState.selected_supporting_artists.erase(selected)
				break

	result_label.text = artist["name"] + " removed from lineup."
	refresh_selected_lists()
	refresh_summary()


func _artist_already_selected(artist: Dictionary) -> bool:
	for selected in GameState.selected_headliners:
		if selected["id"] == artist["id"]:
			return true

	for selected in GameState.selected_supporting_artists:
		if selected["id"] == artist["id"]:
			return true

	return false


func _can_add_artist_without_exceeding_debt_limit(artist: Dictionary) -> bool:
	var total_cost := GameState.get_total_lineup_cost()
	var predicted_budget := GameState.money - total_cost - int(artist["cost"])
	return predicted_budget >= -300000


func refresh_summary() -> void:
	var total_cost := GameState.get_total_lineup_cost()
	var avg_popularity := GameState.get_average_lineup_popularity()
	var total_attendance := GameState.get_total_expected_attendance()
	var remaining_budget := GameState.money - total_cost

	money_label.text = "Current Budget: " + str(GameState.money) + " TL"

	requirements_label.text = \
		"Required: 1 Headliner, at least 2 Supporting Artists" + \
		"\nSelected: " + str(GameState.selected_headliners.size()) + " Headliner, " + str(GameState.selected_supporting_artists.size()) + " Supporting"

	total_cost_label.text = "Total Cost: " + str(total_cost) + " TL"
	total_popularity_label.text = "Average Popularity: %.1f" % avg_popularity
	total_attendance_label.text = "Expected Attendance: " + str(total_attendance)
	remaining_budget_label.text = "Remaining Budget After Booking: " + str(remaining_budget) + " TL"


func _on_confirm_pressed() -> void:
	if GameState.selected_headliners.size() < 1:
		result_label.text = "You must select 1 main headliner."
		return

	if GameState.selected_supporting_artists.size() < 2:
		result_label.text = "You must select at least 2 supporting artists."
		return

	var total_cost := GameState.get_total_lineup_cost()
	var predicted_budget := GameState.money - total_cost

	if predicted_budget < -300000:
		result_label.text = "Debt limit exceeded. Minimum allowed budget is -300000 TL."
		return

	GameState.money -= total_cost
	GameState.complete_activity("entertainment_lineup")

	result_label.text = "Lineup confirmed successfully."
	hide()
	get_parent().get_node("ActivityBoard").show()
	get_parent().get_node("ActivityBoard").refresh_board()


func _on_back_pressed() -> void:
	hide()
	get_parent().get_node("ActivityBoard").show()
	get_parent().get_node("ActivityBoard").refresh_board()
