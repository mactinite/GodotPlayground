extends Node3D
class_name Main

@export var menus: Menus
@export var player_spawner: PlayerSpawner
@export var map_spawner: MapSpawner

func _ready() -> void:
	GameManager.main = self
