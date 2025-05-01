extends Control
class_name InventoryUI

@export var inventory_data: InventoryData
@export var external_data: InventoryData

@onready var inventory: InventoryComponent = $Inventory
@onready var external_inventory: InventoryComponent = $"External Inventory"
@onready var grabbed_slot: SlotUI = $GrabbedSlot

var hovered_index: int = -1
var hovered_inventory: InventoryComponent;

func _ready() -> void:
	
	Inventory.toggle_player_inventory.connect(func(open):
		self.visible = open
	)
	
	Inventory.on_player_inventory_update.connect(func(data: InventoryData):
		inventory_data = data
		inventory.inventory_data = data
		inventory.redraw_inventory()
	)
	
	external_inventory.inventory_data = external_data
	
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
	
	external_inventory.on_slot_click_down.connect(func (index: int):
			var name = external_data.slots[index].item.name if external_data.slots[index] && external_data.slots[index].item else "null"
			if external_data.slots[index]:
				grabbed_slot.slot_data = external_data.slots[index]
				grabbed_slot.visible = true
	)
	external_inventory.on_slot_click_up.connect(func (index: int):
		var name = external_data.slots[index].item.name if external_data.slots[index] && external_data.slots[index].item else "null"
		
		print("Dropping %s from %s:%s on %s;%s" % [name, external_data, index, hovered_inventory, hovered_index])
		
		_swap_slots(external_data, index, hovered_inventory.inventory_data, hovered_index)
		
		grabbed_slot.slot_data = null
		grabbed_slot.visible = false
	)
	
	external_inventory.on_slot_hovered.connect(func(i: int):
		hovered_index = i
		hovered_inventory = external_inventory
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
