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
var container_registry: Dictionary = {}

func _ready() -> void:
	item_db._generate_item_dict(item_db.items)
	

@rpc("authority", "call_local")
func player_inventory_updated(encoded: Array):
	if player_inventory == null:
		player_inventory = InventoryData.net_decode(encoded)
		player_inventory.inventory_changed.connect(func():
			update_player_inventory.rpc_id(1, player_inventory.net_encode())
			on_player_inventory_update.emit(player_inventory)
		)
		player_inventory.inventory_changed_remote.connect(func():
			on_player_inventory_update.emit(player_inventory)
		)
	else:
		player_inventory.update_from_network(encoded)
	
	on_player_inventory_update.emit(player_inventory)


@rpc("any_peer")
func update_player_inventory(encoded: Array):
	if multiplayer.is_server():
		var sender = multiplayer.get_remote_sender_id()
		var unique_id = GameState.players[sender].user_id
		server_all_player_inventories[unique_id].update_from_network(encoded)
		player_inventory_updated.rpc_id(sender, server_all_player_inventories[unique_id].net_encode())

func toggle_inventory():
	inventory_open = !inventory_open
	toggle_player_inventory.emit(inventory_open)

func open_container(container: InventoryContainer):
	inventory_open = true
	toggle_player_inventory.emit(inventory_open)
	show_container_inventory.emit(container)

func register_container(container: InventoryContainer) -> int:
	var container_id = container.get_path().hash()
	container_registry[container_id] = container
	return container_id

@rpc("any_peer", "call_local")
func sync_container_data(container_id: int):
	if multiplayer.is_server() && container_registry.has(container_id):
		update_container_data.rpc(container_id, container_registry[container_id].inventory_data.net_encode())

@rpc("any_peer", "call_local")
func send_container_data(container_id: int, encoded_data: Array):
	if container_registry.has(container_id):
		container_registry[container_id].inventory_data.update_from_network(encoded_data)
		update_container_data.rpc(container_id, encoded_data)

@rpc("authority")
func update_container_data(container_id: int, encoded_data: Array):
	if container_registry.has(container_id):
		container_registry[container_id].inventory_data.update_from_network(encoded_data)

func get_container_data(container_id: int) -> InventoryData:
	if container_registry.has(container_id):
		return container_registry[container_id].inventory_data
	return null


func set_player_inventory(multiplayer_id: int, user_id: int):
	if !Inventory.server_all_player_inventories.has(user_id):
		Inventory.server_all_player_inventories[user_id] = TEST_INVENTORY.duplicate()
		
	player_inventory_updated.rpc_id(multiplayer_id, Inventory.server_all_player_inventories[user_id].net_encode())
