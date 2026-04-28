extends Panel

var selected_facility: String = ""
var selected_area_name: String = ""

var came_from_volunteer: bool = false
var return_to_volunteer_btn: Button

# Area Data with quantitative metrics
var areas = {
	"AreaA": {
		"electricity": true, 
		"truck_access": true, 
		"capacity": 100, 
		"size_m2": 500, 
		"elec_kw": 50, 
		"assigned": []
	},
	"AreaB": {
		"electricity": false, 
		"truck_access": true, 
		"capacity": 60, 
		"size_m2": 300, 
		"elec_kw": 0, 
		"assigned": []
	},
	"AreaC": {
		"electricity": true, 
		"truck_access": false, 
		"capacity": 80, 
		"size_m2": 400, 
		"elec_kw": 30, 
		"assigned": []
	},
	"AreaD": {
		"electricity": false, 
		"truck_access": false, 
		"capacity": 40, 
		"size_m2": 200, 
		"elec_kw": 0, 
		"assigned": []
	},
	"AreaE": {
		"electricity": true, 
		"truck_access": true, 
		"capacity": 120, 
		"size_m2": 600, 
		"elec_kw": 60, 
		"assigned": []
	},
	"AreaF": {
		"electricity": false, 
		"truck_access": false, 
		"capacity": 50, 
		"size_m2": 250, 
		"elec_kw": 0, 
		"assigned": []
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
@onready var back_button: Button = $MarginContainer/VBoxContainer/Footer/BackButton

@onready var stage_btn: Button = $MarginContainer/VBoxContainer/MainContent/Palette/PlacementButtons/StageButton
@onready var food_btn: Button = $MarginContainer/VBoxContainer/MainContent/Palette/PlacementButtons/FoodButton
@onready var club_btn: Button = $MarginContainer/VBoxContainer/MainContent/Palette/PlacementButtons/ClubButton

@onready var info_btn: Button = $MarginContainer/VBoxContainer/Header/InfoButton
@onready var guide_panel: PanelContainer = $GuidePanel
@onready var guide_label: Label = $GuidePanel/MarginContainer/VBoxContainer/ScrollContainer/GuideLabel
@onready var close_guide_btn: Button = $GuidePanel/MarginContainer/VBoxContainer/HBoxContainer/CloseGuideButton
@onready var clear_area_btn: Button = $MarginContainer/VBoxContainer/MainContent/RightDetails/DetailsPanel/MarginContainer/VBoxContainer/ClearAreaButton

func _ready() -> void:
	# Palette Connections (Drag Sources)
	stage_btn.set_drag_forwarding(_get_drag_data_for_facility.bind("Stage"), Callable(), Callable())
	food_btn.set_drag_forwarding(_get_drag_data_for_facility.bind("Food Vendor"), Callable(), Callable())
	club_btn.set_drag_forwarding(_get_drag_data_for_facility.bind("Club Stand"), Callable(), Callable())

	# Map Area Connections (Drop Targets)
	for area_name in areas.keys():
		var btn = area_list.get_node(area_name)
		btn.pressed.connect(func(): _on_area_pressed(area_name))
		btn.set_drag_forwarding(Callable(), _can_drop_data_on_area.bind(area_name), _drop_data_on_area.bind(area_name))
		
		# Add Icon Label for electricity and truck
		var icon_label = Label.new()
		icon_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
		icon_label.offset_left = -70
		icon_label.offset_top = -40
		icon_label.offset_right = -10
		icon_label.offset_bottom = -10
		
		var icons = ""
		if areas[area_name]["electricity"]: icons += "⚡"
		if areas[area_name]["truck_access"]: icons += "🚚"
		
		icon_label.text = icons
		icon_label.add_theme_font_size_override("font_size", 20)
		icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		icon_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		btn.add_child(icon_label)

	back_button.pressed.connect(_on_back_pressed)
	clear_area_btn.pressed.connect(_on_clear_area_pressed)
	clear_area_btn.hide()
	
	info_btn.pressed.connect(_on_info_pressed)
	close_guide_btn.pressed.connect(func(): guide_panel.hide())
	_setup_guide_text()

	_setup_ui_styles()
	
	# Special return button for Volunteer Club transition
	return_to_volunteer_btn = Button.new()
	return_to_volunteer_btn.text = "Return to Volunteer Club Selection"
	return_to_volunteer_btn.add_theme_font_size_override("font_size", 18)
	var rbtn_style = StyleBoxFlat.new()
	rbtn_style.bg_color = Color(0.1, 0.4, 0.6, 0.8)
	rbtn_style.set_corner_radius_all(8)
	return_to_volunteer_btn.add_theme_stylebox_override("normal", rbtn_style)
	return_to_volunteer_btn.pressed.connect(_on_return_to_volunteer_pressed)
	return_to_volunteer_btn.hide()
	$MarginContainer/VBoxContainer/Footer.add_child(return_to_volunteer_btn)


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


func _get_drag_data_for_facility(at_position: Vector2, facility_name: String) -> Variant:
	var drag_preview = Label.new()
	drag_preview.text = facility_name
	var style = StyleBoxFlat.new()
	style.bg_color = get_facility_color(facility_name).darkened(0.2)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color.WHITE
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 5
	style.content_margin_bottom = 5
	drag_preview.add_theme_stylebox_override("normal", style)
	
	var control = Control.new()
	control.add_child(drag_preview)
	drag_preview.position = -drag_preview.get_minimum_size() / 2.0
	stage_btn.set_drag_preview(control)
	
	return {"type": "facility", "name": facility_name}

func _can_drop_data_on_area(at_position: Vector2, data: Variant, area_name: String) -> bool:
	if typeof(data) != TYPE_DICTIONARY or not data.has("type") or data["type"] != "facility":
		return false
		
	var facility_name = data["name"]
	var req = requirements.get(facility_name)
	if not req:
		return false
		
	var area = areas[area_name]
	
	# Check used size and capacity
	var used_size = 0
	for assigned_item in area["assigned"]:
		var item_req = requirements.get(assigned_item)
		if item_req:
			used_size += item_req["min_size"]
			
	var remaining_size = area["size_m2"] - used_size
	
	if remaining_size < req["min_size"]:
		return false # Not enough space
		
	return true

func _drop_data_on_area(at_position: Vector2, data: Variant, area_name: String) -> void:
	var facility_name = data["name"]
	areas[area_name]["assigned"].append(facility_name)
	update_area_button_style(area_name)
	if selected_area_name == area_name:
		update_area_info(area_name)

func _on_area_pressed(area_name: String) -> void:
	selected_area_name = area_name
	update_area_info(area_name)
	
func _on_clear_area_pressed() -> void:
	if selected_area_name != "":
		areas[selected_area_name]["assigned"].clear()
		update_area_button_style(selected_area_name)
		update_area_info(selected_area_name)


func update_area_button_style(area_name: String) -> void:
	var btn = area_list.get_node(area_name)
	var area_data = areas[area_name]
	var assigned = area_data["assigned"]
	
	var style = StyleBoxFlat.new()
	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 5
	style.corner_radius_bottom_right = 5
	style.corner_radius_bottom_left = 5
	
	if assigned.size() > 0:
		var counts = {}
		var used_size = 0
		for item in assigned:
			counts[item] = counts.get(item, 0) + 1
			if requirements.has(item):
				used_size += requirements[item]["min_size"]
			
		var assigned_text = ""
		for item in counts:
			if counts[item] > 1:
				assigned_text += item.to_upper() + " x" + str(counts[item]) + "\n"
			else:
				assigned_text += item.to_upper() + "\n"
		
		var remaining_size = area_data["size_m2"] - used_size
		
		# Use color of the first item for background
		var first_item = assigned[0]
		style.bg_color = get_facility_color(first_item).darkened(0.5)
		style.border_width_left = 3
		style.border_width_top = 3
		style.border_width_right = 3
		style.border_width_bottom = 3
		style.border_color = get_facility_color(first_item)
		btn.text = area_name + " (" + str(remaining_size) + " m² left)\n" + \
				   "━━━━━━━━━━\n" + \
				   assigned_text.strip_edges()
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
	
	var used_size = 0
	var assigned_text = "NONE"
	
	if area["assigned"].size() > 0:
		var counts = {}
		for item in area["assigned"]:
			counts[item] = counts.get(item, 0) + 1
			used_size += requirements[item]["min_size"]
			
		var text_parts = []
		for item in counts:
			text_parts.append(item + " x" + str(counts[item]))
		assigned_text = ", ".join(text_parts)
	
	var remaining_size = area["size_m2"] - used_size
	
	area_info_label.text = "ZONE: " + area_name + "\n" + \
		"----------------------\n" + \
		"SIZE: " + str(area["size_m2"]) + " m² (Used: " + str(used_size) + " m², Left: " + str(remaining_size) + " m²)\n" + \
		"POWER: " + str(area["elec_kw"]) + " kW | " + elec_icon + "\n" + \
		"LOGISTICS: " + truck_icon + "\n" + \
		"CAPACITY: " + str(area["capacity"]) + "\n" + \
		"----------------------\n" + \
		"ASSIGNED:\n" + assigned_text

	clear_area_btn.visible = area["assigned"].size() > 0

	# Validation Warning
	_check_validity(area_name)


func _check_validity(area_name: String) -> void:
	var area = areas[area_name]
	var assigned = area["assigned"]
	warning_label.text = ""
	
	if assigned.size() == 0:
		return
		
	var warnings = []
	var needed_elec = false
	var needed_truck = false
	var required_size = 0
	
	for item in assigned:
		var req = requirements.get(item)
		if req:
			if req["electricity"]: needed_elec = true
			if req["truck_access"]: needed_truck = true
			required_size += req["min_size"]
			
	if needed_elec and not area["electricity"]:
		warnings.append("- Lack of Electricity!")
	if needed_truck and not area["truck_access"]:
		warnings.append("- No Truck Access for setup!")
	if area["size_m2"] < required_size:
		warnings.append("- Area too small for all assigned items!")
		
	if warnings.size() > 0:
		warning_label.text = "LOGISTICS WARNING:\n" + "\n".join(warnings)
	else:
		warning_label.text = "Area is suitable for assigned facilities."


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


func _on_back_pressed() -> void:
	came_from_volunteer = false
	if return_to_volunteer_btn:
		return_to_volunteer_btn.hide()
	back_button.show()
	
	GameState.layout_plan = areas
	if not GameState.completed_activities.has("initial_festival_layout_mapping"):
		GameState.completed_activities.append("initial_festival_layout_mapping")
	hide()
	get_parent().get_node("ActivityBoard").show()
	if get_parent().get_node("ActivityBoard").has_method("refresh_board"):
		get_parent().get_node("ActivityBoard").refresh_board()

func open_from_volunteer() -> void:
	came_from_volunteer = true
	back_button.hide()
	return_to_volunteer_btn.show()
	show()

func _on_return_to_volunteer_pressed() -> void:
	GameState.layout_plan = areas
	came_from_volunteer = false
	return_to_volunteer_btn.hide()
	back_button.show()
	hide()
	var volunteer_panel = get_parent().get_node("VolunteerClubPanel")
	if volunteer_panel:
		volunteer_panel.show()
