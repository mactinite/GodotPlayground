extends Node3D

signal toggle_inventory(external_inventory_owner)

@export var inventory_data: InventoryData

func _ready() -> void:
	toggle_inventory.connect(func(owner):
		GameManager.toggle_inventory(owner)
	)

func player_interact() -> void:
	toggle_inventory.emit(self)
