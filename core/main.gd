extends Node3D
class_name Main

@export var menus: Menus
@export var player_spawner: PlayerSpawner
@export var map_spawner: MapSpawner
@export var inventory_ui: InventoryUI
@export var notification_manager: Node

func _ready() -> void:
	GameManager.main = self
	NetworkManager.on_server_disconnected.connect(func ():
		GameState.game_started = false
		multiplayer.multiplayer_peer = null
		GameManager.main.menus.goto(Menus.MENU.MAIN)
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	)
