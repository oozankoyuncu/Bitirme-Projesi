extends Panel

var selected_area_name: String = ""

# Keep track of which items are placed where
# "item_id": "AreaA" (if placed) or "" (if not placed)
var placed_items = {}
var unified_items = {}

var areas = {
	"AreaA": {"electricity": true, "truck_access": true, "capacity": 70, "size_m2": 500, "elec_kw": 50, "assigned": []},
	"AreaB": {"electricity": false, "truck_access": true, "capacity": 60, "size_m2": 300, "elec_kw": 0, "assigned": []},
	"AreaC": {"electricity": true, "truck_access": false, "capacity": 40, "size_m2": 400, "elec_kw": 30, "assigned": []},
	"AreaD": {"electricity": false, "truck_access": true, "capacity": 30, "size_m2": 200, "elec_kw": 0, "assigned": []},
	"AreaE": {"electricity": true, "truck_access": false, "capacity": 40, "size_m2": 600, "elec_kw": 60, "assigned": []},
	"AreaF": {"electricity": true, "truck_access": true, "capacity": 50, "size_m2": 250, "elec_kw": 20, "assigned": []}
}

@onready var center_map: CenterContainer = $MarginContainer/VBoxContainer/MainContent/CenterMap
@onready var area_list: Control = $MarginContainer/VBoxContainer/MainContent/CenterMap/MapArea
@onready var area_info_label: Label = $MarginContainer/VBoxContainer/MainContent/RightDetails/DetailsPanel/MarginContainer/VBoxContainer/AreaInfoLabel
@onready var warning_label: Label = $MarginContainer/VBoxContainer/MainContent/RightDetails/DetailsPanel/MarginContainer/VBoxContainer/WarningLabel
@onready var back_button: Button = $MarginContainer/VBoxContainer/Footer/BackButton
@onready var finish_button: Button = $MarginContainer/VBoxContainer/Footer/FinishButton
@onready var confirm_button: Button = $MarginContainer/VBoxContainer/Footer/ConfirmButton

@onready var placement_buttons: VBoxContainer = $MarginContainer/VBoxContainer/MainContent/Palette/ScrollContainer/PlacementButtons

@onready var info_btn: Button = $MarginContainer/VBoxContainer/Header/InfoButton
@onready var guide_panel: PanelContainer = $GuidePanel
@onready var guide_label: Label = $GuidePanel/MarginContainer/VBoxContainer/ScrollContainer/GuideLabel
@onready var close_guide_btn: Button = $GuidePanel/MarginContainer/VBoxContainer/HBoxContainer/CloseGuideButton
@onready var clear_area_btn: Button = $MarginContainer/VBoxContainer/MainContent/RightDetails/DetailsPanel/MarginContainer/VBoxContainer/ClearAreaButton

func _ready() -> void:

	# -- DYNAMIC BUTTON INJECTION --
	var __footer_found = false
	var __footer_node = null
	
	# Try common paths
	var __paths = [
		"MarginContainer/VBoxContainer/Footer",
		"MarginContainer/VBoxContainer/ButtonRow",
		"MarginContainer/VBoxContainer/MainContent/RightPanel",
		"MarginContainer/VBoxContainer/HBoxContainer"
	]
	
	for p in __paths:
		if has_node(p):
			__footer_node = get_node(p)
			__footer_found = true
			break
	
	if __footer_node != null:
		# Hide or remove any existing Confirm/Back buttons to replace with our standard ones
		for c in __footer_node.get_children():
			if c is Button and (c.name.find("Confirm") >= 0 or c.name.find("Back") >= 0 or c.name.find("Finish") >= 0):
				c.hide()
				# Keep them hidden, we'll use our own
		
		var __hbox = HBoxContainer.new()
		__hbox.alignment = BoxContainer.ALIGNMENT_CENTER
		__hbox.add_theme_constant_override("separation", 20)
		__hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		var __back_btn = Button.new()
		__back_btn.text = "BACK"
		__back_btn.custom_minimum_size = Vector2(150, 45)
		var __b_style = StyleBoxFlat.new()
		__b_style.bg_color = Color(0.3, 0.3, 0.3)
		__b_style.set_corner_radius_all(6)
		__back_btn.add_theme_stylebox_override("normal", __b_style)
		__back_btn.pressed.connect(self._on_back_pressed)
		__hbox.add_child(__back_btn)
		
		var __finish_btn = Button.new()
		__finish_btn.text = "FINISH"
		__finish_btn.custom_minimum_size = Vector2(150, 45)
		var __f_style = StyleBoxFlat.new()
		__f_style.bg_color = Color(0.1, 0.6, 0.2)
		__f_style.set_corner_radius_all(6)
		__finish_btn.add_theme_stylebox_override("normal", __f_style)
		if self.has_method("_on_finish_pressed"):
			__finish_btn.pressed.connect(self._on_finish_pressed)
		__hbox.add_child(__finish_btn)
		
		__footer_node.add_child(__hbox)
	_setup_map()
	visibility_changed.connect(_on_visibility_changed)
	
	# Map Connections
	for area_name in areas.keys():
		var btn = area_list.get_node(area_name)
		btn.pressed.connect(func(): _on_area_pressed(area_name))
		btn.set_drag_forwarding(Callable(), _can_drop_data_on_area.bind(area_name), _drop_data_on_area.bind(area_name))
		
		# Add icons
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
		btn.add_theme_font_size_override("font_size", 12)

	confirm_button.pressed.connect(_on_confirm_pressed)
	clear_area_btn.pressed.connect(_on_clear_area_pressed)
	clear_area_btn.hide()
	
	info_btn.pressed.connect(func(): guide_panel.show())
	close_guide_btn.pressed.connect(func(): guide_panel.hide())
	_setup_guide_text()
	_setup_ui_styles()

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
	if GameState.final_layout_picky_facilities.is_empty() and not GameState.triggered_scenarios.has("final_layout_picky_vendors"):
		GameState.triggered_scenarios.append("final_layout_picky_vendors")
		var candidates = []
		for u in unified_items.keys():
			if unified_items[u]["type"] != "Stage":
				candidates.append(u)
		candidates.shuffle()
		if candidates.size() > 0:
			GameState.final_layout_picky_facilities[candidates[0]] = ""
		if candidates.size() > 1:
			GameState.final_layout_picky_facilities[candidates[1]] = ""
			
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
	
	if GameState.final_layout_picky_facilities.has(uid) and GameState.final_layout_picky_facilities[uid] == area_name:
		return false
	
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
	
	if GameState.final_layout_picky_facilities.has(uid):
		if GameState.final_layout_picky_facilities[uid] == area_name:
			return
		elif GameState.final_layout_picky_facilities[uid] == "":
			GameState.final_layout_picky_facilities[uid] = area_name
			_show_complaint_popup(unified_items[uid]["display_name"], area_name)
			return
		
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
		style.bg_color.a = 0.85
		style.border_width_left = 3
		style.border_width_top = 3
		style.border_width_right = 3
		style.border_width_bottom = 3
		style.border_color = get_item_color(first_item["type"])
		
		btn.text = area_name + "\n" + str(remaining_size) + "m² left\n" + \
				   assigned_text.strip_edges()
		btn.add_theme_font_size_override("font_size", 12)
	else:
		style.bg_color = Color(0.15, 0.18, 0.2, 0.4) # Semi-transparent
		style.border_width_left = 2
		style.border_width_top = 2
		style.border_width_right = 2
		style.border_width_bottom = 2
		style.border_color = Color(0.8, 0.3, 0.3, 0.8) # Reddish highlight
		btn.text = area_name + "\n(EMPTY)\n" + str(area_data["size_m2"]) + " m²"
		btn.add_theme_font_size_override("font_size", 12)
		
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

func _show_complaint_popup(vendor_name: String, area_name: String) -> void:
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.85)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 100
	
	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(700, 400)
	var p_style = StyleBoxFlat.new()
	p_style.bg_color = Color(0.1, 0.12, 0.18, 1.0)
	p_style.set_corner_radius_all(15)
	p_style.border_width_left = 6
	p_style.border_width_right = 6
	p_style.border_width_top = 6
	p_style.border_width_bottom = 6
	p_style.border_color = Color(0.9, 0.5, 0.2, 1.0)
	p_style.shadow_size = 30
	p_style.shadow_color = Color(0, 0, 0, 0.7)
	panel.add_theme_stylebox_override("panel", p_style)
	center.add_child(panel)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 40)
	margin.add_theme_constant_override("margin_right", 40)
	margin.add_theme_constant_override("margin_top", 40)
	margin.add_theme_constant_override("margin_bottom", 40)
	panel.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 25)
	margin.add_child(vbox)
	
	var title = Label.new()
	title.text = "⚠️ FACILITY COMPLAINT ⚠️"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 38)
	title.add_theme_color_override("font_color", Color(1.0, 0.6, 0.2))
	vbox.add_child(title)
	
	var sep = HSeparator.new()
	vbox.add_child(sep)
	
	var body = Label.new()
	body.text = "The facility '%s' has stated that they absolutely do not want to be placed in %s!\n\nThey requested you to change their location to a different zone." % [vendor_name, area_name]
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_size_override("font_size", 24)
	vbox.add_child(body)
	
	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)
	
	var btn = Button.new()
	btn.text = "ACKNOWLEDGE"
	btn.custom_minimum_size = Vector2(300, 65)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	
	var b_style = StyleBoxFlat.new()
	b_style.bg_color = Color(0.8, 0.4, 0.2)
	b_style.set_corner_radius_all(10)
	btn.add_theme_stylebox_override("normal", b_style)
	var b_hover = b_style.duplicate()
	b_hover.bg_color = Color(0.9, 0.5, 0.2)
	btn.add_theme_stylebox_override("hover", b_hover)
	btn.add_theme_font_size_override("font_size", 22)
	
	btn.pressed.connect(func():
		var out_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN)
		out_tween.tween_property(overlay, "modulate:a", 0.0, 0.2)
		out_tween.tween_property(panel, "scale", Vector2(0.8, 0.8), 0.2)
		out_tween.chain().tween_callback(func():
			overlay.queue_free()
		)
	)
	vbox.add_child(btn)
	
	overlay.modulate.a = 0.0
	panel.scale = Vector2(0.8, 0.8)
	var in_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	in_tween.tween_property(overlay, "modulate:a", 1.0, 0.4)
	in_tween.tween_property(panel, "scale", Vector2(1.0, 1.0), 0.4)
	
	add_child(overlay)

func _on_finish_pressed() -> void:
	_on_confirm_pressed()
