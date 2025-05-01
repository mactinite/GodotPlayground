extends Resource
class_name InventoryData


@export var slots: Array[InventorySlot]



# encodes (hopefully) an instance into a network serializable size
func net_encode()-> Array:
	var encoded_array: Array
	for slot in slots:
		encoded_array.append(slot.net_encode() if slot else null)
		
	print(encoded_array)
	return encoded_array

# creates a new instance of InventoryData
static func net_decode(encoded_array: Array) -> InventoryData:
	var inventory: InventoryData = InventoryData.new()
	for encoded_slot in encoded_array:
		var instanced_slot = InventorySlot.net_decode(encoded_slot if encoded_slot else [])
		inventory.slots.append(instanced_slot)
	return inventory
