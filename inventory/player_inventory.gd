extends Node
@export var inventory_data: InventoryData
@onready var interaction_raycast: ShapeCast3D = $"../head/interaction_raycast"

var ground_loot_selected;

func _ready() -> void:
	if !is_multiplayer_authority():
		return
	
	GameManager.set_inventory(inventory_data)
	
func update_player_inventory(data: InventoryData):
	inventory_data = data
	GameManager.set_inventory(inventory_data)

func _unhandled_input(event: InputEvent) -> void:
	if !is_multiplayer_authority():
		return
	
	if Input.is_action_just_pressed("inventory"):
		GameManager.toggle_inventory()
		
	if Input.is_action_just_pressed("interact"):
		interact()
		
func interact() -> void:
	if interaction_raycast.is_colliding() && interaction_raycast.get_collider(0).is_in_group("loot"):
		interaction_raycast.get_collider(0).player_interact()
