extends Node

var obj: Object = null
var last = Vector3.ZERO
@onready var hold: Node3D = $"../head/Hold"
@onready var interaction_raycast: ShapeCast3D = $"../head/interaction_raycast"
var lerp_speed = 500


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

@rpc("authority", "call_local")
func move_object(path: String, pos: Vector3):
	var node = get_node(path)
	var speed = node.global_transform.origin.distance_to(pos) * lerp_speed
	var dir = node.global_transform.origin.direction_to(pos)
	node.linear_velocity = Vector3.ZERO
	node.apply_central_force(dir*speed)
	

func _physics_process(delta):
	if is_multiplayer_authority():
		if Input.is_action_pressed("fire"):
			if obj == null:
				var collider = interaction_raycast.get_collider(0)
				if collider != null:
					if collider.is_in_group("grab"):
						obj = collider
			
			if obj != null:
				last = obj.global_position
				if obj.is_class("RigidBody3D"):
					move_object.rpc(obj.get_path(), hold.global_position)

		else:
			if obj != null:
				obj = null
			
		
