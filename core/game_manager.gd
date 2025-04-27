extends Node

var player_scene = "res://player_controller.tscn";

var main: Main

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass
	

func start_game() -> void:
	GameState.game_started = true
	SignalBus.on_game_start.emit()
	if multiplayer.is_server():
		main.map_spawner.spawn_map()
		main.player_spawner.spawn_players()
		
	
func _remove_player(id: int):
	if GameState.players[id].player_node != null:
		GameState.players[id].player_node.queue_free()
		GameState.players.erase(id)
		
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_key_pressed(KEY_ESCAPE) && GameState.game_started:
		leave_game.rpc_id(1, multiplayer.get_unique_id())
	pass
	
@rpc("any_peer")
func leave_game(id: int) -> void:
	multiplayer.multiplayer_peer.disconnect_peer(id)

	
