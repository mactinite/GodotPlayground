extends Node

signal on_player_inventory_update(InventoryData)
signal on_player_inventory_toggle(Node3D)
signal on_external_inventory_update(InventoryData)
signal on_external_inventory_toggle()
signal on_player_dropped_slot_data(SlotData)

const item_database = preload("res://inventory/resources/item_database.tres")
const item_pickup = preload("res://inventory/item_pickup.tscn")
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
var item_lookup_table: Dictionary
var spawner: MultiplayerSpawner
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	item_lookup_table = item_database.get_lookup_table()
	# Add a multiplayer spawner and point it at the world node
	spawner = MultiplayerSpawner.new()
	add_child(spawner)
	spawner.spawn_path = get_tree().get_first_node_in_group("world").get_path()
	spawner.add_spawnable_scene(item_pickup.resource_path)
	spawner.spawn_function = spawn_pickup_at
	
func spawn_pickup_at(args: Array) -> Node:
	var pick_up = item_pickup.instantiate()
	pick_up.set_slot_data(SlotData.new(GameManager.get_item_by_hash(args[1][1]), args[1][0]))
	var stage = get_tree().get_first_node_in_group("world")
	pick_up.name = pick_up.item_data.name + str(pick_up.item_qty) + str(pick_up.item_hash)
	pick_up.position = args[0]
	return pick_up


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
	
func player_pickup_slot_data(slot_data: SlotData) -> bool:
	return local_player_inventory.pick_up_slot_data(slot_data)

func player_drop_slot_data(slot_data: SlotData) -> void:
	# to the server: we need to drop an item
	player_drop_item.rpc_id(1, slot_data.encode(), multiplayer.get_unique_id())
	
@rpc("any_peer", "call_local")
func player_drop_item(encoded_slot: Array, id: int) -> void:
	if multiplayer.is_server():
		# lets make sure its a valid item
		var slot_data = SlotData.decode(encoded_slot)
		var item = slot_data.item_data
		var quantity = slot_data.quantity
		if quantity > 0 && item:
			var spawn_pos = players[id].player_node.get_drop_position()
			spawner.spawn([spawn_pos, encoded_slot])
	
func get_item_by_hash(hash: String) -> ItemData:
	if item_lookup_table.has(hash):
		return item_lookup_table[hash]
	return null
	
func get_item_hash(item: ItemData) -> String:
	if !item:
		return ""
	return item_database.get_item_hash(item)
