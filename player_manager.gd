extends Node3D
@export var player_scene : PackedScene
@export var spawner: MultiplayerSpawner;

func _enter_tree() -> void:
	spawner.spawn_function = players_custom_spawn

func ready():
	spawner.add_spawnable_scene(player_scene.resource_path)


func players_custom_spawn (id: int) -> Node:
	var currentPlayer = player_scene.instantiate()
	currentPlayer.name = str(id)
	GameManager.players[id].player_node = currentPlayer			
	currentPlayer.set_multiplayer_authority(id)
	if(id == multiplayer.get_unique_id()):
		GameManager.local_player_object = currentPlayer

	return currentPlayer


func spawn_players():
	var index = 0
	for i in GameManager.players:
		if GameManager.players[i].player_node == null:
			var currentPlayer = spawner.spawn(i)
			GameManager.players[i].player_node = currentPlayer

		index += 1
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
