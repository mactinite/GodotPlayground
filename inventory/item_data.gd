extends Resource
class_name ItemData

@export var name: String = ""
@export_multiline var description: String = ""
@export var stackable: bool = false
@export var texture: Texture
@export var mesh: Mesh


func get_hash() -> String:
	var stringToHash = name + description + resource_path
	return stringToHash.sha256_text()
