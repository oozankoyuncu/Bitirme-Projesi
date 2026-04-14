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

func _ready() -> void:
	GameState.load_team_members()
	team_assignment_panel.hide()
	initial_facility_layout_panel.hide()
	emergency_training_panel.hide()
	sponsor_management_panel.hide()
	entertainment_lineup_panel.hide()
	promotion_strategy_panel.hide()
	ticket_pricing_panel.hide()
	volunteer_club_panel.hide()
	stage_setup_choices_panel.hide()
	activity_board.show()
