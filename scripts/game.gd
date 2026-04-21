extends Control



@onready var activity_board = $ActivityBoard
@onready var team_assignment_panel: Panel = $TeamAssignmentPanel
@onready var initial_facility_layout_panel: Panel = $InitialFacilityLayoutPanel
@onready var emergency_training_panel: Panel = $EmergencyTrainingPanel
@onready var sponsor_management_panel: Panel = $SponsorManagementPanel
@onready var entertainment_lineup_panel: Panel = $EntertainmentLineupPanel
@onready var promotion_strategy_panel: Panel = $PromotionStrategyPanel
@onready var ticket_pricing_panel: Panel = $TicketPricingPanel
@onready var volunteer_club_panel: Panel = $VolunteerClubPanel
@onready var stage_setup_choices_panel: Panel = $StageSetupChoicesPanel
@onready var email_panel: Panel = $EmailPanel
@onready var charter_panel: Panel = $CharterPanel

@onready var week_label: Label = $TopBar/Margin/HBox/Stats/WeekBox/Label
@onready var budget_label: Label = $TopBar/Margin/HBox/Stats/BudgetBox/Label
@onready var time_label_hud: Label = $TopBar/Margin/HBox/Stats/TimeBox/Label

func _ready() -> void:
	GameState.load_team_members()
	GameState.time_changed.connect(_on_time_changed)
	
	# Hide all sub-panels
	team_assignment_panel.hide()
	initial_facility_layout_panel.hide()
	emergency_training_panel.hide()
	sponsor_management_panel.hide()
	entertainment_lineup_panel.hide()
	promotion_strategy_panel.hide()
	ticket_pricing_panel.hide()
	volunteer_club_panel.hide()
	stage_setup_choices_panel.hide()
	
	# Initial Onboarding Sequence
	if GameState.skip_onboarding:
		activity_board.show()
		charter_panel.hide()
		email_panel.hide()
		if GameState.has_method("start_game_timer"):
			GameState.start_game_timer()
	else:
		charter_panel.show()
		activity_board.hide()
		email_panel.hide()
	
	_update_hud()

func _on_time_changed() -> void:
	_update_hud()

func _update_hud() -> void:
	week_label.text = "Week: " + str(GameState.week)
	budget_label.text = "Budget: " + str(GameState.money) + " TL"
	
	var total := int(GameState.game_seconds)
	var hours := total / 3600
	var minutes := (total % 3600) / 60
	var seconds := total % 60
	time_label_hud.text = "%02d:%02d:%02d" % [hours, minutes, seconds]
