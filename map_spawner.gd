extends MultiplayerSpawner
class_name MapSpawner

const test_map = preload("res://World.tscn")
@onready var map: Node3D = $"../Map"

var current_scene: Node

func spawn_map() -> void:
	var new_scene = test_map.instantiate()
	if current_scene: current_scene.queue_free()
	map.add_child(new_scene)
