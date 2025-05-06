extends Node
class_name InventoryContainer

signal on_inventory_updated()

@export var inventory_data: InventoryData
var container_id: int
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Register the container with the Inventory system
	container_id = Inventory.register_container(self)
	inventory_data.inventory_changed.connect(func():
		on_inventory_updated.emit()
	)
	if multiplayer.is_server():
		# Sync the container data with all clients
		var encoded_data = inventory_data.net_encode()
		Inventory.send_container_data.rpc_id(1, container_id, encoded_data)
	else:
		Inventory.sync_container_data.rpc(1, container_id)
		


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func interact() -> void:
	Inventory.sync_container_data.rpc_id(1, container_id)
	Inventory.open_container(self)


# will get called by Inventory manager when the container is updated
func update_inventory(data: InventoryData) -> void:
	inventory_data = data
	on_inventory_updated.emit()

func update_inventory_from_network(encoded: Array) -> void:
	inventory_data.update_from_network(encoded)
	on_inventory_updated.emit()
