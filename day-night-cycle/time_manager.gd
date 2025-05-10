extends Node

@export var seconds_per_day: float = 60.0

signal time_updated(time_of_day: float)

var time_of_day := 0.0 # 0.0 = midnight, 0.5 = noon, 1.0 = next midnight

func _process(delta: float) -> void:
	time_of_day += delta / seconds_per_day
	time_of_day = fmod(time_of_day, 1.0)
	time_updated.emit(time_of_day)

func set_seconds_per_day(value: float) -> void:
	seconds_per_day = max(value, 0.01)

func set_time_of_day(value: float) -> void:
	time_of_day = clamp(value, 0.0, 1.0)
	time_updated.emit(time_of_day)
