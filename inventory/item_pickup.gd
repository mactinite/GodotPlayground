extends NetworkRigidBody3D
# like a container but a single slot essentially

@onready var mesh_instance_3d: MeshInstance3D = $MeshInstance3D
@onready var collision_shape_3d: CollisionShape3D = $CollisionShape3D
@export var item_data: ItemData
@export var item_qty: int = 1
@export var item_hash: String

func _ready() -> void:
	if is_multiplayer_authority():
		item_hash = GameManager.get_item_hash(item_data)
		mesh_instance_3d.mesh = item_data.mesh;
		collision_shape_3d.make_convex_from_siblings()
	else:
		gimme_data.rpc_id(1, multiplayer.get_unique_id())
		
func set_item_data_by_id(hash: String) -> void:
	if item_hash.is_empty(): return
	var _item_data = GameManager.get_item_by_hash(hash)
	item_data = _item_data
	mesh_instance_3d.mesh = _item_data.mesh;
	collision_shape_3d.make_convex_from_siblings()

func set_slot_data(slot_data: SlotData):
	item_data = slot_data.item_data
	item_qty = slot_data.quantity
	item_hash = GameManager.get_item_hash(item_data)

func player_interact() -> void:
	if GameManager.player_pickup_slot_data(SlotData.new(item_data, item_qty)):
		self.queue_free()
	pass

@rpc("authority")
func sync_data(hash: String, qty: int)-> void:
	item_hash = hash
	item_qty = qty
	set_item_data_by_id(item_hash)

@rpc("any_peer")
func gimme_data(requester: int)-> void:
	if is_multiplayer_authority():
		sync_data.rpc_id(requester,item_hash, item_qty)
	
