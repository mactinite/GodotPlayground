extends Resource
class_name InventoryData


signal on_remote_inventory_changes(inventory_data:InventoryData)
signal inventory_updated(inventory_data:InventoryData)
signal inventory_interact(inventory_data:InventoryData,index: int, button: int)

@export var slot_datas: Array[SlotData]

func grab_slot_data(index: int) -> SlotData:
	var slot_data = slot_datas[index]
	
	if slot_data:
		slot_datas[index] = null
		inventory_updated.emit(self)
	return slot_data
	
# drop as in drag and dro
func drop_slot_data(grabbed_slot_data: SlotData, index: int) -> SlotData:
	var slot_data = slot_datas[index]
	var return_slot_data: SlotData
	
	if slot_data and slot_data.can_merge_with(grabbed_slot_data):
		return_slot_data = slot_data.merge_with(grabbed_slot_data)
	elif !slot_data || slot_data.is_empty():
		slot_datas[index] = grabbed_slot_data
	else:
		return_slot_data = slot_datas[index]
		slot_datas[index] = grabbed_slot_data
	
	inventory_updated.emit(self)
	return return_slot_data

# drop as in drag and drop
func drop_single_slot_data(grabbed_slot_data: SlotData, index: int) -> SlotData:
	var slot_data = slot_datas[index]
	if not slot_data:
		slot_datas[index] = grabbed_slot_data.create_single_slot_data()
	elif slot_data.can_merge_with(grabbed_slot_data):
		slot_data.merge_with(grabbed_slot_data.create_single_slot_data())
	
	inventory_updated.emit(self)
	
	if grabbed_slot_data.quantity > 0:
		return grabbed_slot_data
	else:
		return null

func on_slot_clicked(index: int, button: int)-> void:
	inventory_interact.emit(self, index, button)
	
func pick_up_slot_data(slot_data: SlotData) -> bool:
	
	for index in slot_datas.size():
		if slot_datas[index] && \
		slot_datas[index].can_fully_merge_with(slot_data):
			
			slot_datas[index].merge_with(slot_data)
			inventory_updated.emit(self)
			return true
	
	for index in slot_datas.size():
		if !slot_datas[index]:
			slot_datas[index] = slot_data
			inventory_updated.emit(self)
			return true

	return false

func serialize() -> Array:
	var arr = []
	for slot in slot_datas:
		if slot:
			var encoded_slot = slot.encode()
			arr.append(encoded_slot)
		else:
			arr.append(null)
	return arr
	
	
func deserialize(serializedArray: Array)-> void:
	slot_datas.clear()
	for encoded_slot in serializedArray:
		if encoded_slot:
			slot_datas.append(SlotData.decode(encoded_slot))
		else:
			slot_datas.append(null)
	on_remote_inventory_changes.emit(self)
