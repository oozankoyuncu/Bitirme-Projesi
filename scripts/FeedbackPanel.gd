extends Control

# ── Dynamic UI references ──────────────────────────────────────────────
var _ofs_status_container: HBoxContainer
var _ofs_feedback_label: Label
var _outcome_table_container: VBoxContainer
var _kpi_scroll_content: VBoxContainer
var _scroll_container: ScrollContainer
var _overlay: ColorRect
var _main_margin: MarginContainer

# ── Palette ────────────────────────────────────────────────────────────
const COLOR_BG_OVERLAY      := Color(0.02, 0.03, 0.05, 0.98)
const COLOR_CARD_BG          := Color(0.06, 0.08, 0.12, 0.95)
const COLOR_EMERALD          := Color(0.2, 0.9, 0.5)
const COLOR_EMERALD_DARK     := Color(0.12, 0.45, 0.28)
const COLOR_TEXT_PRIMARY     := Color(0.92, 0.94, 0.96)
const COLOR_TEXT_SECONDARY   := Color(0.6, 0.64, 0.7)
const COLOR_TEXT_DIM          := Color(0.45, 0.48, 0.54)
const COLOR_DIVIDER          := Color(0.15, 0.17, 0.22, 0.8)
const COLOR_CARD_BORDER      := Color(0.12, 0.14, 0.2, 0.6)
const COLOR_SCORE_GREEN      := Color(0.2, 0.9, 0.4)
const COLOR_SCORE_YELLOW     := Color(0.9, 0.8, 0.2)
const COLOR_SCORE_ORANGE     := Color(0.9, 0.5, 0.2)
const COLOR_SCORE_RED        := Color(0.9, 0.2, 0.2)
const COLOR_MET_GREEN        := Color(0.3, 0.85, 0.45)
const COLOR_UNMET_RED        := Color(0.9, 0.3, 0.3)
const COLOR_BAR_BG           := Color(0.1, 0.12, 0.18)

# ── KPI display order & labels ─────────────────────────────────────────
const KPI_ORDER := ["ps", "eq", "sa", "bc", "tm", "sp"]
const KPI_NAMES := {
	"ps": "Participant Satisfaction",
	"eq": "Event Quality",
	"sa": "Scope Adherence",
	"bc": "Budget Control",
	"tm": "Time Management",
	"sp": "Scenario Preparedness",
}

# ── Tween bookkeeping ─────────────────────────────────────────────────
var _active_tweens: Array[Tween] = []


# ═══════════════════════════════════════════════════════════════════════
#  LIFECYCLE
# ═══════════════════════════════════════════════════════════════════════

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	_build_ui()


# ═══════════════════════════════════════════════════════════════════════
#  PUBLIC API
# ═══════════════════════════════════════════════════════════════════════

func show_results(results: Dictionary) -> void:
	# Kill any leftover tweens
	for tw in _active_tweens:
		if tw and tw.is_valid():
			tw.kill()
	_active_tweens.clear()

	_populate_header(results)
	_populate_outcome_table(results)
	_populate_kpi_sections(results)

	# Entrance animation
	modulate = Color(1, 1, 1, 0)
	visible = true
	var tw := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.3)
	_active_tweens.append(tw)


# ═══════════════════════════════════════════════════════════════════════
#  UI CONSTRUCTION
# ═══════════════════════════════════════════════════════════════════════

func _build_ui() -> void:
	# ── Full-screen dark overlay ──
	_overlay = ColorRect.new()
	_overlay.color = COLOR_BG_OVERLAY
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_overlay)

	# ── Root margin container ──
	_main_margin = MarginContainer.new()
	_main_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_main_margin.add_theme_constant_override("margin_left", 40)
	_main_margin.add_theme_constant_override("margin_right", 40)
	_main_margin.add_theme_constant_override("margin_top", 40)
	_main_margin.add_theme_constant_override("margin_bottom", 40)
	add_child(_main_margin)

	var root_vbox := VBoxContainer.new()
	root_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_vbox.add_theme_constant_override("separation", 20)
	_main_margin.add_child(root_vbox)

	# ── 1. Header ──
	var header := _build_header()
	root_vbox.add_child(header)

	# ── 2. Scroll container ──
	_scroll_container = ScrollContainer.new()
	_scroll_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root_vbox.add_child(_scroll_container)

	_kpi_scroll_content = VBoxContainer.new()
	_kpi_scroll_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_kpi_scroll_content.add_theme_constant_override("separation", 20)
	_scroll_container.add_child(_kpi_scroll_content)

	# ── 3. Footer ──
	var footer := _build_footer()
	root_vbox.add_child(footer)


# ── Header ─────────────────────────────────────────────────────────────

func _build_header() -> VBoxContainer:
	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 10)

	# Title
	var title := Label.new()
	title.text = "FESTIVAL EVALUATION REPORT"
	title.add_theme_font_size_override("font_size", 42)
	title.add_theme_color_override("font_color", COLOR_EMERALD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	# Divider
	vbox.add_child(_make_divider())

	# Score row
	var score_row := HBoxContainer.new()
	score_row.alignment = BoxContainer.ALIGNMENT_CENTER
	score_row.add_theme_constant_override("separation", 16)
	vbox.add_child(score_row)

	_ofs_status_container = HBoxContainer.new()
	score_row.add_child(_ofs_status_container)

	# Feedback
	_ofs_feedback_label = Label.new()
	_ofs_feedback_label.text = ""
	_ofs_feedback_label.add_theme_font_size_override("font_size", 22)
	_ofs_feedback_label.add_theme_color_override("font_color", COLOR_TEXT_SECONDARY)
	_ofs_feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ofs_feedback_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_ofs_feedback_label)

	# Divider
	vbox.add_child(_make_divider())

	# Outcome table
	_outcome_table_container = VBoxContainer.new()
	_outcome_table_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_outcome_table_container.add_theme_constant_override("separation", 6)
	vbox.add_child(_outcome_table_container)

	# Divider
	vbox.add_child(_make_divider())

	return vbox


# ── Footer ─────────────────────────────────────────────────────────────

func _build_footer() -> CenterContainer:
	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var btn := Button.new()
	btn.text = "Return to Main Menu"
	btn.custom_minimum_size = Vector2(400, 70)
	btn.add_theme_font_size_override("font_size", 24)

	var btn_style := StyleBoxFlat.new()
	btn_style.bg_color = COLOR_EMERALD_DARK
	btn_style.corner_radius_top_left = 10
	btn_style.corner_radius_top_right = 10
	btn_style.corner_radius_bottom_left = 10
	btn_style.corner_radius_bottom_right = 10
	btn_style.content_margin_left = 24
	btn_style.content_margin_right = 24
	btn_style.content_margin_top = 12
	btn_style.content_margin_bottom = 12
	btn.add_theme_stylebox_override("normal", btn_style)

	var btn_hover := btn_style.duplicate()
	btn_hover.bg_color = COLOR_EMERALD.darkened(0.15)
	btn.add_theme_stylebox_override("hover", btn_hover)

	var btn_pressed := btn_style.duplicate()
	btn_pressed.bg_color = COLOR_EMERALD.darkened(0.35)
	btn.add_theme_stylebox_override("pressed", btn_pressed)

	btn.add_theme_color_override("font_color", COLOR_TEXT_PRIMARY)
	btn.add_theme_color_override("font_hover_color", Color.WHITE)
	btn.pressed.connect(_on_return_pressed)
	center.add_child(btn)
	return center


# ═══════════════════════════════════════════════════════════════════════
#  POPULATING DATA
# ═══════════════════════════════════════════════════════════════════════

func _populate_header(results: Dictionary) -> void:
	var ofs: Dictionary = results.get("ofs", {})
	var status: String = ofs.get("status", "")
	var feedback: String = ofs.get("feedback", "")

	# Clear old badge
	for c in _ofs_status_container.get_children():
		c.queue_free()
	_ofs_status_container.add_child(_make_status_badge(status))

	_ofs_feedback_label.text = feedback


func _populate_outcome_table(results: Dictionary) -> void:
	# Clear
	for c in _outcome_table_container.get_children():
		c.queue_free()

	# Table header row
	_outcome_table_container.add_child(_make_outcome_header_row())

	var keys := ["ps", "eq", "ofs"]
	var labels := {
		"ps": "Participant Satisfaction",
		"eq": "Event Quality",
		"ofs": "Overall Festival Success",
	}

	for key in keys:
		var data: Dictionary = results.get(key, {})
		var row := _make_outcome_row(
			labels[key],
			data.get("score", 0.0),
			data.get("status", "")
		)
		_outcome_table_container.add_child(row)


func _populate_kpi_sections(results: Dictionary) -> void:
	# Clear old cards
	for c in _kpi_scroll_content.get_children():
		c.queue_free()

	for key in KPI_ORDER:
		var data: Dictionary = results.get(key, {})
		if data.is_empty():
			continue
		var card := _build_kpi_card(key, data)
		_kpi_scroll_content.add_child(card)


# ═══════════════════════════════════════════════════════════════════════
#  KPI CARD BUILDER
# ═══════════════════════════════════════════════════════════════════════

func _build_kpi_card(key: String, data: Dictionary) -> PanelContainer:
	var score: float = data.get("score", 0.0)
	var status: String = data.get("status", "")
	var feedback: String = data.get("feedback", "")

	# ── Card panel ──
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var card_style := StyleBoxFlat.new()
	card_style.bg_color = COLOR_CARD_BG
	card_style.corner_radius_top_left = 10
	card_style.corner_radius_top_right = 10
	card_style.corner_radius_bottom_left = 10
	card_style.corner_radius_bottom_right = 10
	card_style.content_margin_left = 20
	card_style.content_margin_right = 20
	card_style.content_margin_top = 20
	card_style.content_margin_bottom = 20
	# Left accent border
	card_style.border_width_left = 4
	card_style.border_color = _get_score_color(score)
	# Subtle outer border
	card_style.border_width_top = 1
	card_style.border_width_right = 1
	card_style.border_width_bottom = 1
	card_style.set_border_color(Color(card_style.border_color.r, card_style.border_color.g, card_style.border_color.b, 0.3))
	card_style.border_width_left = 4
	card_style.set_corner_radius_all(10)
	panel.add_theme_stylebox_override("panel", card_style)

	var inner := VBoxContainer.new()
	inner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inner.add_theme_constant_override("separation", 12)
	panel.add_child(inner)

	# ── Row 1: Name | Score | Badge ──
	var header_row := HBoxContainer.new()
	header_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.add_theme_constant_override("separation", 12)
	inner.add_child(header_row)

	var name_label := Label.new()
	name_label.text = KPI_NAMES.get(key, key.to_upper())
	name_label.add_theme_font_size_override("font_size", 28)
	name_label.add_theme_color_override("font_color", COLOR_TEXT_PRIMARY)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.add_child(name_label)

	var score_label := Label.new()
	score_label.text = "%d / 100" % int(score)
	score_label.add_theme_font_size_override("font_size", 26)
	score_label.add_theme_color_override("font_color", _get_score_color(score))
	header_row.add_child(score_label)

	header_row.add_child(_make_status_badge(status))

	# ── Row 2: Score bar ──
	var bar_container := _make_score_bar(score)
	inner.add_child(bar_container)

	# ── Row 3: Feedback text ──
	var fb_label := Label.new()
	fb_label.text = feedback
	fb_label.add_theme_font_size_override("font_size", 20)
	fb_label.add_theme_color_override("font_color", COLOR_TEXT_SECONDARY)
	fb_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	fb_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inner.add_child(fb_label)

	# ── Row 4+: Extra details ──
	match key:
		"ps":
			_add_requirement_details(inner, data)
		"sa":
			_add_requirement_details(inner, data)
		"bc":
			_add_budget_details(inner, data)
		"eq":
			_add_attendance_details(inner, data)

	return panel


# ═══════════════════════════════════════════════════════════════════════
#  DETAIL SECTIONS
# ═══════════════════════════════════════════════════════════════════════

func _add_requirement_details(parent: VBoxContainer, data: Dictionary) -> void:
	var details: Array = data.get("details", [])
	if details.is_empty():
		return

	var met_count: int = data.get("met_count", 0)
	var total: int = data.get("total", details.size())

	parent.add_child(_make_thin_divider())

	var summary_label := Label.new()
	summary_label.text = "Requirements Met: %d / %d" % [met_count, total]
	summary_label.add_theme_font_size_override("font_size", 18)
	summary_label.add_theme_color_override("font_color", COLOR_TEXT_DIM)
	parent.add_child(summary_label)

	# Column headers
	var header_row := _make_detail_header_row(["Requirement", "Value", "Status"])
	parent.add_child(header_row)

	for detail in details:
		var d: Dictionary = detail
		var row := HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_theme_constant_override("separation", 8)

		var req_name := Label.new()
		req_name.text = d.get("name", "")
		req_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		req_name.size_flags_stretch_ratio = 2.0
		req_name.add_theme_font_size_override("font_size", 18)
		req_name.add_theme_color_override("font_color", COLOR_TEXT_SECONDARY)
		req_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row.add_child(req_name)

		var val_label := Label.new()
		val_label.text = str(d.get("value", ""))
		val_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		val_label.size_flags_stretch_ratio = 1.0
		val_label.add_theme_font_size_override("font_size", 18)
		val_label.add_theme_color_override("font_color", COLOR_TEXT_SECONDARY)
		val_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		row.add_child(val_label)

		var met: bool = d.get("met", false)
		var status_label := Label.new()
		status_label.text = "✅ Met" if met else "❌ Not Met"
		status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		status_label.size_flags_stretch_ratio = 1.0
		status_label.add_theme_font_size_override("font_size", 18)
		status_label.add_theme_color_override("font_color", COLOR_MET_GREEN if met else COLOR_UNMET_RED)
		status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(status_label)

		parent.add_child(row)


func _add_budget_details(parent: VBoxContainer, data: Dictionary) -> void:
	var incomes: Array = data.get("incomes", [])
	var costs: Array = data.get("costs", [])
	var final_budget: int = data.get("final_budget", 0)

	parent.add_child(_make_thin_divider())

	# ── Income table ──
	if not incomes.is_empty():
		var income_title := Label.new()
		income_title.text = "💰 Income Breakdown"
		income_title.add_theme_font_size_override("font_size", 22)
		income_title.add_theme_color_override("font_color", COLOR_MET_GREEN)
		parent.add_child(income_title)

		var total_income := 0
		for item in incomes:
			var d: Dictionary = item
			var amount: int = d.get("amount", 0)
			total_income += amount
			parent.add_child(_make_money_row(d.get("name", ""), amount, COLOR_MET_GREEN))

		parent.add_child(_make_money_row("Total Income", total_income, COLOR_MET_GREEN, true))

	# ── Cost table ──
	if not costs.is_empty():
		var cost_title := Label.new()
		cost_title.text = "📉 Cost Breakdown"
		cost_title.add_theme_font_size_override("font_size", 22)
		cost_title.add_theme_color_override("font_color", COLOR_UNMET_RED)
		parent.add_child(cost_title)

		var total_cost := 0
		for item in costs:
			var d: Dictionary = item
			var amount: int = d.get("amount", 0)
			total_cost += amount
			parent.add_child(_make_money_row(d.get("name", ""), -amount, COLOR_UNMET_RED))

		parent.add_child(_make_money_row("Total Cost", -total_cost, COLOR_UNMET_RED, true))

	# ── Final budget ──
	parent.add_child(_make_thin_divider())
	var final_row := HBoxContainer.new()
	final_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var fl := Label.new()
	fl.text = "Final Budget"
	fl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fl.add_theme_font_size_override("font_size", 22)
	fl.add_theme_color_override("font_color", COLOR_TEXT_PRIMARY)
	final_row.add_child(fl)

	var fv := Label.new()
	fv.text = "%d ₺" % final_budget
	fv.add_theme_font_size_override("font_size", 22)
	fv.add_theme_color_override("font_color", COLOR_EMERALD if final_budget >= 0 else COLOR_UNMET_RED)
	fv.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	final_row.add_child(fv)

	parent.add_child(final_row)


func _add_attendance_details(parent: VBoxContainer, data: Dictionary) -> void:
	var total_attendance: int = data.get("total_attendance", 0)
	var breakdown: Dictionary = data.get("breakdown", {})
	if breakdown.is_empty() and total_attendance == 0:
		return

	parent.add_child(_make_thin_divider())

	var att_title := Label.new()
	att_title.text = "👥 Attendance Breakdown — Total: %d" % total_attendance
	att_title.add_theme_font_size_override("font_size", 22)
	att_title.add_theme_color_override("font_color", COLOR_EMERALD)
	parent.add_child(att_title)

	var categories := {
		"ticket": "🎟️ Ticket Holders",
		"entertainment": "🎭 Entertainment Visitors",
		"volunteer": "🤝 Volunteers",
	}

	for bk_key in categories:
		var count: int = breakdown.get(bk_key, 0)
		var pct := 0.0
		if total_attendance > 0:
			pct = (float(count) / float(total_attendance)) * 100.0

		var row := HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var cat_label := Label.new()
		cat_label.text = categories[bk_key]
		cat_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cat_label.add_theme_font_size_override("font_size", 18)
		cat_label.add_theme_color_override("font_color", COLOR_TEXT_SECONDARY)
		row.add_child(cat_label)

		var val_label := Label.new()
		val_label.text = "%d  (%.1f%%)" % [count, pct]
		val_label.add_theme_font_size_override("font_size", 18)
		val_label.add_theme_color_override("font_color", COLOR_TEXT_PRIMARY)
		val_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(val_label)

		parent.add_child(row)


# ═══════════════════════════════════════════════════════════════════════
#  WIDGET FACTORIES
# ═══════════════════════════════════════════════════════════════════════

func _make_status_badge(status: String) -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = _get_badge_color(status)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	panel.add_theme_stylebox_override("panel", style)

	var lbl := Label.new()
	lbl.text = status
	lbl.add_theme_font_size_override("font_size", 18)
	lbl.add_theme_color_override("font_color", Color.WHITE)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(lbl)
	return panel


func _make_score_bar(score: float) -> Control:
	var container := Control.new()
	container.custom_minimum_size = Vector2(0, 8)
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# Background track
	var bg := ColorRect.new()
	bg.color = COLOR_BAR_BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	container.add_child(bg)

	# Rounded clip – we use a PanelContainer as the visual track
	var track := PanelContainer.new()
	track.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var track_style := StyleBoxFlat.new()
	track_style.bg_color = COLOR_BAR_BG
	track_style.corner_radius_top_left = 4
	track_style.corner_radius_top_right = 4
	track_style.corner_radius_bottom_left = 4
	track_style.corner_radius_bottom_right = 4
	track.add_theme_stylebox_override("panel", track_style)
	container.add_child(track)

	# Fill bar
	var fill := ColorRect.new()
	fill.color = _get_score_color(score)
	fill.anchor_left = 0
	fill.anchor_top = 0
	fill.anchor_bottom = 1
	fill.anchor_right = 0  # will animate
	fill.offset_left = 0
	fill.offset_top = 0
	fill.offset_bottom = 0
	fill.offset_right = 0
	container.add_child(fill)

	# Animate fill from 0 to score%
	var tw := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(fill, "anchor_right", clampf(score / 100.0, 0.0, 1.0), 0.8).set_delay(0.2)
	_active_tweens.append(tw)

	return container


func _make_divider() -> ColorRect:
	var div := ColorRect.new()
	div.color = COLOR_DIVIDER
	div.custom_minimum_size = Vector2(0, 2)
	div.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return div


func _make_thin_divider() -> ColorRect:
	var div := ColorRect.new()
	div.color = COLOR_DIVIDER
	div.custom_minimum_size = Vector2(0, 1)
	div.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return div


func _make_outcome_header_row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 8)

	var cols := ["Metric", "Score", "Status"]
	var ratios := [3.0, 1.0, 1.5]

	for i in cols.size():
		var lbl := Label.new()
		lbl.text = cols[i]
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl.size_flags_stretch_ratio = ratios[i]
		lbl.add_theme_font_size_override("font_size", 18)
		lbl.add_theme_color_override("font_color", COLOR_TEXT_DIM)
		if i > 0:
			lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		row.add_child(lbl)
	return row


func _make_outcome_row(label_text: String, score: float, status: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 8)

	var name_lbl := Label.new()
	name_lbl.text = label_text
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.size_flags_stretch_ratio = 3.0
	name_lbl.add_theme_font_size_override("font_size", 22)
	name_lbl.add_theme_color_override("font_color", COLOR_TEXT_PRIMARY)
	row.add_child(name_lbl)

	var score_lbl := Label.new()
	score_lbl.text = "%d" % int(score)
	score_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	score_lbl.size_flags_stretch_ratio = 1.0
	score_lbl.add_theme_font_size_override("font_size", 22)
	score_lbl.add_theme_color_override("font_color", _get_score_color(score))
	score_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(score_lbl)

	var badge_wrapper := CenterContainer.new()
	badge_wrapper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	badge_wrapper.size_flags_stretch_ratio = 1.5
	badge_wrapper.add_child(_make_status_badge(status))
	row.add_child(badge_wrapper)

	return row


func _make_detail_header_row(columns: Array) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 8)

	var ratios := [2.0, 1.0, 1.0]
	var alignments := [
		HORIZONTAL_ALIGNMENT_LEFT,
		HORIZONTAL_ALIGNMENT_CENTER,
		HORIZONTAL_ALIGNMENT_RIGHT,
	]

	for i in columns.size():
		var lbl := Label.new()
		lbl.text = columns[i]
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl.size_flags_stretch_ratio = ratios[i]
		lbl.add_theme_font_size_override("font_size", 18)
		lbl.add_theme_color_override("font_color", COLOR_TEXT_DIM)
		lbl.horizontal_alignment = alignments[i]
		row.add_child(lbl)
	return row


func _make_money_row(label_text: String, amount: int, accent: Color, bold: bool = false) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var nl := Label.new()
	nl.text = ("  " if not bold else "") + label_text
	nl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nl.add_theme_font_size_override("font_size", 20 if bold else 18)
	nl.add_theme_color_override("font_color", COLOR_TEXT_PRIMARY if bold else COLOR_TEXT_SECONDARY)
	row.add_child(nl)

	var vl := Label.new()
	vl.text = "%s%d ₺" % ["+" if amount >= 0 else "", amount]
	vl.add_theme_font_size_override("font_size", 20 if bold else 18)
	vl.add_theme_color_override("font_color", accent)
	vl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(vl)

	return row


# ═══════════════════════════════════════════════════════════════════════
#  COLOR HELPERS
# ═══════════════════════════════════════════════════════════════════════

func _get_score_color(score: float) -> Color:
	if score >= 80.0:
		return COLOR_SCORE_GREEN
	elif score >= 60.0:
		return COLOR_SCORE_YELLOW
	elif score >= 40.0:
		return COLOR_SCORE_ORANGE
	else:
		return COLOR_SCORE_RED


func _get_badge_color(status: String) -> Color:
	var s := status.to_lower()
	if "excellent" in s or "outstanding" in s:
		return Color(0.1, 0.6, 0.3)
	elif "good" in s or "strong" in s or "successful" in s:
		return Color(0.2, 0.5, 0.3)
	elif "moderate" in s or "acceptable" in s:
		return Color(0.6, 0.5, 0.1)
	elif "weak" in s or "risky" in s:
		return Color(0.7, 0.3, 0.1)
	elif "very low" in s or "critical" in s or "fail" in s:
		return Color(0.7, 0.1, 0.1)
	else:
		return Color(0.35, 0.38, 0.45)


# ═══════════════════════════════════════════════════════════════════════
#  CALLBACKS
# ═══════════════════════════════════════════════════════════════════════

func _on_return_pressed() -> void:
	var tw := create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(self, "modulate", Color(1, 1, 1, 0), 0.25)
	tw.tween_callback(func():
		visible = false
		get_tree().change_scene_to_file("res://main_menu.tscn")
	)
