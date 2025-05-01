
extends Resource
class_name InventorySlot

@export var item : InventoryItem
@export var count : int
	
func net_encode() -> Array:
	if item:
		return [item.get_hash(), count]
	else:
		return [null, 0]


static func net_decode(encoded_data: Array) -> InventorySlot:
	if encoded_data.size() == 0:
		return null
	
	var inventory_slot = InventorySlot.new()
	if encoded_data.size() == 2:
		inventory_slot = InventorySlot.new()
		inventory_slot.item = Inventory.item_db.get_item(encoded_data[0])
		inventory_slot.count = encoded_data[1]
		
	return inventory_slot
