extends Panel

var selected_facility: String = ""
var selected_area_name: String = ""

# Area Data with quantitative metrics
var areas = {
	"AreaA": {
		"electricity": true, 
		"truck_access": true, 
		"capacity": 100, 
		"size_m2": 500, 
		"elec_kw": 50, 
		"assigned": ""
	},
	"AreaB": {
		"electricity": false, 
		"truck_access": true, 
		"capacity": 60, 
		"size_m2": 300, 
		"elec_kw": 0, 
		"assigned": ""
	},
	"AreaC": {
		"electricity": true, 
		"truck_access": false, 
		"capacity": 80, 
		"size_m2": 400, 
		"elec_kw": 30, 
		"assigned": ""
	},
	"AreaD": {
		"electricity": false, 
		"truck_access": false, 
		"capacity": 40, 
		"size_m2": 200, 
		"elec_kw": 0, 
		"assigned": ""
	}
}

# Facility Requirements
var requirements = {
	"Stage": {"electricity": true, "truck_access": true, "min_size": 350},
	"Food Vendor": {"electricity": true, "truck_access": true, "min_size": 100},
	"Club Stand": {"electricity": false, "truck_access": false, "min_size": 20}
}

# UI References
@onready var area_list: GridContainer = $MarginContainer/VBoxContainer/MainContent/CenterMap/MapArea
@onready var area_info_label: Label = $MarginContainer/VBoxContainer/MainContent/RightDetails/DetailsPanel/MarginContainer/VBoxContainer/AreaInfoLabel
@onready var warning_label: Label = $MarginContainer/VBoxContainer/MainContent/RightDetails/DetailsPanel/MarginContainer/VBoxContainer/WarningLabel
@onready var confirm_button: Button = $MarginContainer/VBoxContainer/Footer/ConfirmButton
@onready var back_button: Button = $MarginContainer/VBoxContainer/Footer/BackButton

@onready var stage_btn: Button = $MarginContainer/VBoxContainer/MainContent/Palette/PlacementButtons/StageButton
@onready var food_btn: Button = $MarginContainer/VBoxContainer/MainContent/Palette/PlacementButtons/FoodButton
@onready var club_btn: Button = $MarginContainer/VBoxContainer/MainContent/Palette/PlacementButtons/ClubButton

@onready var info_btn: Button = $MarginContainer/VBoxContainer/Header/InfoButton
@onready var guide_panel: PanelContainer = $GuidePanel
@onready var guide_label: Label = $GuidePanel/MarginContainer/VBoxContainer/ScrollContainer/GuideLabel
@onready var close_guide_btn: Button = $GuidePanel/MarginContainer/VBoxContainer/HBoxContainer/CloseGuideButton

func _ready() -> void:
	# Palette Connections
	stage_btn.pressed.connect(func(): _on_palette_selected("Stage", stage_btn))
	food_btn.pressed.connect(func(): _on_palette_selected("Food Vendor", food_btn))
	club_btn.pressed.connect(func(): _on_palette_selected("Club Stand", club_btn))

	# Map Area Connections
	for area_name in areas.keys():
		var btn = area_list.get_node(area_name)
		btn.pressed.connect(func(): _on_area_pressed(area_name))

	confirm_button.pressed.connect(_on_confirm_pressed)
	back_button.pressed.connect(_on_back_pressed)
	
	# Guide Connections
	info_btn.pressed.connect(_on_info_pressed)
	close_guide_btn.pressed.connect(func(): guide_panel.hide())
	_setup_guide_text()

	_setup_ui_styles()


func _setup_ui_styles() -> void:
	# Main Panel Glassmorphism
	var main_style = StyleBoxFlat.new()
	main_style.bg_color = Color(0.05, 0.07, 0.1, 0.95)
	main_style.border_width_left = 4
	main_style.border_color = Color(0.1, 0.6, 0.4)
	add_theme_stylebox_override("panel", main_style)

	# Details Panel
	var side_style = StyleBoxFlat.new()
	side_style.bg_color = Color(0.1, 0.12, 0.15, 0.8)
	side_style.corner_radius_top_left = 10
	side_style.corner_radius_top_right = 10
	side_style.corner_radius_bottom_right = 10
	side_style.corner_radius_bottom_left = 10
	side_style.border_width_left = 1
	side_style.border_width_top = 1
	side_style.border_width_right = 1
	side_style.border_width_bottom = 1
	side_style.border_color = Color(0.2, 0.4, 0.3)
	$MarginContainer/VBoxContainer/MainContent/RightDetails/DetailsPanel.add_theme_stylebox_override("panel", side_style)

	# Initial Area Button Styles
	for area_name in areas.keys():
		update_area_button_style(area_name)


func _on_palette_selected(facility: String, btn: Button) -> void:
	if selected_facility == facility:
		# Deselect if clicking the same button
		selected_facility = ""
		btn.remove_theme_stylebox_override("normal")
		return
		
	selected_facility = facility
	
	# Reset palette buttons
	stage_btn.remove_theme_stylebox_override("normal")
	food_btn.remove_theme_stylebox_override("normal")
	club_btn.remove_theme_stylebox_override("normal")
	
	# Highlight selected
	var select_style = StyleBoxFlat.new()
	select_style.bg_color = get_facility_color(facility).darkened(0.3)
	select_style.border_width_left = 2
	select_style.border_width_top = 2
	select_style.border_width_right = 2
	select_style.border_width_bottom = 2
	select_style.border_color = Color.WHITE
	btn.add_theme_stylebox_override("normal", select_style)


func _on_area_pressed(area_name: String) -> void:
	selected_area_name = area_name

	# If the area already has something assigned, clear it.
	# Otherwise, assign the selected facility.
	if areas[area_name]["assigned"] != "":
		areas[area_name]["assigned"] = ""
	else:
		if selected_facility != "":
			areas[area_name]["assigned"] = selected_facility
	
	update_area_button_style(area_name)
	update_area_info(area_name)


func update_area_button_style(area_name: String) -> void:
	var btn = area_list.get_node(area_name)
	var area_data = areas[area_name]
	var assigned = area_data["assigned"]
	
	var style = StyleBoxFlat.new()
	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 5
	style.corner_radius_bottom_right = 5
	style.corner_radius_bottom_left = 5
	
	if assigned != "":
		style.bg_color = get_facility_color(assigned).darkened(0.5)
		style.border_width_left = 3
		style.border_width_top = 3
		style.border_width_right = 3
		style.border_width_bottom = 3
		style.border_color = get_facility_color(assigned)
		btn.text = area_name + "\n[" + assigned.to_upper() + "]\n" + str(area_data["size_m2"]) + " m²"
	else:
		style.bg_color = Color(0.15, 0.18, 0.2, 0.6)
		style.border_width_left = 1
		style.border_width_top = 1
		style.border_width_right = 1
		style.border_width_bottom = 1
		style.border_color = Color(0.4, 0.5, 0.6)
		btn.text = area_name + "\n(EMPTY)\n" + str(area_data["size_m2"]) + " m²"
		
	btn.add_theme_stylebox_override("normal", style)


func get_facility_color(facility: String) -> Color:
	match facility:
		"Stage": return Color(0.5, 0.2, 0.9)
		"Food Vendor": return Color(0.9, 0.6, 0.1)
		"Club Stand": return Color(0.2, 0.8, 0.3)
	return Color.GRAY


func update_area_info(area_name: String) -> void:
	var area = areas[area_name]
	
	var elec_icon = "POWER OK" if area["electricity"] else "NO POWER"
	var truck_icon = "TRUCK OK" if area["truck_access"] else "NO ACCESS"
	
	area_info_label.text = "ZONE: " + area_name + "\n" + \
		"----------------------\n" + \
		"SIZE: " + str(area["size_m2"]) + " m²\n" + \
		"POWER: " + str(area["elec_kw"]) + " kW | " + elec_icon + "\n" + \
		"LOGISTICS: " + truck_icon + "\n" + \
		"CAPACITY: " + str(area["capacity"]) + "\n" + \
		"----------------------\n" + \
		"ASSIGNED: " + (area["assigned"] if area["assigned"] != "" else "NONE")

	# Validation Warning
	_check_validity(area_name)


func _check_validity(area_name: String) -> void:
	var area = areas[area_name]
	var assigned = area["assigned"]
	warning_label.text = ""
	
	if assigned == "":
		return
		
	var req = requirements.get(assigned)
	if not req:
		return
		
	var warnings = []
	if req["electricity"] and not area["electricity"]:
		warnings.append("- Lack of Electricity!")
	if req["truck_access"] and not area["truck_access"]:
		warnings.append("- No Truck Access for setup!")
	if area["size_m2"] < req["min_size"]:
		warnings.append("- Area too small for " + assigned + "!")
		
	if warnings.size() > 0:
		warning_label.text = "LOGISTICS WARNING:\n" + "\n".join(warnings)
	else:
		warning_label.text = "Area is suitable for " + assigned + "."


func _on_info_pressed() -> void:
	guide_panel.show()


func _setup_guide_text() -> void:
	guide_label.text = "INITIAL FESTIVAL LAYOUT MAPPING\n\n" + \
		"Activity Overview:\n" + \
		"In this stage, you explore the festival area and create an initial layout plan. The map presents multiple zones, each with different features, capacities, and technical constraints.\n\n" + \
		"Your Objective:\n" + \
		"Develop a clear understanding of the festival space and determine suitability for activities.\n\n" + \
		"Understanding Area Features:\n" + \
		"• Stage: Suitable for performances and large audiences. REQUIRES: Electricity, Truck Access, Min 350m².\n" + \
		"• Food Vendors: Suitable for stands. REQUIRES: Electricity, Truck Access, Min 100m².\n" + \
		"• Student Club Stands: Suitable for booths. REQUIRES: Min 20m².\n\n" + \
		"Match Needs:\n" + \
		"Ensure areas meet technical and logistical requirements."


func _on_confirm_pressed() -> void:
	GameState.layout_plan = areas
	if not GameState.completed_activities.has("initial_festival_layout_mapping"):
		GameState.completed_activities.append("initial_festival_layout_mapping")
	hide()
	get_parent().get_node("ActivityBoard").show()
	get_parent().get_node("ActivityBoard").refresh_board()


func _on_back_pressed() -> void:
	hide()
	get_parent().get_node("ActivityBoard").show()
