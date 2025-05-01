extends Node
class_name InventoryContainer

@export var inventory_data: InventoryData

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func interact() -> void:
	Inventory.open_container(self)
