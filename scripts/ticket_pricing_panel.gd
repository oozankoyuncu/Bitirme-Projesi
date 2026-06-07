extends Control

# Strategic Pricing Options
var pricing_options = {
	"ticket_0": {
		"display_name": "Ticket – 0",
		"desc": "Free entry to maximize attendance. No revenue from tickets.",
		"price": 0,
		"impact": 0.30,
		"quality": 1,
		"color": Color(0.4, 0.9, 0.4)
	},
	"ticket_50": {
		"display_name": "Ticket – 50",
		"desc": "Minimal pricing to attract the widest audience possible.",
		"price": 50,
		"impact": 0.30,
		"quality": 1,
		"color": Color(0.4, 0.8, 0.4)
	},
	"ticket_100": {
		"display_name": "Ticket – 100",
		"desc": "Low-cost entry that still boosts attendance significantly.",
		"price": 100,
		"impact": 0.30,
		"quality": 2,
		"color": Color(0.3, 0.8, 0.6)
	},
	"ticket_150": {
		"display_name": "Ticket – 150",
		"desc": "Affordable pricing with moderate attendance growth.",
		"price": 150,
		"impact": 0.10,
		"quality": 2,
		"color": Color(0.2, 0.7, 0.9)
	},
	"ticket_200": {
		"display_name": "Ticket – 200",
		"desc": "Balanced pricing that maintains steady attendance.",
		"price": 200,
		"impact": 0.10,
		"quality": 3,
		"color": Color(0.3, 0.6, 1.0)
	},
	"ticket_250": {
		"display_name": "Ticket – 250",
		"desc": "Mid-range pricing with moderate attendance and quality.",
		"price": 250,
		"impact": 0.10,
		"quality": 3,
		"color": Color(1.0, 1.0, 1.0)
	},
	"ticket_300": {
		"display_name": "Ticket – 300",
		"desc": "Higher pricing that reduces attendance but increases perceived value.",
		"price": 300,
		"impact": -0.25,
		"quality": 4,
		"color": Color(0.9, 0.8, 0.2)
	},
	"ticket_350": {
		"display_name": "Ticket – 350",
		"desc": "Premium pricing targeting a quality-focused audience.",
		"price": 350,
		"impact": -0.25,
		"quality": 4,
		"color": Color(0.9, 0.7, 0.2)
	},
	"ticket_400": {
		"display_name": "Ticket – 400",
		"desc": "High-end pricing for an exclusive festival experience.",
		"price": 400,
		"impact": -0.25,
		"quality": 5,
		"color": Color(0.9, 0.5, 0.2)
	},
	"ticket_450": {
		"display_name": "Ticket – 450",
		"desc": "Maximum pricing for the most exclusive experience. Limited crowd.",
		"price": 450,
		"impact": -0.25,
		"quality": 5,
		"color": Color(0.8, 0.3, 0.9)
	}
}

@onready var pricing_list: VBoxContainer = $MarginContainer/VBoxContainer/ContentPanel/MarginContainer/DynamicContent/PricingList
@onready var summary_label: Label = $MarginContainer/VBoxContainer/SummaryPanel/Margin/VBoxContainer/SummaryLabel
@onready var confirm_button: Button = $MarginContainer/VBoxContainer/ButtonRow/ConfirmButton

@onready var consulting_panel: PanelContainer = $MarginContainer/VBoxContainer/ContentPanel/MarginContainer/DynamicContent/ConsultingPanel
# @onready var purchase_consulting_btn: Button = ... (removed)

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
	confirm_button.pressed.connect(_on_confirm_pressed)
	info_button.pressed.connect(func(): info_popup.show())
	info_close.pressed.connect(func(): info_popup.hide())
	info_popup.hide()
	
	if consulting_panel:
		consulting_panel.hide()
	
	# Wrap PricingList in a ScrollContainer so all options are scrollable
	_wrap_pricing_list_in_scroll()
	
	_setup_styles()
	create_options()
	refresh_ui()
	
	self.visibility_changed.connect(_on_visibility_changed)

var _popup_timer_started = false
func _on_visibility_changed() -> void:
	if is_visible_in_tree() and not GameState.ticket_pricing_completed and not GameState.ticket_consulting_purchased and not _popup_timer_started:
		_popup_timer_started = true
		_start_popup_timer()

func _start_popup_timer() -> void:
	await get_tree().create_timer(2.0).timeout
	if not is_inside_tree() or not is_visible_in_tree() or GameState.ticket_consulting_purchased:
		return
	_show_intelligence_popup()

func _show_intelligence_popup() -> void:
	var dialog = ConfirmationDialog.new()
	dialog.title = "Consulting Intelligence Service"
	dialog.dialog_text = "Would you like to purchase intelligence data to see Event Quality stars and exact Attendance impacts?\nCost: 10000 TL"
	dialog.ok_button_text = "Yes (Pay 10000 TL)"
	dialog.cancel_button_text = "No"
	
	dialog.min_size = Vector2(650, 200)
	var lbl = dialog.get_label()
	if lbl:
		lbl.add_theme_font_size_override("font_size", 20)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	dialog.get_ok_button().add_theme_font_size_override("font_size", 18)
	dialog.get_ok_button().custom_minimum_size = Vector2(180, 50)
	dialog.get_cancel_button().add_theme_font_size_override("font_size", 18)
	dialog.get_cancel_button().custom_minimum_size = Vector2(100, 50)
	
	dialog.confirmed.connect(func():
		if GameState.money >= 10000:
			GameState.money -= 10000
			GameState.ticket_consulting_purchased = true
			refresh_ui()
			create_options()
	)
	
	add_child(dialog)
	dialog.popup_centered()

func _wrap_pricing_list_in_scroll() -> void:
	var parent = pricing_list.get_parent()
	if not parent:
		return
	
	var scroll = ScrollContainer.new()
	scroll.name = "PricingScrollContainer"
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	
	var idx = pricing_list.get_index()
	parent.remove_child(pricing_list)
	parent.add_child(scroll)
	parent.move_child(scroll, idx)
	
	scroll.add_child(pricing_list)
	pricing_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL

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
	pass # Deprecated

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
				selected_id = id
		
		# Restore selection visually
		if selected_id == id:
			btn.set_pressed_no_signal(true)
			card.add_theme_stylebox_override("panel", selected_style)
			
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
		title.add_theme_font_size_override("font_size", 26)
		title.add_theme_color_override("font_color", p["color"])
		
		var desc = Label.new()
		desc.text = p["desc"]
		desc.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		desc.add_theme_font_size_override("font_size", 18)
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
		if GameState.ticket_consulting_purchased:
			for i in range(p["quality"]): stars += "★"
		else:
			stars = "?"
			
		_add_stat(stats_grid, "Event Quality:", stars, Color(0.9, 0.7, 0.2))
		
		hbox.add_child(stats_grid)
		
		card.add_child(btn)
		card.add_child(margin)
		pricing_list.add_child(card)

func _add_stat(grid: GridContainer, label_text: String, value_text: String, color: Color) -> void:
	var lbl = Label.new()
	lbl.text = label_text
	lbl.custom_minimum_size = Vector2(130, 0) # Fixed width for left alignment
	lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	lbl.add_theme_font_size_override("font_size", 20)
	
	var val = Label.new()
	val.text = value_text
	val.custom_minimum_size = Vector2(130, 0) # Fixed width for left alignment
	val.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	val.add_theme_color_override("font_color", color)
	val.add_theme_font_size_override("font_size", 20)
	
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
		
		if GameState.active_scenarios.has("rival_free_festival") and not GameState.triggered_scenarios.has("rival_free_festival"):
			GameState.triggered_scenarios.append("rival_free_festival")
			for m in GameState.selected_team:
				m["reliability"] = max(1.0, m.get("reliability", 3.0) - 1.0)
			
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
			p_style.border_color = Color(0.9, 0.4, 0.3, 1.0)
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
			title.text = "🚨 RIVAL FESTIVAL DETECTED 🚨"
			title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			title.add_theme_font_size_override("font_size", 38)
			title.add_theme_color_override("font_color", Color(1.0, 0.4, 0.3))
			vbox.add_child(title)
			
			var sep = HSeparator.new()
			vbox.add_child(sep)
			
			var body = Label.new()
			body.text = "Team Member: A rival university is hosting a free festival on the exact same day!\nOur team's reliability has dropped due to stress, which decreases our expected ticket demand.\n\nYou might want to rethink your pricing strategy."
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
			b_style.bg_color = Color(0.8, 0.3, 0.2)
			b_style.set_corner_radius_all(10)
			btn.add_theme_stylebox_override("normal", b_style)
			var b_hover = b_style.duplicate()
			b_hover.bg_color = Color(0.9, 0.4, 0.3)
			btn.add_theme_stylebox_override("hover", b_hover)
			btn.add_theme_font_size_override("font_size", 22)
			
			btn.pressed.connect(func():
				var out_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN)
				out_tween.tween_property(overlay, "modulate:a", 0.0, 0.2)
				out_tween.tween_property(panel, "scale", Vector2(0.8, 0.8), 0.2)
				out_tween.chain().tween_callback(func():
					overlay.queue_free()
					refresh_ui()
				)
			)
			vbox.add_child(btn)
			
			overlay.modulate.a = 0.0
			panel.scale = Vector2(0.8, 0.8)
			var in_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
			in_tween.tween_property(overlay, "modulate:a", 1.0, 0.4)
			in_tween.tween_property(panel, "scale", Vector2(1.0, 1.0), 0.4)
			
			add_child(overlay)
	else:
		if selected_id == id:
			selected_id = "" # Deselected
		card_visuals[id].add_theme_stylebox_override("panel", normal_style)
	
	refresh_ui()

func get_totals() -> Dictionary:
	var base_reach = GameState.promotion_total_actual_reach
	if base_reach <= 0.0: base_reach = 5000.0 #Fallback
	
	var team_reliability = 3.0
	if GameState.selected_team.size() > 0:
		var total_rel = 0.0
		for m in GameState.selected_team:
			total_rel += m.get("reliability", 3.0)
		team_reliability = total_rel / GameState.selected_team.size()
		
	var reliability_factor = team_reliability / 3.0
	
	if selected_id == "":
		return {"selected": false, "attendance": base_reach * reliability_factor, "price": 0, "revenue": 0, "quality": 0}
		
	var p = pricing_options[selected_id]
	var adj_attendance = base_reach * (1.0 + p["impact"]) * reliability_factor
	var revenue = adj_attendance * p["price"]
	
	# Fuzzy totals for UI if not consulting
	var fuzzy_att_low = base_reach * (1.0 + p["impact"] - 0.05) * reliability_factor
	var fuzzy_att_high = base_reach * (1.0 + p["impact"] + 0.05) * reliability_factor
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
	# purchase_consulting_btn logic removed
	
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

func _on_back_pressed() -> void:
	go_back()

func _on_finish_pressed() -> void:
	_on_confirm_pressed()
