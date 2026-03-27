extends Panel

var selected_facility: String = ""
var selected_area_name: String = ""

var areas = {
	"AreaA": {"electricity": true, "truck_access": true, "capacity": 100, "assigned": ""},
	"AreaB": {"electricity": false, "truck_access": true, "capacity": 60, "assigned": ""},
	"AreaC": {"electricity": true, "truck_access": false, "capacity": 80, "assigned": ""},
	"AreaD": {"electricity": false, "truck_access": false, "capacity": 40, "assigned": ""}
}

@onready var area_info_label: Label = $AreaInfoLabel
@onready var confirm_button: Button = $ConfirmButton


func _ready() -> void:
	$PlacementButtons/StageButton.pressed.connect(_on_stage_pressed)
	$PlacementButtons/FoodButton.pressed.connect(_on_food_pressed)
	$PlacementButtons/ClubButton.pressed.connect(_on_club_pressed)

	$MapArea/AreaA.pressed.connect(func(): _on_area_pressed("AreaA"))
	$MapArea/AreaB.pressed.connect(func(): _on_area_pressed("AreaB"))
	$MapArea/AreaC.pressed.connect(func(): _on_area_pressed("AreaC"))
	$MapArea/AreaD.pressed.connect(func(): _on_area_pressed("AreaD"))

	$ConfirmButton.pressed.connect(_on_confirm_pressed)
	$BackButton.pressed.connect(_on_back_pressed)

func _on_stage_pressed() -> void:
	selected_facility = "Stage"

func _on_food_pressed() -> void:
	selected_facility = "Food Vendor"

func _on_club_pressed() -> void:
	selected_facility = "Club Stand"

func _on_area_pressed(area_name: String) -> void:
	selected_area_name = area_name

	if selected_facility != "":
		areas[area_name]["assigned"] = selected_facility

		var area_button = $MapArea.get_node(area_name)
		area_button.text = area_name + "\n" + selected_facility

	update_area_info(area_name)

func update_area_info(area_name: String) -> void:
	var area = areas[area_name]

	area_info_label.text = area_name + "\n" + \
		"Electricity: " + str(area["electricity"]) + "\n" + \
		"Truck Access: " + str(area["truck_access"]) + "\n" + \
		"Capacity: 0/" + str(area["capacity"]) + "\n" + \
		"Assigned: " + str(area["assigned"])
		
		
		
func _on_confirm_pressed() -> void:
	GameState.layout_plan = areas

	if not GameState.completed_activities.has("initial_festival_layout_mapping"):
		GameState.completed_activities.append("initial_festival_layout_mapping")

	hide()
	get_parent().get_node("ActivityBoard").show()
	get_parent().get_node("ActivityBoard").refresh_board()
	
	
	
func _on_back_pressed() -> void:
	hide()
	get_parent().get_node("ActivityBoard").show()
