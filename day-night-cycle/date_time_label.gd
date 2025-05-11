extends Label

func _ready() -> void:
	if not TimeManager:
		push_warning("TimeManager autoload not found!")
		return
	TimeManager.time_updated.connect(_on_time_updated)
	# Set initial value
	_on_time_updated(TimeManager.time_of_day)

func _on_time_updated(time_of_day: float) -> void:
	var date = TimeManager.get_date()
	var year = date["year"]
	var month = date["month"]
	var day = date["day"]
	var hours = int(time_of_day * 24)
	var minutes = int((time_of_day * 24 - hours) * 60)
	text = "%02d:%02d %02d/%02d %04d" % [hours, minutes, month, day, year]
