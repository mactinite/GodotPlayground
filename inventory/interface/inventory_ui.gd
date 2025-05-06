extends Control
class_name InventoryUI

@export var inventory_data: InventoryData
@export var container_data: InventoryData

@onready var inventory: InventoryComponent = $Inventory
@onready var container_inventory: InventoryComponent = $"External Inventory"

var hovered_index: int = -1
var hovered_inventory: InventoryComponent

var open_container: InventoryContainer

func _ready() -> void:
	Inventory.toggle_player_inventory.connect(func(open):
		self.visible = open
		if !open:
			container_inventory.visible = false
			container_inventory.inventory_data = InventoryData.new()
			if open_container:
				open_container.on_inventory_updated.disconnect(_container_updated)
				open_container = null
	)
	
	Inventory.show_container_inventory.connect(func(container: InventoryContainer):
		self.visible = true
		open_container = container
		open_container.on_inventory_updated.connect(_container_updated)
		container_data = container.inventory_data
		container_inventory.inventory_data = container_data
		container_inventory.visible = true
		container_inventory.redraw_inventory()
	)
	
	Inventory.on_player_inventory_update.connect(func(data: InventoryData):
		inventory_data = data
		inventory.inventory_data = data
		inventory.redraw_inventory()
	)

	inventory.on_slot_hovered.connect(func(i: int):
		hovered_index = i
		hovered_inventory = inventory
	)
	
	container_inventory.on_slot_hovered.connect(func(i: int):
		hovered_index = i
		hovered_inventory = container_inventory
	)

func _container_updated() -> void:
	container_data = open_container.inventory_data
	container_inventory.inventory_data = container_data
	container_inventory.redraw_inventory()
