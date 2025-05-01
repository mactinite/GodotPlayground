extends Resource
class_name ItemDB

@export var items: Array[InventoryItem]

var item_dict: Dictionary[int, InventoryItem]


func _generate_item_dict(items: Array[InventoryItem]) -> Dictionary[int, InventoryItem]:
		item_dict = {}
		for item in items:
			# generating a hash map for quick lookup and referencing
			item_dict.set(item.get_hash(), item)
		return item_dict

func get_item(hash: int) -> InventoryItem:
	if item_dict.has(hash):
		return item_dict[hash]
	else:
		return null
