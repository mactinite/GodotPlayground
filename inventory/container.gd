extends Node3D

signal toggle_inventory(external_inventory_owner)

@export var inventory_data: InventoryData

func _ready() -> void:
	toggle_inventory.connect(func(owner):
		InventoryManager.toggle_inventory(owner)
		request_inventory_data.rpc_id(1)
	)
	
	inventory_data.inventory_updated.connect(func (data: InventoryData):
		if is_multiplayer_authority():
			var encoded = data.serialize()
			send_inventory_update.rpc(encoded)
		else:
			var encoded = data.serialize()
			send_inventory_update.rpc_id(1, encoded)
	)
	
	inventory_data.on_remote_inventory_changes.connect(func (data: InventoryData):
		SignalBus.on_external_inventory_update.emit(data)
	)

@rpc("any_peer", "call_local")
func send_inventory_update(serialized_inventory: Array):
	inventory_data.deserialize(serialized_inventory)

@rpc("any_peer")
func request_inventory_data():
	if is_multiplayer_authority():
		send_inventory_update(inventory_data.serialize())

func player_interact() -> void:
	toggle_inventory.emit(self)
