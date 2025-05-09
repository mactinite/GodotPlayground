extends Node
class_name InventoryContainer

signal on_inventory_updated()

@export var inventory_data: InventoryData
var container_id: int
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Register the container with the Inventory system
	container_id = Inventory.register_container(self)

	if multiplayer.is_server():
		# Sync the container data with all clients
		var encoded_data = inventory_data.net_encode()
		Inventory.send_container_data.rpc(container_id, encoded_data)
	else:
		Inventory.sync_container_data.rpc_id(1, container_id)

	inventory_data.inventory_changed.connect(func():
		if multiplayer.is_server():
			# Sync the container data with all clients
			var encoded_data = inventory_data.net_encode()
			Inventory.send_container_data.rpc(container_id, encoded_data)
		else:
			var encoded_data = inventory_data.net_encode()
			Inventory.send_container_data.rpc_id(1, container_id, encoded_data)

		on_inventory_updated.emit()
	)

	inventory_data.inventory_changed_remote.connect(func():
		on_inventory_updated.emit()
	)

		
func interact() -> void:
	Inventory.sync_container_data.rpc_id(1, container_id)
	Inventory.open_container(self)
