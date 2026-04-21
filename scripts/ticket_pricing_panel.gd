extends Control

# Strategic Pricing Options
var pricing_options = {
	"super_saver": {
		"display_name": "Super Saver / Early Bird",
		"desc": "Aggressive low pricing to fill the venue quickly. High energy, low margin.",
		"price": 250,
		"impact": 0.35,
		"quality": 0,
		"color": Color(0.4, 0.8, 0.4)
	},
	"student": {
		"display_name": "Student Promotion",
		"desc": "Targeted pricing for the core campus demographic. Balanced and fair.",
		"price": 380,
		"impact": 0.15,
		"quality": 1,
		"color": Color(0.2, 0.7, 0.9)
	},
	"standard": {
		"display_name": "Standard Access",
		"desc": "The market expected price. No surprises, steady attendance.",
		"price": 550,
		"impact": 0.0,
		"quality": 2,
		"color": Color(1.0, 1.0, 1.0)
	},
	"premium": {
		"display_name": "Premium Experience",
		"desc": "Higher price for a perceived quality boost and exclusive atmosphere.",
		"price": 950,
		"impact": -0.18,
		"quality": 4,
		"color": Color(0.9, 0.7, 0.2)
	},
	"elite": {
		"display_name": "Elite / VIP Tier",
		"desc": "Maximum margin. Targets a niche audience. Massive quality boost, limited crowd.",
		"price": 1600,
		"impact": -0.45,
		"quality": 6,
		"color": Color(0.8, 0.3, 0.9)
	}
}

@onready var pricing_list: VBoxContainer = $MarginContainer/VBoxContainer/ContentPanel/MarginContainer/DynamicContent/PricingList
@onready var summary_label: Label = $MarginContainer/VBoxContainer/SummaryPanel/Margin/VBoxContainer/SummaryLabel
@onready var confirm_button: Button = $MarginContainer/VBoxContainer/ButtonRow/ConfirmButton

@onready var consulting_panel: PanelContainer = $MarginContainer/VBoxContainer/ContentPanel/MarginContainer/DynamicContent/ConsultingPanel
@onready var purchase_consulting_btn: Button = $MarginContainer/VBoxContainer/ContentPanel/MarginContainer/DynamicContent/ConsultingPanel/Margin/HBox/PurchaseConsultingButton

@onready var info_popup: PanelContainer = $InfoPopup
@onready var info_button: Button = $MarginContainer/VBoxContainer/HeaderPanel/InfoButton
@onready var info_close: Button = $InfoPopup/Margin/VBox/Header/Close

var option_buttons: Array = []
var card_visuals: Dictionary = {}
var selected_id: String = ""

var normal_style: StyleBoxFlat
var hover_style: StyleBoxFlat
var selected_style: StyleBoxFlat

func _ready() -> void:
	confirm_button.pressed.connect(_on_confirm_pressed)
	info_button.pressed.connect(func(): info_popup.show())
	info_close.pressed.connect(func(): info_popup.hide())
	purchase_consulting_btn.pressed.connect(_on_purchase_consulting_pressed)
	info_popup.hide()
	
	_setup_styles()
	create_options()
	refresh_ui()

func _setup_styles() -> void:
	normal_style = StyleBoxFlat.new()
	normal_style.bg_color = Color(0.12, 0.15, 0.18, 0.6)
	normal_style.set_corner_radius_all(10)
	normal_style.border_width_left = 6
	normal_style.border_color = Color(0.4, 0.4, 0.4, 0.5)

	hover_style = StyleBoxFlat.new()
	hover_style.bg_color = Color(0.15, 0.18, 0.22, 0.8)
	hover_style.set_corner_radius_all(10)
	hover_style.border_width_left = 6
	hover_style.border_color = Color(0.6, 0.6, 0.6, 0.8)

	selected_style = StyleBoxFlat.new()
	selected_style.bg_color = Color(0.1, 0.3, 0.5, 0.8)
	selected_style.set_corner_radius_all(10)
	selected_style.border_width_left = 6
	selected_style.border_color = Color(0.3, 0.7, 1.0, 1.0)
	selected_style.shadow_color = Color(0.3, 0.7, 1.0, 0.2)
	selected_style.shadow_size = 15

func _on_purchase_consulting_pressed() -> void:
	if GameState.money >= GameState.TICKET_CONSULTING_COST:
		GameState.money -= GameState.TICKET_CONSULTING_COST
		GameState.ticket_consulting_purchased = true
		purchase_consulting_btn.disabled = true
		purchase_consulting_btn.text = "Consulting Active"
		create_options() # Re-create cards with precise info
		refresh_ui()
	else:
		purchase_consulting_btn.text = "Insufficient Funds!"

func create_options() -> void:
	for c in pricing_list.get_children():
		c.queue_free()
	option_buttons.clear()
	card_visuals.clear()

	for id in pricing_options.keys():
		var p = pricing_options[id]
		
		var card = PanelContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.add_theme_stylebox_override("panel", normal_style)
		card_visuals[id] = card
		
		var btn = Button.new()
		btn.flat = true
		btn.toggle_mode = true
		btn.set_meta("id", id)
		btn.mouse_entered.connect(_on_card_hovered.bind(id, true))
		btn.mouse_exited.connect(_on_card_hovered.bind(id, false))
		btn.toggled.connect(_on_card_toggled.bind(id))
		if GameState.ticket_pricing_completed:
			btn.disabled = true
			if GameState.chosen_ticket_price == p["price"]:
				btn.button_pressed = true
				selected_id = id
		option_buttons.append(btn)
		
		var margin = MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 20)
		margin.add_theme_constant_override("margin_top", 12)
		margin.add_theme_constant_override("margin_right", 20)
		margin.add_theme_constant_override("margin_bottom", 12)
		margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		var hbox = HBoxContainer.new()
		hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		margin.add_child(hbox)
		
		# Left: Title + Description
		var left_vbox = VBoxContainer.new()
		left_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		left_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		var title = Label.new()
		title.text = p["display_name"]
		title.add_theme_font_size_override("font_size", 22)
		title.add_theme_color_override("font_color", p["color"])
		
		var desc = Label.new()
		desc.text = p["desc"]
		desc.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc.custom_minimum_size.x = 400
		
		left_vbox.add_child(title)
		left_vbox.add_child(desc)
		hbox.add_child(left_vbox)
		
		# Right: Stats Panel
		var stats_grid = GridContainer.new()
		stats_grid.columns = 2
		stats_grid.add_theme_constant_override("h_separation", 30)
		stats_grid.size_flags_horizontal = Control.SIZE_SHRINK_END
		stats_grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		_add_stat(stats_grid, "Price:", str(p["price"]) + " TL", Color(0.9, 0.9, 0.9))
		
		var impact_color = Color(0.4, 0.8, 0.4) if p["impact"] >= 0 else Color(0.9, 0.4, 0.4)
		var impact_prefix = "+" if p["impact"] > 0 else ""
		
		var impact_text = ""
		if GameState.ticket_consulting_purchased:
			impact_text = impact_prefix + str(p["impact"] * 100) + "%"
		else:
			# Fuzzy range logic: Jitter of +/- 5%
			var low = (p["impact"] - 0.05) * 100
			var high = (p["impact"] + 0.05) * 100
			impact_text = str(int(low)) + "% ~ " + str(int(high)) + "%"
			
		_add_stat(stats_grid, "Attendance:", impact_text, impact_color)
		
		var stars = ""
		for i in range(p["quality"]): stars += "★"
		_add_stat(stats_grid, "Event Quality:", stars, Color(0.9, 0.7, 0.2))
		
		hbox.add_child(stats_grid)
		
		card.add_child(btn)
		card.add_child(margin)
		pricing_list.add_child(card)

func _add_stat(grid: GridContainer, label_text: String, value_text: String, color: Color) -> void:
	var lbl = Label.new()
	lbl.text = label_text
	lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	var val = Label.new()
	val.text = value_text
	val.add_theme_color_override("font_color", color)
	grid.add_child(lbl)
	grid.add_child(val)

func _on_card_hovered(id: String, is_hovered: bool) -> void:
	if selected_id == id: return
	var card = card_visuals[id]
	card.add_theme_stylebox_override("panel", hover_style if is_hovered else normal_style)

func _on_card_toggled(toggled_on: bool, id: String) -> void:
	if toggled_on:
		selected_id = id
		# Un-press others
		for btn in option_buttons:
			if btn.get_meta("id") != id:
				btn.set_pressed_no_signal(false)
				var other_id = btn.get_meta("id")
				card_visuals[other_id].add_theme_stylebox_override("panel", normal_style)
		
		card_visuals[id].add_theme_stylebox_override("panel", selected_style)
	else:
		if selected_id == id:
			selected_id = "" # Deselected
		card_visuals[id].add_theme_stylebox_override("panel", normal_style)
	
	refresh_ui()

func get_totals() -> Dictionary:
	var base_reach = GameState.promotion_total_actual_reach
	if base_reach <= 0.0: base_reach = 5000.0 #Fallback
	
	if selected_id == "":
		return {"selected": false, "attendance": base_reach, "price": 0, "revenue": 0, "quality": 0}
		
	var p = pricing_options[selected_id]
	var adj_attendance = base_reach * (1.0 + p["impact"])
	var revenue = adj_attendance * p["price"]
	
	# Fuzzy totals for UI if not consulting
	var fuzzy_att_low = base_reach * (1.0 + p["impact"] - 0.05)
	var fuzzy_att_high = base_reach * (1.0 + p["impact"] + 0.05)
	var fuzzy_rev_low = fuzzy_att_low * p["price"]
	var fuzzy_rev_high = fuzzy_att_high * p["price"]
	
	return {
		"selected": true,
		"id": selected_id,
		"attendance": int(adj_attendance),
		"price": p["price"],
		"revenue": int(revenue),
		"quality": p["quality"],
		"fuzzy_att": [int(fuzzy_att_low), int(fuzzy_att_high)],
		"fuzzy_rev": [int(fuzzy_rev_low), int(fuzzy_rev_high)]
	}

func refresh_ui() -> void:
	if GameState.ticket_consulting_purchased:
		purchase_consulting_btn.text = "Consulting Active"
		purchase_consulting_btn.disabled = true
	else:
		purchase_consulting_btn.text = "Purchase Consulting (" + str(GameState.TICKET_CONSULTING_COST) + " TL)"
		purchase_consulting_btn.disabled = false
	
	var data = get_totals()
	if data["selected"]:
		if GameState.ticket_consulting_purchased:
			summary_label.text = "Estimated Attendance: " + str(data["attendance"]) + "   |   Projected Revenue: " + str(data["revenue"]) + " TL"
		else:
			summary_label.text = "Estimated Attendance: " + str(data["fuzzy_att"][0]) + "~" + str(data["fuzzy_att"][1]) + "   |   Projected Revenue: ~" + str(data["fuzzy_rev"][0] / 1000) + "K-" + str(data["fuzzy_rev"][1] / 1000) + "K TL"
		confirm_button.disabled = false
	else:
		summary_label.text = "Select a pricing strategy to see technical projections..."
		confirm_button.disabled = true
		
	if GameState.ticket_pricing_completed:
		confirm_button.text = "Back to Board"
		confirm_button.disabled = false
		consulting_panel.hide()

func _on_confirm_pressed() -> void:
	if GameState.ticket_pricing_completed:
		go_back()
		return
		
	var data = get_totals()
	if not data["selected"]: return
		
	GameState.finalize_ticket_pricing(data["attendance"], data["price"], data["revenue"], data["quality"])
	go_back()

func go_back() -> void:
	hide()
	get_parent().get_node("ActivityBoard").show()
	get_parent().get_node("ActivityBoard").refresh_board()
