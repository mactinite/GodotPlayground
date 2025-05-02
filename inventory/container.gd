extends Node
class_name InventoryContainer

signal on_inventory_updated()

@export var inventory_data: InventoryData

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func interact() -> void:
	Inventory.open_container(self)
	

@rpc("any_peer")
func update_inventory(encoded_inventory: Array)-> void:
	inventory_data = InventoryData.net_decode(encoded_inventory)
	if multiplayer.is_server():
		on_inventory_updated.emit()
		send_inventory_update.rpc(inventory_data.net_encode())


@rpc("authority")
func send_inventory_update(encoded_inventory: Array)-> void:
	inventory_data = InventoryData.net_decode(encoded_inventory)
	on_inventory_updated.emit()
