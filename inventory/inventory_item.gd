extends Resource
class_name InventoryItem
@export var name: String
@export_multiline var desc: String
@export var icon: Texture2D
@export var stackable: bool
@export var max_stack: int = 100
# Generates a 32 bit hash using the name and path of the resource
# hopefully will not have hash collisions with just a few items
func get_hash() -> int:
	var string =  "%s-%s" % [name, resource_path]
	var _hash = string.hash()
	return _hash
