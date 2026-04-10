extends Node2D



@onready var activity_board = $ActivityBoard
@onready var team_assignment_panel: Panel = $TeamAssignmentPanel
@onready var initial_facility_layout_panel: Panel = $InitialFacilityLayoutPanel
@onready var emergency_training_panel: Panel = $EmergencyTrainingPanel
@onready var sponsor_management_panel: Panel = $SponsorManagementPanel

func _ready() -> void:
	GameState.load_team_members()
	team_assignment_panel.hide()
	initial_facility_layout_panel.hide()
	emergency_training_panel.hide()
	sponsor_management_panel.hide()
	activity_board.show()
