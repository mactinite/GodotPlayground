extends Control
class_name InventoryUI

@export var inventory_data: InventoryData
@export var container_data: InventoryData

@onready var inventory: InventoryComponent = $Inventory
@onready var container_inventory: InventoryComponent = $"External Inventory"
@onready var grabbed_slot: SlotUI = $GrabbedSlot

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
	
	container_inventory.inventory_data = container_data
	
	inventory.on_slot_click_down.connect(func(index: int):
		if inventory_data.slots[index]:
			grabbed_slot.slot_data = inventory_data.slots[index]
			grabbed_slot.visible = true
		pass
	)
	inventory.on_slot_click_up.connect(func(index: int):
		_swap_slots(inventory_data, index, hovered_inventory.inventory_data, hovered_index)

		if hovered_inventory == container_inventory:
			# send the new data to the server
			Inventory.send_container_data.rpc_id(1, open_container.container_id, container_data.net_encode())
			
		Inventory.update_player_inventory.rpc_id(1, inventory_data.net_encode())
		grabbed_slot.slot_data = null
		grabbed_slot.visible = false
	)
	
	inventory.on_slot_hovered.connect(func(i: int):
		hovered_index = i
		hovered_inventory = inventory
	)
	
	container_inventory.on_slot_click_down.connect(func(index: int):
		if container_data.slots[index]:
			grabbed_slot.slot_data = container_data.slots[index]
			grabbed_slot.visible = true
	)
	container_inventory.on_slot_click_up.connect(func(index: int):
		_swap_slots(container_data, index, hovered_inventory.inventory_data, hovered_index)

		# send the new data to the server
		Inventory.send_container_data.rpc_id(1, open_container.container_id, container_data.net_encode())
		Inventory.update_player_inventory.rpc_id(1, inventory_data.net_encode())
		grabbed_slot.slot_data = null
		grabbed_slot.visible = false
	)
	
	container_inventory.on_slot_hovered.connect(func(i: int):
		hovered_index = i
		hovered_inventory = container_inventory
	)
	
func _container_updated() -> void:
	container_data = open_container.inventory_data
	container_inventory.inventory_data = container_data
	container_inventory.redraw_inventory()

func _swap_slots(_inventory_data: InventoryData, index: int, \
	other_inventory_data: InventoryData, other_index: int) -> void:
	# drop the item into the inventory data, and if anything is return swap it to the source index
	var dest = other_inventory_data.slots[other_index]
	other_inventory_data.slots[other_index] = grabbed_slot.slot_data
	_inventory_data.slots[index] = dest

	hovered_inventory.redraw_inventory()
	inventory.redraw_inventory()


func _physics_process(_delta: float) -> void:
	if grabbed_slot.visible:
		grabbed_slot.global_position = get_global_mouse_position() + Vector2(5, 5)
