extends Panel

var selected_area_name: String = ""

# Keep track of which items are placed where
# "item_id": "AreaA" (if placed) or "" (if not placed)
var placed_items = {}
var unified_items = {}

var areas = {
	"AreaA": {"electricity": true, "truck_access": true, "capacity": 100, "size_m2": 500, "elec_kw": 50, "assigned": []},
	"AreaB": {"electricity": false, "truck_access": true, "capacity": 60, "size_m2": 300, "elec_kw": 0, "assigned": []},
	"AreaC": {"electricity": true, "truck_access": false, "capacity": 80, "size_m2": 400, "elec_kw": 30, "assigned": []},
	"AreaD": {"electricity": false, "truck_access": false, "capacity": 40, "size_m2": 200, "elec_kw": 0, "assigned": []},
	"AreaE": {"electricity": true, "truck_access": true, "capacity": 120, "size_m2": 600, "elec_kw": 60, "assigned": []},
	"AreaF": {"electricity": false, "truck_access": false, "capacity": 50, "size_m2": 250, "elec_kw": 0, "assigned": []}
}

@onready var area_list: GridContainer = $MarginContainer/VBoxContainer/MainContent/CenterMap/MapArea
@onready var area_info_label: Label = $MarginContainer/VBoxContainer/MainContent/RightDetails/DetailsPanel/MarginContainer/VBoxContainer/AreaInfoLabel
@onready var warning_label: Label = $MarginContainer/VBoxContainer/MainContent/RightDetails/DetailsPanel/MarginContainer/VBoxContainer/WarningLabel
@onready var back_button: Button = $MarginContainer/VBoxContainer/Footer/BackButton
@onready var confirm_button: Button = $MarginContainer/VBoxContainer/Footer/ConfirmButton

@onready var placement_buttons: VBoxContainer = $MarginContainer/VBoxContainer/MainContent/Palette/ScrollContainer/PlacementButtons

@onready var info_btn: Button = $MarginContainer/VBoxContainer/Header/InfoButton
@onready var guide_panel: PanelContainer = $GuidePanel
@onready var guide_label: Label = $GuidePanel/MarginContainer/VBoxContainer/ScrollContainer/GuideLabel
@onready var close_guide_btn: Button = $GuidePanel/MarginContainer/VBoxContainer/HBoxContainer/CloseGuideButton
@onready var clear_area_btn: Button = $MarginContainer/VBoxContainer/MainContent/RightDetails/DetailsPanel/MarginContainer/VBoxContainer/ClearAreaButton

func _ready() -> void:
	visibility_changed.connect(_on_visibility_changed)
	
	# Map Connections
	for area_name in areas.keys():
		var btn = area_list.get_node(area_name)
		btn.pressed.connect(func(): _on_area_pressed(area_name))
		btn.set_drag_forwarding(Callable(), _can_drop_data_on_area.bind(area_name), _drop_data_on_area.bind(area_name))
		
		# Add icons
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
	confirm_button.pressed.connect(_on_confirm_pressed)
	clear_area_btn.pressed.connect(_on_clear_area_pressed)
	clear_area_btn.hide()
	
	info_btn.pressed.connect(func(): guide_panel.show())
	close_guide_btn.pressed.connect(func(): guide_panel.hide())
	_setup_guide_text()
	_setup_ui_styles()

func _on_visibility_changed() -> void:
	if visible:
		populate_unified_items()

func populate_unified_items() -> void:
	unified_items.clear()
	placed_items.clear()
	
	# Food Vendors
	var food_panel = get_parent().get_node_or_null("FoodVendorSelectionPanel")
	if food_panel:
		var food_options = food_panel.vendor_options
		for f_id in GameState.selected_food_vendors:
			if food_options.has(f_id):
				var f = food_options[f_id]
				var uid = "food_" + f_id
				var allocated_space = f.get("space_requirement", 10)
				if food_panel.has_method("get_allocated_space"):
					allocated_space = food_panel.get_allocated_space(f_id)
				unified_items[uid] = {
					"display_name": f["display_name"],
					"type": "Food Vendor",
					"electricity": f["electricity_requirement"] > 0,
					"truck_access": true,
					"min_size": allocated_space
				}
				placed_items[uid] = ""
				
	# Volunteer Clubs
	var club_panel = get_parent().get_node_or_null("VolunteerClubPanel")
	if club_panel:
		var club_options = club_panel.club_options
		for c_id in GameState.selected_volunteer_clubs:
			if club_options.has(c_id):
				var c = club_options[c_id]
				var uid = "club_" + c_id
				unified_items[uid] = {
					"display_name": c["display_name"],
					"type": "Club Stand",
					"electricity": false,
					"truck_access": false,
					"min_size": c["space_requirement"]
				}
				placed_items[uid] = ""
				
	# Stage Setup
	if GameState.selected_stage_setup.has("name"):
		var s = GameState.selected_stage_setup
		var uid = "stage_main"
		unified_items[uid] = {
			"display_name": s["name"],
			"type": "Stage",
			"electricity": true,
			"truck_access": true,
			"min_size": s.get("stage_size", 2) * 50
		}
		placed_items[uid] = ""
		
	# Reconcile placed_items with areas
	for area_name in areas.keys():
		var assigned = areas[area_name]["assigned"]
		var valid_assigned = []
		for uid in assigned:
			if unified_items.has(uid):
				valid_assigned.append(uid)
				placed_items[uid] = area_name
		areas[area_name]["assigned"] = valid_assigned
		update_area_button_style(area_name)
		
	# Now generate the palette buttons
	for child in placement_buttons.get_children():
		child.queue_free()
		
	for uid in unified_items.keys():
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(0, 50)
		btn.name = uid
		if placed_items[uid] != "":
			btn.disabled = true
			btn.text = "[PLACED] " + unified_items[uid]["display_name"]
		else:
			btn.text = unified_items[uid]["display_name"]
		btn.set_drag_forwarding(_get_drag_data_for_item.bind(uid), Callable(), Callable())
		placement_buttons.add_child(btn)
		
	if GameState.final_layout_completed:
		confirm_button.text = "BACK TO BOARD"
		# Pre-populate map if revisiting
		# Simplification: assuming no save/load needed for map details for now
		
func _setup_ui_styles() -> void:
	var main_style = StyleBoxFlat.new()
	main_style.bg_color = Color(0.05, 0.07, 0.1, 0.95)
	main_style.border_width_left = 4
	main_style.border_color = Color(0.6, 0.2, 0.8) # Purple accent for final layout
	add_theme_stylebox_override("panel", main_style)

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
	side_style.border_color = Color(0.4, 0.3, 0.6)
	$MarginContainer/VBoxContainer/MainContent/RightDetails/DetailsPanel.add_theme_stylebox_override("panel", side_style)

	for area_name in areas.keys():
		update_area_button_style(area_name)

func _get_drag_data_for_item(at_position: Vector2, uid: String) -> Variant:
	if placed_items[uid] != "":
		return null # Already placed, cannot drag
		
	var item = unified_items[uid]
	var drag_preview = Label.new()
	drag_preview.text = item["display_name"]
	
	var style = StyleBoxFlat.new()
	style.bg_color = get_item_color(item["type"]).darkened(0.2)
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
	placement_buttons.get_node(uid).set_drag_preview(control)
	
	return {"type": "facility", "uid": uid}

func _can_drop_data_on_area(at_position: Vector2, data: Variant, area_name: String) -> bool:
	if typeof(data) != TYPE_DICTIONARY or not data.has("type") or data["type"] != "facility":
		return false
		
	var uid = data["uid"]
	if not unified_items.has(uid): return false
	
	var item = unified_items[uid]
	var area = areas[area_name]
	
	var used_size = 0
	for assigned_uid in area["assigned"]:
		used_size += unified_items[assigned_uid]["min_size"]
			
	var remaining_size = area["size_m2"] - used_size
	
	if remaining_size < item["min_size"]:
		return false
		
	return true

func _drop_data_on_area(at_position: Vector2, data: Variant, area_name: String) -> void:
	var uid = data["uid"]
	areas[area_name]["assigned"].append(uid)
	placed_items[uid] = area_name
	
	# Disable palette button
	if placement_buttons.has_node(uid):
		placement_buttons.get_node(uid).disabled = true
		placement_buttons.get_node(uid).text = "[PLACED] " + unified_items[uid]["display_name"]
		
	update_area_button_style(area_name)
	if selected_area_name == area_name:
		update_area_info(area_name)

func _on_area_pressed(area_name: String) -> void:
	selected_area_name = area_name
	update_area_info(area_name)
	
func _on_clear_area_pressed() -> void:
	if selected_area_name != "":
		# Re-enable palette buttons
		for uid in areas[selected_area_name]["assigned"]:
			placed_items[uid] = ""
			if placement_buttons.has_node(uid):
				placement_buttons.get_node(uid).disabled = false
				placement_buttons.get_node(uid).text = unified_items[uid]["display_name"]
				
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
		var used_size = 0
		var assigned_text = ""
		for uid in assigned:
			used_size += unified_items[uid]["min_size"]
			assigned_text += unified_items[uid]["display_name"] + "\n"
		
		var remaining_size = area_data["size_m2"] - used_size
		var first_item = unified_items[assigned[0]]
		
		style.bg_color = get_item_color(first_item["type"]).darkened(0.5)
		style.border_width_left = 3
		style.border_width_top = 3
		style.border_width_right = 3
		style.border_width_bottom = 3
		style.border_color = get_item_color(first_item["type"])
		
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

func get_item_color(type: String) -> Color:
	match type:
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
		var text_parts = []
		for uid in area["assigned"]:
			used_size += unified_items[uid]["min_size"]
			text_parts.append("- " + unified_items[uid]["display_name"])
		assigned_text = "\n".join(text_parts)
	
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
	_check_validity(area_name)

func _check_validity(area_name: String) -> void:
	var area = areas[area_name]
	var assigned = area["assigned"]
	warning_label.text = ""
	
	if assigned.size() == 0: return
		
	var warnings = []
	var needed_elec = false
	var needed_truck = false
	var required_size = 0
	
	for uid in assigned:
		var item = unified_items[uid]
		if item["electricity"]: needed_elec = true
		if item["truck_access"]: needed_truck = true
		required_size += item["min_size"]
			
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

func _setup_guide_text() -> void:
	guide_label.text = "FINAL FESTIVAL LAYOUT MAPPING\n\n" + \
		"Activity Overview:\n" + \
		"You must now accurately place the precise items you selected (Food Vendors, Club Stands, and your actual Stage). You must assign every chosen facility to an appropriate area to complete the map.\n\n" + \
		"Rules:\n" + \
		"• Each selected item appears in the palette exactly once.\n" + \
		"• Once placed, the item cannot be dragged again unless you clear the area."

func _on_confirm_pressed() -> void:
	if GameState.final_layout_completed:
		hide()
		get_parent().get_node("ActivityBoard").show()
		return
		
	GameState.finalize_final_layout(areas)
	hide()
	get_parent().get_node("ActivityBoard").show()
	
	if get_parent().get_node("ActivityBoard").has_method("refresh_board"):
		get_parent().get_node("ActivityBoard").refresh_board()

func _on_back_pressed() -> void:
	hide()
	get_parent().get_node("ActivityBoard").show()
