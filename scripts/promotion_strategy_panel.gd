extends Control

# Data structure expanded to 5 options according to objectives
var promotion_options = {
	"posters": {
		"display_name": "Campus Posters & Flyers",
		"desc": "Low cost, traditional method. Highly visible on campus but easy to ignore.",
		"cost": 800,
		"expected_reach": 1500,
		"reliability": 0.6
	},
	"social_media": {
		"display_name": "Targeted Social Media Ads",
		"desc": "Uses algorithms to target student demographics on popular platforms.",
		"cost": 2500,
		"expected_reach": 3500,
		"reliability": 0.82
	},
	"radio_podcast": {
		"display_name": "Local Radio & Podcasts",
		"desc": "Sponsorship spots on local youth stations and campus podcasts.",
		"cost": 3000,
		"expected_reach": 4200,
		"reliability": 0.7
	},
	"pr_press": {
		"display_name": "Traditional Media (PR & Press)",
		"desc": "Press releases and articles in local newspapers and news portals.",
		"cost": 4500,
		"expected_reach": 5500,
		"reliability": 0.85
	},
	"influencers": {
		"display_name": "Influencer Partnerships",
		"desc": "Collaboration with local social media personalities. Massive potential audience.",
		"cost": 6500,
		"expected_reach": 9000,
		"reliability": 0.65
	}
}

@onready var promotion_list: VBoxContainer = $MarginContainer/VBoxContainer/ContentPanel/MarginContainer/PromotionList
@onready var budget_label: Label = $MarginContainer/VBoxContainer/HeaderPanel/Margin/VBoxContainer/BudgetLabel
@onready var summary_label: Label = $MarginContainer/VBoxContainer/SummaryPanel/Margin/VBoxContainer/SummaryLabel
@onready var confirm_button: Button = $MarginContainer/VBoxContainer/ButtonRow/ConfirmButton
@onready var back_button: Button = $MarginContainer/VBoxContainer/ButtonRow/BackButton
@onready var finish_button: Button = $MarginContainer/VBoxContainer/ButtonRow/FinishButton

@onready var info_popup: PanelContainer = $InfoPopup
@onready var info_button: Button = $MarginContainer/VBoxContainer/HeaderPanel/InfoButton
@onready var info_close: Button = $InfoPopup/Margin/VBox/TopBox/CloseInfoButton


var option_buttons: Array = []
var card_visuals: Dictionary = {}
var secret_nodes: Array = []

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
	
	_setup_styles()
	create_options()
	refresh_ui()
	
	self.visibility_changed.connect(_on_visibility_changed)

var _popup_timer_started = false
func _on_visibility_changed() -> void:
	if is_visible_in_tree() and not GameState.promotion_phase_completed and not GameState.promotion_intelligence_bought and not _popup_timer_started:
		_popup_timer_started = true
		_start_popup_timer()

func _start_popup_timer() -> void:
	await get_tree().create_timer(2.0).timeout
	if not is_inside_tree() or not is_visible_in_tree() or GameState.promotion_intelligence_bought:
		return
	_show_intelligence_popup()

func _show_intelligence_popup() -> void:
	var dialog = ConfirmationDialog.new()
	dialog.title = "Consulting Intelligence Service"
	dialog.dialog_text = "Would you like to purchase intelligence data to see the Effectiveness score and Actual Impact estimates?\nCost: 10000 TL"
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
			GameState.promotion_intelligence_bought = true
			refresh_ui()
			_reveal_intelligence()
	)
	
	add_child(dialog)
	dialog.popup_centered()

func _reveal_intelligence() -> void:
	for node in secret_nodes:
		if is_instance_valid(node):
			node.visible = true
	refresh_ui()

func _setup_styles() -> void:
	# General Panel Style
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.05, 0.07, 0.1, 0.85)
	add_theme_stylebox_override("panel", bg_style)

	# Card Styles
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
	selected_style.bg_color = Color(0.1, 0.25, 0.4, 0.8)
	selected_style.set_corner_radius_all(10)
	selected_style.border_width_left = 6
	selected_style.border_color = Color(0.2, 0.6, 1.0, 1.0)
	selected_style.shadow_color = Color(0.2, 0.6, 1.0, 0.2)
	selected_style.shadow_size = 15

func create_options() -> void:
	for c in promotion_list.get_children():
		c.queue_free()
	option_buttons.clear()
	card_visuals.clear()
	secret_nodes.clear()

	for id in promotion_options.keys():
		var p = promotion_options[id]
		var expected = p["expected_reach"]
		var rel = p["reliability"]
		var actual = int(expected * rel)
		var efficiency = float(actual) / float(p["cost"]) * 10.0 # Multiplier for visual scale

		# Main Card Container
		var card = PanelContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.add_theme_stylebox_override("panel", normal_style)
		card_visuals[id] = card
		
		# Overlay button for clicking the entire card
		var btn = Button.new()
		btn.flat = true
		btn.toggle_mode = true
		btn.set_meta("id", id)
		btn.mouse_entered.connect(_on_card_hovered.bind(id, true))
		btn.mouse_exited.connect(_on_card_hovered.bind(id, false))
		btn.toggled.connect(_on_card_toggled.bind(id))
		if GameState.promotion_phase_completed:
			btn.disabled = true
		option_buttons.append(btn)
		
		var margin = MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 20)
		margin.add_theme_constant_override("margin_top", 15)
		margin.add_theme_constant_override("margin_right", 20)
		margin.add_theme_constant_override("margin_bottom", 15)
		margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		# Card Layout
		var hbox = HBoxContainer.new()
		hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		margin.add_child(hbox)
		
		# Left: Checkbox Icon + Text
		var left_vbox = VBoxContainer.new()
		left_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		left_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		var title_hbox = HBoxContainer.new()
		title_hbox.add_theme_constant_override("separation", 15)
		var checkbox_placeholder = Label.new() # Can use icon here later
		checkbox_placeholder.text = "〇"
		checkbox_placeholder.add_theme_font_size_override("font_size", 24)
		checkbox_placeholder.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		btn.set_meta("cb_label", checkbox_placeholder)
		
		var title = Label.new()
		title.text = p["display_name"]
		title.add_theme_font_size_override("font_size", 22)
		title.add_theme_color_override("font_color", Color.WHITE)
		
		var ef_label = Label.new()
		ef_label.text = "  (Eff: " + str(snapped(efficiency, 0.01)) + ")"
		ef_label.add_theme_font_size_override("font_size", 20)
		ef_label.add_theme_color_override("font_color", Color(0.4, 0.8, 0.4))
		
		title_hbox.add_child(checkbox_placeholder)
		title_hbox.add_child(title)
		title_hbox.add_child(ef_label)
		
		var desc = Label.new()
		desc.text = p["desc"]
		desc.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc.custom_minimum_size.x = 400
		
		left_vbox.add_child(title_hbox)
		left_vbox.add_child(desc)
		hbox.add_child(left_vbox)
		
		# Right: Stats Grid
		var stats_grid = GridContainer.new()
		stats_grid.columns = 2
		stats_grid.add_theme_constant_override("h_separation", 30)
		stats_grid.size_flags_horizontal = Control.SIZE_SHRINK_END
		stats_grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		var lbl_cost = Label.new()
		lbl_cost.text = "Cost:"
		lbl_cost.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
		lbl_cost.custom_minimum_size = Vector2(140, 0)
		var val_cost = Label.new()
		val_cost.text = str(p["cost"]) + " TL"
		val_cost.add_theme_color_override("font_color", Color(0.9, 0.4, 0.4))
		val_cost.custom_minimum_size = Vector2(160, 0)
		
		var lbl_reach = Label.new()
		lbl_reach.text = "Expected Reach:"
		lbl_reach.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
		lbl_reach.custom_minimum_size = Vector2(140, 0)
		var val_reach = Label.new()
		val_reach.text = str(expected)
		val_reach.custom_minimum_size = Vector2(160, 0)
		
		var lbl_rel = Label.new()
		lbl_rel.text = "Reliability:"
		lbl_rel.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
		lbl_rel.custom_minimum_size = Vector2(140, 0)
		var val_rel = Label.new()
		val_rel.text = str(rel * 100) + "%"
		val_rel.custom_minimum_size = Vector2(160, 0)
		
		var lbl_act = Label.new()
		lbl_act.text = "Actual Impact:"
		lbl_act.add_theme_color_override("font_color", Color(0.4, 0.8, 0.4))
		lbl_act.custom_minimum_size = Vector2(140, 0)
		var val_act = Label.new()
		val_act.text = "≈ " + str(actual) + " attendees"
		val_act.add_theme_color_override("font_color", Color(0.4, 0.8, 0.4))
		val_act.custom_minimum_size = Vector2(160, 0)

		if not GameState.promotion_intelligence_bought:
			ef_label.visible = false
			lbl_act.visible = false
			val_act.visible = false
			
		secret_nodes.append(ef_label)
		secret_nodes.append(lbl_act)
		secret_nodes.append(val_act)
		
		stats_grid.add_child(lbl_cost); stats_grid.add_child(val_cost)
		stats_grid.add_child(lbl_reach); stats_grid.add_child(val_reach)
		stats_grid.add_child(lbl_rel); stats_grid.add_child(val_rel)
		stats_grid.add_child(lbl_act); stats_grid.add_child(val_act)
		
		hbox.add_child(stats_grid)
		
		# Assemble
		card.add_child(btn)
		card.add_child(margin)
		promotion_list.add_child(card)

func _on_card_hovered(id: String, is_hovered: bool) -> void:
	var btn = _get_button(id)
	if btn and btn.button_pressed: return # Don't change hover state if selected
	
	var card = card_visuals[id]
	if is_hovered:
		card.add_theme_stylebox_override("panel", hover_style)
	else:
		card.add_theme_stylebox_override("panel", normal_style)

func _on_card_toggled(toggled_on: bool, id: String) -> void:
	var btn = _get_button(id)
	var card = card_visuals[id]
	var cb_label = btn.get_meta("cb_label")
	
	if toggled_on:
		card.add_theme_stylebox_override("panel", selected_style)
		cb_label.text = "☑"
		cb_label.add_theme_color_override("font_color", Color(0.2, 0.6, 1.0))
	else:
		if btn.is_hovered():
			card.add_theme_stylebox_override("panel", hover_style)
		else:
			card.add_theme_stylebox_override("panel", normal_style)
		cb_label.text = "〇"
		cb_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		
	refresh_ui()

func _get_button(id: String) -> Button:
	for b in option_buttons:
		if b.get_meta("id") == id: return b
	return null

func get_totals() -> Dictionary:
	var total_cost: int = 0
	var total_actual_reach: float = 0.0
	var selected_ids: Array = []
	
	for btn in option_buttons:
		if btn.button_pressed:
			var id = btn.get_meta("id")
			selected_ids.append(id)
			total_cost += promotion_options[id]["cost"]
			total_actual_reach += promotion_options[id]["expected_reach"] * promotion_options[id]["reliability"]

	return {
		"cost": total_cost,
		"reach": int(total_actual_reach),
		"selected": selected_ids
	}

func refresh_ui() -> void:
	var data = get_totals()
	budget_label.text = "Current Budget: " + str(GameState.money) + " TL"
	
	if GameState.promotion_intelligence_bought:
		summary_label.text = "Total Investment: " + str(data["cost"]) + " TL     |     Combined Reach Impact: ≈" + str(data["reach"]) + " attendees"
	else:
		summary_label.text = "Total Investment: " + str(data["cost"]) + " TL     |     Combined Reach Impact: ???"
	
	if GameState.promotion_phase_completed:
		confirm_button.text = "Back to Module Overview"
		confirm_button.disabled = false
	else:
		confirm_button.text = "Confirm Strategy"
		if GameState.money - data["cost"] < GameState.university_debt_limit:
			confirm_button.disabled = true
			summary_label.text += "\n[Cannot afford! Over debt limit]"
		else:
			confirm_button.disabled = false

func _on_confirm_pressed() -> void:
	if GameState.promotion_phase_completed:
		go_back()
		return
		
	var data = get_totals()
	if GameState.money - data["cost"] < GameState.university_debt_limit:
		return
		
	GameState.finalize_promotion_strategy(data["selected"], data["cost"], data["reach"])
	go_back()

func go_back() -> void:
	hide()
	get_parent().get_node("ActivityBoard").show()
	get_parent().get_node("ActivityBoard").refresh_board()

func _on_back_pressed() -> void:
	go_back()

func _on_finish_pressed() -> void:
	_on_confirm_pressed()
