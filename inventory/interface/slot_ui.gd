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
	return data.has("inventory") and data.has("slot_index")

func _drop_data(_pos, data):
	if _can_drop_data(_pos, data):
		# Move the item from the source to this slot
		data["inventory"].move_to(data["slot_index"], parent_inventory, slot_index)
