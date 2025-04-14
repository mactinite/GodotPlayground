extends Node3D
@export var player_scene : PackedScene
@export var spawner: MultiplayerSpawner;

func ready():
	spawner.add_spawnable_scene(player_scene.resource_path)

func spawn_players():
	var index = 0
	for i in GameManager.players:
		if GameManager.players[i].player_node == null:
			var currentPlayer = player_scene.instantiate()
			currentPlayer.name = str(i)
			GameManager.players[i].player_node = currentPlayer
			self.add_child(currentPlayer, true)
			for spawn in get_tree().get_nodes_in_group("spawn_point"):
				if spawn.name == str(index):
					currentPlayer.global_position = spawn.global_position
		index += 1
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
