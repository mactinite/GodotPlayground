extends Resource
class_name InventoryData

signal inventory_changed

@export var slots: Array[InventorySlot]

# Moves a slot from this inventory to another (or itself)
func move_to(index_a: int, other_inventory: InventoryData, index_b: int) -> void:
	var temp = other_inventory.slots[index_b]
	other_inventory.slots[index_b] = self.slots[index_a]
	self.slots[index_a] = temp
	self.inventory_changed.emit()
	if other_inventory != self:
		other_inventory.inventory_changed.emit()

# Updates slots in-place from network data (preserves signals)
func update_from_network(encoded_array: Array) -> void:
	slots.clear()
	for encoded_slot in encoded_array:
		var instanced_slot = InventorySlot.net_decode(encoded_slot if encoded_slot else [])
		slots.append(instanced_slot)
	inventory_changed.emit()

# encodes (hopefully) an instance into a network serializable size
func net_encode() -> Array:
	var encoded_array: Array
	for slot in slots:
		encoded_array.append(slot.net_encode() if slot else null)
	return encoded_array

# creates a new instance of InventoryData
static func net_decode(encoded_array: Array) -> InventoryData:
	var inventory: InventoryData = InventoryData.new()
	for encoded_slot in encoded_array:
		var instanced_slot = InventorySlot.net_decode(encoded_slot if encoded_slot else [])
		inventory.slots.append(instanced_slot)
	return inventory
