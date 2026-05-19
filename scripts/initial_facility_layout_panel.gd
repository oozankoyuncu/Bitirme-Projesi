extends Panel

var selected_facility: String = ""
var selected_area_name: String = ""

var came_from_volunteer: bool = false
var return_to_volunteer_btn: Button

# Plan Management
var plans: Array = []
var active_plan_index: int = 0
var plan_buttons: Array = []

# Area Data with quantitative metrics
var areas = {
	"AreaA": {
		"electricity": true, 
		"truck_access": true, 
		"capacity": 70, 
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
		"capacity": 40, 
		"size_m2": 400, 
		"elec_kw": 30, 
		"assigned": []
	},
	"AreaD": {
		"electricity": false, 
		"truck_access": true, 
		"capacity": 30, 
		"size_m2": 200, 
		"elec_kw": 0, 
		"assigned": []
	},
	"AreaE": {
		"electricity": true, 
		"truck_access": false, 
		"capacity": 40, 
		"size_m2": 600, 
		"elec_kw": 60, 
		"assigned": []
	},
	"AreaF": {
		"electricity": true, 
		"truck_access": true, 
		"capacity": 50, 
		"size_m2": 250, 
		"elec_kw": 20, 
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
@onready var center_map: CenterContainer = $MarginContainer/VBoxContainer/MainContent/CenterMap
@onready var area_list: Control = $MarginContainer/VBoxContainer/MainContent/CenterMap/MapArea
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
	# Initialize the plans and load active plan state
	initialize_plans()
	var target_plan = plans[active_plan_index]
	for area_name in areas.keys():
		areas[area_name]["assigned"] = target_plan[area_name]["assigned"].duplicate()

	_setup_map()
	
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
		icon_label.offset_left = -55
		icon_label.offset_top = -30
		icon_label.offset_right = -5
		icon_label.offset_bottom = -5
		
		var icons = ""
		if areas[area_name]["electricity"]: icons += "⚡"
		if areas[area_name]["truck_access"]: icons += "🚚"
		
		icon_label.text = icons
		icon_label.add_theme_font_size_override("font_size", 20)
		icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		icon_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		btn.add_child(icon_label)
		
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		btn.clip_text = true
		btn.add_theme_font_size_override("font_size", 18)

	back_button.pressed.connect(_on_back_pressed)
	clear_area_btn.pressed.connect(_on_clear_area_pressed)
	clear_area_btn.hide()
	
	info_btn.pressed.connect(_on_info_pressed)
	close_guide_btn.pressed.connect(func(): guide_panel.hide())
	_setup_guide_text()

	_setup_ui_styles()
	
	# Setup Plan Switcher Tabs
	_setup_plan_navigation()
	
	# Special return button for Volunteer Club transition
	return_to_volunteer_btn = Button.new()
	return_to_volunteer_btn.text = "↩️ RETURN TO VOLUNTEER CLUB SELECTION"
	return_to_volunteer_btn.add_theme_font_size_override("font_size", 24)
	return_to_volunteer_btn.custom_minimum_size = Vector2(600, 70)
	
	var rbtn_style = StyleBoxFlat.new()
	rbtn_style.bg_color = Color(0.1, 0.4, 0.6, 0.9) # Prominent Blue
	rbtn_style.border_width_left = 4
	rbtn_style.border_width_top = 4
	rbtn_style.border_width_right = 4
	rbtn_style.border_width_bottom = 4
	rbtn_style.border_color = Color(0.3, 0.7, 1.0, 1.0)
	rbtn_style.set_corner_radius_all(12)
	
	var rbtn_hover = rbtn_style.duplicate()
	rbtn_hover.bg_color = Color(0.15, 0.5, 0.8, 1.0)
	
	return_to_volunteer_btn.add_theme_stylebox_override("normal", rbtn_style)
	return_to_volunteer_btn.add_theme_stylebox_override("hover", rbtn_hover)
	return_to_volunteer_btn.add_theme_stylebox_override("pressed", rbtn_style)
	
	return_to_volunteer_btn.pressed.connect(_on_return_to_volunteer_pressed)
	return_to_volunteer_btn.hide()
	
	# Create a top container for this button
	var layout_btn_container = CenterContainer.new()
	layout_btn_container.name = "ReturnToVolunteerContainer"
	layout_btn_container.custom_minimum_size = Vector2(0, 80)
	layout_btn_container.add_child(return_to_volunteer_btn)
	
	$MarginContainer/VBoxContainer.add_child(layout_btn_container)
	$MarginContainer/VBoxContainer.move_child(layout_btn_container, 1) # Below header

func _setup_map() -> void:
	var tex = load("res://assets/images/sabanci_map_bg.png")
	
	var aspect = AspectRatioContainer.new()
	aspect.ratio = 1024.0 / 688.0
	aspect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	aspect.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	var tex_rect = TextureRect.new()
	tex_rect.texture = tex
	tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex_rect.stretch_mode = TextureRect.STRETCH_SCALE
	tex_rect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tex_rect.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	aspect.add_child(tex_rect)
	
	var main_content = center_map.get_parent()
	main_content.add_child(aspect)
	main_content.move_child(aspect, 1)
	
	# Move buttons to TextureRect
	var children = area_list.get_children()
	for child in children:
		area_list.remove_child(child)
		tex_rect.add_child(child)
		child.size_flags_horizontal = 0
		child.size_flags_vertical = 0
		child.custom_minimum_size = Vector2(0, 0)
	
	# Assign relative anchors
	_set_anchors(tex_rect.get_node("AreaA"), 0.28, 0.25, 0.58, 0.38)
	_set_anchors(tex_rect.get_node("AreaB"), 0.24, 0.44, 0.38, 0.64)
	_set_anchors(tex_rect.get_node("AreaC"), 0.40, 0.44, 0.52, 0.64)
	_set_anchors(tex_rect.get_node("AreaD"), 0.54, 0.40, 0.66, 0.62)
	_set_anchors(tex_rect.get_node("AreaE"), 0.70, 0.30, 0.85, 0.50)
	_set_anchors(tex_rect.get_node("AreaF"), 0.33, 0.76, 0.67, 0.88)
	
	center_map.queue_free()
	area_list = tex_rect

func _set_anchors(btn: Control, left: float, top: float, right: float, bottom: float) -> void:
	btn.anchor_left = left
	btn.anchor_top = top
	btn.anchor_right = right
	btn.anchor_bottom = bottom
	btn.offset_left = 0
	btn.offset_top = 0
	btn.offset_right = 0
	btn.offset_bottom = 0

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
		style.bg_color.a = 0.85
		style.border_width_left = 3
		style.border_width_top = 3
		style.border_width_right = 3
		style.border_width_bottom = 3
		style.border_color = get_facility_color(first_item)
		btn.text = area_name + "\n" + str(remaining_size) + "m² left\n" + \
				   assigned_text.strip_edges()
		btn.add_theme_font_size_override("font_size", 15)
	else:
		style.bg_color = Color(0.15, 0.18, 0.2, 0.4) # Semi-transparent empty
		style.border_width_left = 2
		style.border_width_top = 2
		style.border_width_right = 2
		style.border_width_bottom = 2
		style.border_color = Color(0.8, 0.3, 0.3, 0.8) # Reddish border to highlight empty drop zones
		btn.text = area_name + "\n" + str(area_data["size_m2"]) + "m²"
		btn.add_theme_font_size_override("font_size", 18)
		
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
	area_info_label.add_theme_font_size_override("font_size", 20) # Larger sidebar text

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
		return_to_volunteer_btn.get_parent().hide() # Hide the entire container
	back_button.show()
	
	# Save current active plan
	plans[active_plan_index] = {}
	for area_name in areas.keys():
		var area_data = areas[area_name]
		plans[active_plan_index][area_name] = {
			"electricity": area_data["electricity"],
			"truck_access": area_data["truck_access"],
			"capacity": area_data["capacity"],
			"size_m2": area_data["size_m2"],
			"elec_kw": area_data["elec_kw"],
			"assigned": area_data["assigned"].duplicate()
		}
	GameState.layout_plans = plans
	GameState.layout_active_plan_index = active_plan_index
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
	if return_to_volunteer_btn:
		return_to_volunteer_btn.get_parent().show() # Show the container
		return_to_volunteer_btn.show()
	show()

func _on_return_to_volunteer_pressed() -> void:
	# Save current active plan
	plans[active_plan_index] = {}
	for area_name in areas.keys():
		var area_data = areas[area_name]
		plans[active_plan_index][area_name] = {
			"electricity": area_data["electricity"],
			"truck_access": area_data["truck_access"],
			"capacity": area_data["capacity"],
			"size_m2": area_data["size_m2"],
			"elec_kw": area_data["elec_kw"],
			"assigned": area_data["assigned"].duplicate()
		}
	GameState.layout_plans = plans
	GameState.layout_active_plan_index = active_plan_index
	GameState.layout_plan = areas
	
	came_from_volunteer = false
	if return_to_volunteer_btn:
		return_to_volunteer_btn.get_parent().hide()
	back_button.show()
	hide()
	var volunteer_panel = get_parent().get_node("VolunteerClubPanel")
	if volunteer_panel:
		volunteer_panel.show()

func initialize_plans() -> void:
	if GameState.layout_plans.size() > 0:
		plans = GameState.layout_plans
		active_plan_index = GameState.layout_active_plan_index
	else:
		plans.clear()
		for i in range(3):
			var plan_copy = {}
			for area_name in areas.keys():
				var area_def = areas[area_name]
				plan_copy[area_name] = {
					"electricity": area_def["electricity"],
					"truck_access": area_def["truck_access"],
					"capacity": area_def["capacity"],
					"size_m2": area_def["size_m2"],
					"elec_kw": area_def["elec_kw"],
					"assigned": []
				}
			plans.append(plan_copy)
		
		# If there's an existing plan in GameState, load it into Plan 1
		if GameState.layout_plan.size() > 0:
			for area_name in GameState.layout_plan.keys():
				if plans[0].has(area_name):
					plans[0][area_name]["assigned"] = GameState.layout_plan[area_name]["assigned"].duplicate()
		
		GameState.layout_plans = plans
		GameState.layout_active_plan_index = 0

func _setup_plan_navigation() -> void:
	var palette = $MarginContainer/VBoxContainer/MainContent/Palette
	
	# Container for the plan switcher
	var switcher_vbox = VBoxContainer.new()
	switcher_vbox.name = "PlanNavigation"
	switcher_vbox.add_theme_constant_override("separation", 10)
	
	# Title label for switcher
	var title = Label.new()
	title.text = "SELECT ACTIVE PLAN"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color(0.2, 0.9, 0.5, 0.8)) # Vibrant light emerald glow
	switcher_vbox.add_child(title)
	
	# Buttons container
	var btn_vbox = VBoxContainer.new()
	btn_vbox.add_theme_constant_override("separation", 8)
	switcher_vbox.add_child(btn_vbox)
	
	plan_buttons.clear()
	for i in range(3):
		var btn = Button.new()
		btn.text = "📋 Plan " + str(i + 1)
		btn.custom_minimum_size = Vector2(200, 42)
		btn.toggle_mode = true
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		btn.add_theme_font_size_override("font_size", 16)
		
		# Styles
		var style_normal = StyleBoxFlat.new()
		style_normal.bg_color = Color(0.1, 0.12, 0.15, 0.9)
		style_normal.border_width_left = 1
		style_normal.border_width_top = 1
		style_normal.border_width_right = 1
		style_normal.border_width_bottom = 1
		style_normal.border_color = Color(0.2, 0.3, 0.4, 0.5)
		style_normal.set_corner_radius_all(8)
		
		var style_selected = StyleBoxFlat.new()
		style_selected.bg_color = Color(0.1, 0.45, 0.3, 0.9) # Green theme for layouts
		style_selected.border_width_left = 3
		style_selected.border_width_top = 1
		style_selected.border_width_right = 1
		style_selected.border_width_bottom = 1
		style_selected.border_color = Color(0.2, 0.9, 0.5, 1.0)
		style_selected.set_corner_radius_all(8)
		
		var style_hover = style_selected.duplicate()
		style_hover.bg_color = Color(0.12, 0.5, 0.35, 1.0)
		
		btn.add_theme_stylebox_override("normal", style_normal)
		btn.add_theme_stylebox_override("pressed", style_selected)
		btn.add_theme_stylebox_override("hover", style_hover)
		
		btn.pressed.connect(_on_plan_tab_pressed.bind(i))
		btn_vbox.add_child(btn)
		plan_buttons.append(btn)
		
	# A small separator between the switcher and construction palette
	var sep = HSeparator.new()
	switcher_vbox.add_child(sep)
	
	# Insert at the very top of the Palette (Index 0)
	palette.add_child(switcher_vbox)
	palette.move_child(switcher_vbox, 0)
	
	_select_plan_tab(active_plan_index)

func _on_plan_tab_pressed(index: int) -> void:
	if index == active_plan_index:
		plan_buttons[index].button_pressed = true
		return
		
	# Save current active plan's assigned items
	plans[active_plan_index] = {}
	for area_name in areas.keys():
		var area_data = areas[area_name]
		plans[active_plan_index][area_name] = {
			"electricity": area_data["electricity"],
			"truck_access": area_data["truck_access"],
			"capacity": area_data["capacity"],
			"size_m2": area_data["size_m2"],
			"elec_kw": area_data["elec_kw"],
			"assigned": area_data["assigned"].duplicate()
		}
		
	# Switch index
	active_plan_index = index
	GameState.layout_active_plan_index = index
	
	# Load new plan's state
	var target_plan = plans[active_plan_index]
	for area_name in areas.keys():
		areas[area_name]["assigned"] = target_plan[area_name]["assigned"].duplicate()
		
	# Refresh UI display
	for area_name in areas.keys():
		update_area_button_style(area_name)
		
	if selected_area_name != "":
		update_area_info(selected_area_name)
	else:
		area_info_label.text = "Select a zone to inspect details."
		clear_area_btn.hide()
		warning_label.text = ""
		
	_select_plan_tab(index)

func _select_plan_tab(index: int) -> void:
	for i in range(plan_buttons.size()):
		var btn = plan_buttons[i]
		btn.button_pressed = (i == index)
