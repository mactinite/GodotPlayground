class_name InventoryCommand
var index: int
var quantity: int
var item_hash: int
var action: INVENTORY_ACTION

enum INVENTORY_ACTION {
	PLACE,
	REMOVE
}

func as_string() -> String:
	return "%sx %s %s @ %s" % [ quantity, item_hash, action, index]
