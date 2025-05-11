extends Node

@export var seconds_per_day: float = 300 # 300 seconds = 5 minutes for a full day cycle

signal time_updated(time_of_day: float)

var time_of_day := 0.0 # 0.0 = midnight, 0.5 = noon, 1.0 = next midnight

const START_YEAR := 2000
const DAYS_IN_MONTH := [31,28,31,30,31,30,31,31,30,31,30,31] # Non-leap year

var year: int = START_YEAR
var month: int = 1 # 1-12
var day: int = 1 # 1-31

var time_running := false

func _process(delta: float) -> void:
	if time_running:
		time_of_day += delta / seconds_per_day
		if time_of_day >= 1.0:
			time_of_day = fmod(time_of_day, 1.0)
			_increment_date()
		time_updated.emit(time_of_day)

func start_time():
	time_running = true

func stop_time():
	time_running = false

func _increment_date():
	day += 1
	var days_this_month = DAYS_IN_MONTH[month - 1]
	# Simple leap year check for February
	if month == 2 and _is_leap_year(year):
		days_this_month = 29
	if day > days_this_month:
		day = 1
		month += 1
		if month > 12:
			month = 1
			year += 1

func _is_leap_year(y: int) -> bool:
	return (y % 4 == 0 and (y % 100 != 0 or y % 400 == 0))

func set_seconds_per_day(value: float) -> void:
	seconds_per_day = max(value, 0.01)

func set_time_of_day(value: float) -> void:
	time_of_day = clamp(value, 0.0, 1.0)
	time_updated.emit(time_of_day)

func get_date() -> Dictionary:
	return {"year": year, "month": month, "day": day}

@rpc("authority")
func sync_time_to_client(target_peer_id: int):
	if multiplayer.is_server():
		sync_time.rpc_id(target_peer_id, time_of_day, year, month, day)

@rpc("any_peer")
func sync_time(time_of_day_val: float, year_val: int, month_val: int, day_val: int):
	time_of_day = time_of_day_val
	year = year_val
	month = month_val
	day = day_val
	time_updated.emit(time_of_day)
