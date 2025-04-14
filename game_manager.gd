extends Node

var players = {
	# name
	# id
	# player_node
}

var gameStarted: bool = false;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _spawn_players(player_scene: PackedScene):
	var index = 0
	for i in GameManager.players:
		if(GameManager.players[i].player_node != null):
			var currentPlayer = player_scene.instantiate()
			currentPlayer.name = str(GameManager.players[i].id)
			add_child(currentPlayer)
			for spawn in get_tree().get_nodes_in_group("spawn_point"):
				if spawn.name == str(index):
					currentPlayer.global_position = spawn.global_position
			index += 1

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
