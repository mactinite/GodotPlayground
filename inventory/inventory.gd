extends Node

signal on_player_inventory_update(InventoryData)
signal toggle_player_inventory(bool)
signal show_container_inventory(InventoryContainer)

const TEST_INVENTORY = preload("res://inventory/data/Test_Inventory.tres")
const TEST_ITEM_DATABASE = preload("res://inventory/data/item_database.tres")
var item_db: ItemDB = TEST_ITEM_DATABASE

var player_inventory: InventoryData
var inventory_open: bool = false
var server_all_player_inventories: Dictionary[int, InventoryData]

func _ready() -> void:
	item_db._generate_item_dict(item_db.items)
	

@rpc("authority", "call_local")
func player_inventory_updated(encoded: Array):
	player_inventory = InventoryData.net_decode(encoded)
	on_player_inventory_update.emit(player_inventory)


@rpc("any_peer")
func update_player_inventory(encoded: Array):
	if multiplayer.is_server():
		var sender = multiplayer.get_remote_sender_id()
		var unique_id = GameState.players[sender].user_id
		server_all_player_inventories[unique_id] = InventoryData.net_decode(encoded)
		player_inventory_updated.rpc_id(sender, server_all_player_inventories[unique_id].net_encode())


		
func toggle_inventory():
	inventory_open = !inventory_open
	toggle_player_inventory.emit(inventory_open)

func open_container(container: InventoryContainer):
	inventory_open = true
	toggle_player_inventory.emit(inventory_open)
	show_container_inventory.emit(container)
	
func set_player_inventory(multiplayer_id:int, user_id: int):
	if !Inventory.server_all_player_inventories.keys().has(user_id):
		Inventory.server_all_player_inventories[user_id] = TEST_INVENTORY.duplicate()
		
	player_inventory_updated.rpc_id(multiplayer_id,Inventory.server_all_player_inventories[user_id].net_encode())
