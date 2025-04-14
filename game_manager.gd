extends Node

var player_scene = "res://player_controller.tscn";
var players = {
	# name
	# id
	# player_node
}
var game_started = false
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _remove_player(id: int):
	if GameManager.players[id].player_node != null:
		GameManager.players[id].player_node.queue_free()
		GameManager.players.erase(id)



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
