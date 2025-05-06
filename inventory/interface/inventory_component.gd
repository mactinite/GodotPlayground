extends Panel
class_name InventoryComponent

signal on_slot_click_down(int)
signal on_slot_click_up(int)
# returns slot id when hovered and -1 when exiting
signal on_slot_hovered(int)

@export var slot_scene: PackedScene = preload("res://inventory/interface/slot_ui.tscn")
@onready var grid_container: GridContainer = $MarginContainer/GridContainer
@onready var grabbed_slot: SlotUI = $"../GrabbedSlot"


var inventory_data: InventoryData: 
	set(value):
		inventory_data = value
		redraw_inventory()
		pass

func redraw_inventory() -> void:
	for child in grid_container.get_children():
		child.queue_free()
	
	if !inventory_data: return
	
	for i in inventory_data.slots.size():
		var slot_ui: SlotUI = slot_scene.instantiate()
		slot_ui.slot_data = inventory_data.slots[i]
		slot_ui.slot_index = i
		slot_ui.parent_inventory = inventory_data

		slot_ui.mouse_entered.connect(func():
			on_slot_hovered.emit(i)
		)
		
		slot_ui.mouse_exited.connect(func():
			on_slot_hovered.emit(-1)
		)
		
		grid_container.add_child(slot_ui)
	pass
