extends Panel
class_name SlotUI

signal on_left_click_down()
signal on_right_click_down()

signal on_left_click_released()
signal on_right_click_released()

@export var icon: TextureRect
@export var label: Label
@export var disabled_color: Color
@export var hovered_color: Color
@export var disabled = false:
	set(value):
		disabled = value
		_update_components()

var slot_data: InventorySlot:
	set(value):
		slot_data = value
		_update_components()

var baseColor: Color
var hovered: bool
var slot_index: int
var parent_inventory: InventoryData

func _ready() -> void:
	baseColor = modulate

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _update_components() -> void:
	if slot_data && slot_data.item:
		icon.texture = slot_data.item.icon
		icon.visible = true
		label.visible = slot_data.item.stackable
		label.text = str(slot_data.count)
	else:
		icon.visible = false
		label.visible = false
	
	if disabled:
		icon.modulate = disabled_color
	else:
		icon.modulate = Color.WHITE


func _on_mouse_entered() -> void:
	modulate = hovered_color
	hovered = true
	pass # Replace with function body.


func _on_mouse_exited() -> void:
	modulate = baseColor
	hovered = false
	pass # Replace with function body.


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		match [event.is_pressed(), event.button_index]:
			[true, MOUSE_BUTTON_LEFT]:
				on_left_click_down.emit()
			[false, MOUSE_BUTTON_LEFT]:
				on_left_click_released.emit()
			[true, MOUSE_BUTTON_RIGHT]:
				on_right_click_down.emit()
			[false, MOUSE_BUTTON_RIGHT]:
				on_right_click_released.emit()

func _get_drag_data(_pos):
	if slot_data && slot_data.item:
		var drag_preview = duplicate()
		set_drag_preview(drag_preview)
		return {
			"inventory": parent_inventory,
			"slot_index": slot_index
		}

func _can_drop_data(_pos, data):
	if !(data.has("inventory") and data.has("slot_index")):
		return false
	var source_slot: InventorySlot = data["inventory"].slots[data["slot_index"]]
	if !slot_data or !slot_data.item or !source_slot or !source_slot.item:
		return true # Allow moving to empty or from empty
	# Check for stackable and same item
	return slot_data.item.stackable and source_slot.item.stackable and slot_data.item.get_hash() == source_slot.item.get_hash()

func _drop_data(_pos, data):
	if _can_drop_data(_pos, data):
		var source_inventory = data["inventory"]
		var source_index = data["slot_index"]
		var source_slot: InventorySlot = source_inventory.slots[source_index]
		if slot_data and slot_data.item and source_slot and source_slot.item and slot_data.item.get_hash() == source_slot.item.get_hash() and slot_data.item.stackable:
			# Merge stacks
			var total = slot_data.count + source_slot.count
			var max_stack = slot_data.item.max_stack
			if total <= max_stack:
				slot_data.count = total
				source_inventory.slots[source_index] = null
			else:
				slot_data.count = max_stack
				source_slot.count = total - max_stack
				source_inventory.slots[source_index] = source_slot
			parent_inventory.inventory_changed.emit()
			source_inventory.inventory_changed.emit()
		else:
			# Move as normal
			source_inventory.move_to(source_index, parent_inventory, slot_index)
