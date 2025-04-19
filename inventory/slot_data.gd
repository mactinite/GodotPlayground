extends Resource
class_name SlotData

const MAX_STACK_SIZE: int = 99

@export var item_data: ItemData
@export_range(1,MAX_STACK_SIZE) var quantity:int = 1: set = set_quantity

func can_fully_merge_with(other_slot_data: SlotData) -> bool:
	return item_data == other_slot_data.item_data \
			&& item_data.stackable \
			&& quantity + other_slot_data.quantity < MAX_STACK_SIZE

func is_empty() -> bool:
	return item_data == null

func can_merge_with(other_slot_data: SlotData) -> bool:
	return item_data == other_slot_data.item_data \
			&& item_data.stackable \
			&& quantity < MAX_STACK_SIZE
				
func merge_with(other_slot_data: SlotData)-> SlotData:
	var remainder: int = 0
	var return_slot_data: SlotData = null
	quantity += other_slot_data.quantity
	if quantity > MAX_STACK_SIZE:
		remainder = quantity - MAX_STACK_SIZE
		quantity = MAX_STACK_SIZE
		return_slot_data = other_slot_data.duplicate()
		return_slot_data.set_quantity(max(1,remainder))
		
	return return_slot_data

func create_single_slot_data() -> SlotData:
	var new_slot_data = duplicate()
	new_slot_data.quantity = 1
	quantity -= 1
	return new_slot_data

func set_quantity(value: int) -> void: 
	quantity = value
	if quantity > 1 and not item_data.stackable:
		quantity = 1
		push_error("%s is not stackable" % item_data.name)
