extends Control
class_name InventoryUI

@export var inventory_data: InventoryData
@export var container_data: InventoryData

@onready var inventory: InventoryComponent = $Inventory
@onready var container_inventory: InventoryComponent = $"External Inventory"
@onready var grabbed_slot: SlotUI = $GrabbedSlot

var hovered_index: int = -1
var hovered_inventory: InventoryComponent;

func _ready() -> void:
	
	Inventory.toggle_player_inventory.connect(func(open):
		self.visible = open
		if !open:
			container_inventory.visible = false
	)
	
	Inventory.show_container_inventory.connect(func(container: InventoryContainer):
		self.visible = true
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
	
	inventory.on_slot_click_down.connect(func (index: int):
		var name = inventory_data.slots[index].item.name if inventory_data.slots[index] && inventory_data.slots[index].item else "null"
		if inventory_data.slots[index]:
			grabbed_slot.slot_data = inventory_data.slots[index]
			grabbed_slot.visible = true
		pass
	)
	inventory.on_slot_click_up.connect(func (index: int):
		var name = inventory_data.slots[index].item.name if inventory_data.slots[index] && inventory_data.slots[index].item else "null"
		
		print("Dropping %s from %s:%s on %s;%s" % [name, inventory_data, index, hovered_inventory, hovered_index])
		
		_swap_slots(inventory_data, index, hovered_inventory.inventory_data, hovered_index)
		
		grabbed_slot.slot_data = null
		grabbed_slot.visible = false
	)
	
	inventory.on_slot_hovered.connect(func(i: int):
		hovered_index = i
		hovered_inventory = inventory
	)
	
	container_inventory.on_slot_click_down.connect(func (index: int):
			var name = container_data.slots[index].item.name if container_data.slots[index] && container_data.slots[index].item else "null"
			if container_data.slots[index]:
				grabbed_slot.slot_data = container_data.slots[index]
				grabbed_slot.visible = true
	)
	container_inventory.on_slot_click_up.connect(func (index: int):
		var name = container_data.slots[index].item.name if container_data.slots[index] && container_data.slots[index].item else "null"
		
		print("Dropping %s from %s:%s on %s;%s" % [name, container_data, index, hovered_inventory, hovered_index])
		
		_swap_slots(container_data, index, hovered_inventory.inventory_data, hovered_index)
		
		grabbed_slot.slot_data = null
		grabbed_slot.visible = false
	)
	
	container_inventory.on_slot_hovered.connect(func(i: int):
		hovered_index = i
		hovered_inventory = container_inventory
	)
	
func _swap_slots(inventory: InventoryData, index: int, \
	other_inventory: InventoryData, other_index: int) -> void:
	# drop the item into the inventory data, and if anything is return swap it to the source index
	var dest = other_inventory.slots[other_index]		
	other_inventory.slots[other_index] = grabbed_slot.slot_data
	inventory.slots[index] = dest
	hovered_inventory.redraw_inventory()
	Inventory.update_player_inventory.rpc_id(1, inventory.net_encode())

func _physics_process(delta: float) -> void:
	if grabbed_slot.visible:
		grabbed_slot.global_position = get_global_mouse_position() + Vector2(8,	8)

func receive_command(index: int, action: InventoryCommand):
	print(action.as_string())
