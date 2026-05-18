extends Panel

@onready var money_label: Label = $MarginContainer/VBoxContainer/MoneyLabel
@onready var requirements_label: Label = $MarginContainer/VBoxContainer/RequirementsLabel

@onready var available_artists_list: VBoxContainer = $MarginContainer/VBoxContainer/HBoxContainer/AvailableArtistsPanel/VBoxContainer/AvailableScroll/AvailableArtistsList
@onready var headliner_list: VBoxContainer = $MarginContainer/VBoxContainer/HBoxContainer/SelectedLineupPanel/VBoxContainer/HeadlinerScroll/HeadlinerList
@onready var supporting_list: VBoxContainer = $MarginContainer/VBoxContainer/HBoxContainer/SelectedLineupPanel/VBoxContainer/SupportingScroll/SupportingList

@onready var total_cost_label: Label = $MarginContainer/VBoxContainer/SummaryPanel/MarginContainer/VBoxContainer/TotalCostLabel
@onready var total_popularity_label: Label = $MarginContainer/VBoxContainer/SummaryPanel/MarginContainer/VBoxContainer/TotalPopularityLabel
@onready var total_attendance_label: Label = $MarginContainer/VBoxContainer/SummaryPanel/MarginContainer/VBoxContainer/TotalAttendanceLabel
@onready var remaining_budget_label: Label = $MarginContainer/VBoxContainer/SummaryPanel/MarginContainer/VBoxContainer/RemainingBudgetLabel

@onready var result_label: Label = $MarginContainer/VBoxContainer/ResultLabel
@onready var confirm_button: Button = $MarginContainer/VBoxContainer/ButtonRow/ConfirmButton
@onready var back_button: Button = $MarginContainer/VBoxContainer/ButtonRow/BackButton


@onready var available_panel = $MarginContainer/VBoxContainer/HBoxContainer/AvailableArtistsPanel
@onready var selected_panel = $MarginContainer/VBoxContainer/HBoxContainer/SelectedLineupPanel
@onready var summary_panel = $MarginContainer/VBoxContainer/SummaryPanel

var guide_panel: PanelContainer
var guide_label: Label
var info_button: Button

func _ready() -> void:
	confirm_button.pressed.connect(_on_confirm_pressed)
	back_button.pressed.connect(_on_back_pressed)

	_setup_ui_styles()
	_setup_guide_ui()
	_setup_guide_text()

	create_available_artist_list()
	refresh_selected_lists()
	refresh_summary()

func _setup_ui_styles() -> void:
	var main_style = StyleBoxFlat.new()
	main_style.bg_color = Color(0.05, 0.07, 0.1, 0.95)
	main_style.border_width_left = 4
	main_style.border_color = Color(0.1, 0.4, 0.7)
	self.add_theme_stylebox_override("panel", main_style)

	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.1, 0.12, 0.15, 0.8)
	panel_style.corner_radius_top_left = 10
	panel_style.corner_radius_top_right = 10
	panel_style.corner_radius_bottom_right = 10
	panel_style.corner_radius_bottom_left = 10
	panel_style.border_width_left = 1
	panel_style.border_width_top = 1
	panel_style.border_width_right = 1
	panel_style.border_width_bottom = 1
	panel_style.border_color = Color(0.2, 0.3, 0.4)

	if available_panel: available_panel.add_theme_stylebox_override("panel", panel_style)
	if selected_panel: selected_panel.add_theme_stylebox_override("panel", panel_style)
	if summary_panel: summary_panel.add_theme_stylebox_override("panel", panel_style)

	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = Color(0.2, 0.5, 0.8)
	btn_style.corner_radius_top_left = 5
	btn_style.corner_radius_top_right = 5
	btn_style.corner_radius_bottom_right = 5
	btn_style.corner_radius_bottom_left = 5
	
	var btn_hover = btn_style.duplicate()
	btn_hover.bg_color = Color(0.3, 0.6, 0.9)

	confirm_button.add_theme_stylebox_override("normal", btn_style)
	confirm_button.add_theme_stylebox_override("hover", btn_hover)
	back_button.add_theme_stylebox_override("normal", btn_style)
	back_button.add_theme_stylebox_override("hover", btn_hover)

func _setup_guide_ui() -> void:
	var header = HBoxContainer.new()
	var vbox = $MarginContainer/VBoxContainer
	var title = $MarginContainer/VBoxContainer/TitleLabel
	
	vbox.remove_child(title)
	vbox.add_child(header)
	vbox.move_child(header, 0)
	
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	
	info_button = Button.new()
	info_button.text = "?"
	info_button.custom_minimum_size = Vector2(40, 40)
	header.add_child(info_button)
	
	guide_panel = PanelContainer.new()
	guide_panel.visible = false
	guide_panel.set_anchors_preset(Control.PRESET_CENTER)
	guide_panel.custom_minimum_size = Vector2(800, 600)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.10, 0.14, 1.0)
	style.set_corner_radius_all(12)
	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 3
	style.border_color = Color(0.15, 0.55, 0.9, 0.8)
	style.shadow_color = Color(0, 0, 0, 0.6)
	style.shadow_size = 20
	guide_panel.add_theme_stylebox_override("panel", style)
	
	var g_margin = MarginContainer.new()
	g_margin.add_theme_constant_override("margin_left", 20)
	g_margin.add_theme_constant_override("margin_right", 20)
	g_margin.add_theme_constant_override("margin_top", 20)
	g_margin.add_theme_constant_override("margin_bottom", 20)
	guide_panel.add_child(g_margin)
	
	var g_vbox = VBoxContainer.new()
	g_margin.add_child(g_vbox)
	
	var g_header = HBoxContainer.new()
	g_vbox.add_child(g_header)
	
	var g_title = Label.new()
	g_title.text = "ACTIVITY GUIDE"
	g_title.add_theme_font_size_override("font_size", 24)
	g_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	g_header.add_child(g_title)
	
	var close_btn = Button.new()
	close_btn.text = "X"
	close_btn.custom_minimum_size = Vector2(40, 40)
	g_header.add_child(close_btn)
	
	var g_sep = HSeparator.new()
	g_vbox.add_child(g_sep)
	
	var g_scroll = ScrollContainer.new()
	g_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	g_vbox.add_child(g_scroll)
	
	guide_label = Label.new()
	guide_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	guide_label.custom_minimum_size = Vector2(740, 0)
	g_scroll.add_child(guide_label)
	
	add_child(guide_panel)
	
	# Center the guide panel on the screen
	guide_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	
	info_button.pressed.connect(func():
		guide_panel.show()
		guide_panel.position = (size - guide_panel.size) / 2
	)
	close_btn.pressed.connect(func(): guide_panel.hide())

func _setup_guide_text() -> void:
	guide_label.text = "ACTIVITY GUIDE: ENTERTAINMENT LINE-UP\n\n" + \
		"What You Need to Pay Attention To:\n" + \
		"• Budget Constraints: You must not exceed the debt limit (-300,000 TL). However, remember that you will need funds for future stages. Spending your entire budget here will heavily restrict your options later.\n" + \
		"• Minimum Requirements: You must select exactly 1 Main Headliner and at least 2 Supporting Artists.\n\n" + \
		"How You Gather Points & Impact Success:\n" + \
		"• Participant Satisfaction: Determined by the average Popularity of your lineup. Choosing highly popular artists directly boosts your final Event Quality and Satisfaction scores.\n" + \
		"• Festival Attendance: Determined by the Expected Crowd Appeal of your artists. (e.g., 'Very High' = 1000 people, 'Medium' = 400 people). Higher attendance means a more successful festival.\n" + \
		"• Strategic Balance: Do not just pick the most expensive artists. Your goal is to maximize Popularity (for satisfaction) and Crowd Appeal (for attendance) while maintaining a healthy budget for the rest of the game."


func create_available_artist_list() -> void:
	for child in available_artists_list.get_children():
		child.queue_free()

	if GameState.available_artists.is_empty():
		result_label.text = "No artists loaded."
		return

	for artist in GameState.available_artists:
		var card := PanelContainer.new()
		var card_style = StyleBoxFlat.new()
		card_style.bg_color = Color(0.15, 0.15, 0.15, 0.6)
		card_style.border_width_left = 1
		card_style.border_width_top = 1
		card_style.border_width_right = 1
		card_style.border_width_bottom = 1
		card_style.border_color = Color(0.3, 0.3, 0.3)
		card_style.corner_radius_top_left = 8
		card_style.corner_radius_top_right = 8
		card_style.corner_radius_bottom_right = 8
		card_style.corner_radius_bottom_left = 8
		card.add_theme_stylebox_override("panel", card_style)
		card.custom_minimum_size = Vector2(0, 110)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var margin := MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 15)
		margin.add_theme_constant_override("margin_top", 15)
		margin.add_theme_constant_override("margin_right", 15)
		margin.add_theme_constant_override("margin_bottom", 15)
		card.add_child(margin)

		var row := HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		margin.add_child(row)

		var vbox_labels := VBoxContainer.new()
		vbox_labels.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		vbox_labels.alignment = BoxContainer.ALIGNMENT_CENTER

		var name_label := Label.new()
		name_label.text = str(artist["name"])
		name_label.add_theme_font_size_override("font_size", 28)
		name_label.add_theme_color_override("font_color", Color(0.95, 0.85, 0.2))
		name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		
		var info_label := Label.new()
		info_label.text = "Role: " + str(artist["role"]).capitalize() + " | Cost: " + str(artist["cost"]) + " TL\n" + \
						  "Pop: " + str(artist["popularity"]) + " | Appeal: " + str(artist["crowd_appeal"])
		info_label.add_theme_font_size_override("font_size", 22)
		info_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
		info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

		vbox_labels.add_child(name_label)
		vbox_labels.add_child(info_label)

		var add_button := Button.new()
		add_button.text = "Add"
		add_button.custom_minimum_size = Vector2(100, 45)
		add_button.add_theme_font_size_override("font_size", 18)
		add_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		
		var btn_style = StyleBoxFlat.new()
		btn_style.bg_color = Color(0.2, 0.6, 0.3)
		btn_style.corner_radius_top_left = 5
		btn_style.corner_radius_top_right = 5
		btn_style.corner_radius_bottom_right = 5
		btn_style.corner_radius_bottom_left = 5
		var btn_hover = btn_style.duplicate()
		btn_hover.bg_color = Color(0.3, 0.7, 0.4)
		add_button.add_theme_stylebox_override("normal", btn_style)
		add_button.add_theme_stylebox_override("hover", btn_hover)
		
		add_button.set_meta("artist_data", artist)
		add_button.pressed.connect(func(): _on_add_artist_pressed(add_button.get_meta("artist_data")))

		row.add_child(vbox_labels)
		row.add_child(add_button)
		available_artists_list.add_child(card)


func refresh_selected_lists() -> void:
	for child in headliner_list.get_children():
		child.queue_free()

	for child in supporting_list.get_children():
		child.queue_free()

	# Headliner
	if GameState.selected_headliners.is_empty():
		var empty_headliner := Label.new()
		empty_headliner.text = "No headliner selected."
		empty_headliner.add_theme_font_size_override("font_size", 22)
		headliner_list.add_child(empty_headliner)
	else:
		for artist in GameState.selected_headliners:
			headliner_list.add_child(_create_selected_artist_row(artist))

	# Supporting
	if GameState.selected_supporting_artists.is_empty():
		var empty_supporting := Label.new()
		empty_supporting.text = "No supporting artists selected."
		empty_supporting.add_theme_font_size_override("font_size", 22)
		supporting_list.add_child(empty_supporting)
	else:
		for artist in GameState.selected_supporting_artists:
			supporting_list.add_child(_create_selected_artist_row(artist))


func _create_selected_artist_row(artist: Dictionary) -> PanelContainer:
	var card := PanelContainer.new()
	var card_style = StyleBoxFlat.new()
	card_style.bg_color = Color(0.1, 0.25, 0.4, 0.6)
	card_style.border_width_left = 1
	card_style.border_width_top = 1
	card_style.border_width_right = 1
	card_style.border_width_bottom = 1
	card_style.border_color = Color(0.3, 0.5, 0.7)
	card_style.corner_radius_top_left = 8
	card_style.corner_radius_top_right = 8
	card_style.corner_radius_bottom_right = 8
	card_style.corner_radius_bottom_left = 8
	card.add_theme_stylebox_override("panel", card_style)
	card.custom_minimum_size = Vector2(0, 110)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 15)
	margin.add_theme_constant_override("margin_top", 15)
	margin.add_theme_constant_override("margin_right", 15)
	margin.add_theme_constant_override("margin_bottom", 15)
	card.add_child(margin)

	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(row)

	var vbox_labels := VBoxContainer.new()
	vbox_labels.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox_labels.alignment = BoxContainer.ALIGNMENT_CENTER

	var name_label := Label.new()
	name_label.text = str(artist["name"])
	name_label.add_theme_font_size_override("font_size", 28)
	name_label.add_theme_color_override("font_color", Color(0.4, 0.9, 1.0))
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	
	var info_label := Label.new()
	info_label.text = "Role: " + str(artist["role"]).capitalize() + " | Cost: " + str(artist["cost"]) + " TL\n" + \
					  "Pop: " + str(artist["popularity"]) + " | Appeal: " + str(artist["crowd_appeal"])
	info_label.add_theme_font_size_override("font_size", 22)
	info_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	vbox_labels.add_child(name_label)
	vbox_labels.add_child(info_label)

	var remove_button := Button.new()
	remove_button.text = "Remove"
	remove_button.custom_minimum_size = Vector2(100, 45)
	remove_button.add_theme_font_size_override("font_size", 18)
	remove_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	
	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = Color(0.8, 0.2, 0.2)
	btn_style.corner_radius_top_left = 5
	btn_style.corner_radius_top_right = 5
	btn_style.corner_radius_bottom_right = 5
	btn_style.corner_radius_bottom_left = 5
	var btn_hover = btn_style.duplicate()
	btn_hover.bg_color = Color(0.9, 0.3, 0.3)
	remove_button.add_theme_stylebox_override("normal", btn_style)
	remove_button.add_theme_stylebox_override("hover", btn_hover)
	
	remove_button.set_meta("artist_data", artist)
	remove_button.pressed.connect(func(): _on_remove_artist_pressed(remove_button.get_meta("artist_data")))

	row.add_child(vbox_labels)
	row.add_child(remove_button)

	return card


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

	money_label.text = "Budget: " + str(GameState.money) + " TL"
	money_label.add_theme_font_size_override("font_size", 24)
	money_label.add_theme_color_override("font_color", Color(0.3, 0.8, 0.3))

	requirements_label.text = \
		"Requirements: 1 Headliner, 2+ Supporting" + \
		"\nStatus: " + str(GameState.selected_headliners.size()) + " Headliner, " + str(GameState.selected_supporting_artists.size()) + " Supporting"
	requirements_label.add_theme_font_size_override("font_size", 20)
	requirements_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))

	total_cost_label.text = "Total Lineup Cost: " + str(total_cost) + " TL"
	total_cost_label.add_theme_font_size_override("font_size", 20)
	total_cost_label.add_theme_color_override("font_color", Color(0.9, 0.4, 0.4))

	total_popularity_label.text = "Lineup Popularity: %.1f / 100" % avg_popularity
	total_popularity_label.add_theme_font_size_override("font_size", 20)
	total_popularity_label.add_theme_color_override("font_color", Color(0.4, 0.9, 1.0))

	total_attendance_label.text = "Expected Crowd: " + str(total_attendance)
	total_attendance_label.add_theme_font_size_override("font_size", 20)
	total_attendance_label.add_theme_color_override("font_color", Color(0.9, 0.8, 0.2))

	remaining_budget_label.text = "Remaining Budget: " + str(remaining_budget) + " TL"
	remaining_budget_label.add_theme_font_size_override("font_size", 24)
	if remaining_budget < 0:
		remaining_budget_label.add_theme_color_override("font_color", Color(0.9, 0.2, 0.2))
	else:
		remaining_budget_label.add_theme_color_override("font_color", Color(0.3, 0.8, 0.3))
		
	if result_label:
		result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		result_label.add_theme_font_size_override("font_size", 22)
		result_label.add_theme_color_override("font_color", Color(0.9, 0.8, 0.2))


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
