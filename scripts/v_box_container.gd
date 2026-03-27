extends VBoxContainer




@onready var hud: Label = $HUD


func _ready():
	GameState.time_changed.connect(_refresh_time)
	_refresh_time()

func _refresh_time():
	hud.text = GameState.get_hud_text()
	
