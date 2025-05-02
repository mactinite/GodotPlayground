extends Node

var player_scene = "res://player_controller.tscn";

var main: Main

var lan_user_name: String = "Master Chief"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var args = get_args()
	
	lan_user_name = args.user
	pass

func get_args() -> Dictionary:
	var arguments = {}
	for argument in OS.get_cmdline_args():
		if argument.contains("="):
			var key_value = argument.split("=")
			arguments[key_value[0].trim_prefix("--")] = key_value[1]
		else:
			# Options without an argument will be present in the dictionary,
			# with the value set to an empty string.
			arguments[argument.trim_prefix("--")] = ""
			
	return arguments

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
	
@rpc("any_peer", "call_local")
func leave_game(id: int) -> void:
	multiplayer.multiplayer_peer.disconnect_peer(id)
