extends CanvasLayer

@onready var cronometer_label: Label = $CronometerLabel
@onready var week_label: Label = $WeekLabel



func _ready():
	GameState.time_changed.connect(_refresh_time)
	_refresh_time()

func _refresh_time():
	cronometer_label.text = GameState.get_time_text()
	week_label.text = GameState.get_week_text()
