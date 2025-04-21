extends Resource
class_name ItemDB

@export var items : Array[ItemData]

func get_lookup_table()-> Dictionary:
	var lookupTable = {}
	
	for item in items:
		var hash: String = get_item_hash(item)
		lookupTable[hash] = item
		
	
	return lookupTable

func get_item_hash(item: ItemData) -> String:
	return item.get_hash()
