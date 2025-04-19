extends Node

signal on_player_inventory_update(InventoryData)
signal on_player_inventory_toggle(Node3D)
signal on_external_inventory_update(InventoryData)
signal on_external_inventory_toggle()


var player_scene = "res://player_controller.tscn";
# reference to the players controller (fps, tps, etc)
var local_player_object: Node;
var local_player_inventory: InventoryData
var players = {
	# name
	# id
	# player_node
}
var game_started = false


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func start_game():
	game_started = true
	
func set_inventory(data: InventoryData):
	local_player_inventory = data
	on_player_inventory_update.emit(local_player_inventory)

func _remove_player(id: int):
	if GameManager.players[id].player_node != null:
		GameManager.players[id].player_node.queue_free()
		GameManager.players.erase(id)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func toggle_inventory(external_inventory_owner = null):
	
	if local_player_object:
		local_player_object.can_control = !local_player_object.can_control
	
	on_player_inventory_toggle.emit(external_inventory_owner)
