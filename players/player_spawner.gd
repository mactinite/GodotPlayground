extends MultiplayerSpawner
class_name PlayerSpawner

@export var player_scene : PackedScene

func _enter_tree() -> void:
	spawn_function = players_custom_spawn

func ready():
	add_spawnable_scene(player_scene.resource_path)


func players_custom_spawn(id: int) -> Node:
	var currentPlayer = player_scene.instantiate()
	currentPlayer.set_meta("id", id)
	currentPlayer.set_multiplayer_authority(id)
	if(id == multiplayer.get_unique_id()):
		GameState.local_player_object = currentPlayer
	return currentPlayer

func spawn_players():
	var index = 0
	for i in GameState.players:
		if GameState.players[i].player_node == null:
			var currentPlayer = spawn(i)
			GameState.players[i].player_node = currentPlayer
		index += 1
