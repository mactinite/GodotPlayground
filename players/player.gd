extends CharacterBody3D

@export var interaction_raycast: RayCast3D

@onready var head: Node3D = $head
@onready var crouch_collision_shape: CollisionShape3D = $crouch_collision_shape
@onready var standing_collision_shape: CollisionShape3D = $standing_collision_shape
@onready var uncrouch_raycast: RayCast3D = $uncrouch_raycast
@onready var camera_3d: Camera3D = $head/Camera3D
@onready var player_grab: Node = $player_grab

var current_speed = 5.0

const walking_speed = 5.0
const sprinting_speed = 7.0
const crouching_speed = 3.0

var crouch_depth = -0.5
var starting_height
const jump_velocity = 4.5

var lerp_speed = 10.0

var direction = Vector3.ZERO;
const mouse_sens = 0.2

var can_control = true

func _ready():
	starting_height = head.position.y
	crouch_collision_shape.disabled = true
	
	if has_meta("id") && GameState.players.has(get_meta("id")):
		GameState.players[get_meta("id")].player_node = self
	
	if is_multiplayer_authority():
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		camera_3d.set_current(true)
		GameState.local_player_object = self
		SignalBus.on_player_spawned.emit(self)
		var spawn = get_tree().get_nodes_in_group("spawn_point").pick_random()
		global_position = spawn.global_position
		Inventory.toggle_player_inventory.connect(func(open):
			if open:
				can_control = false
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			else:
				can_control = true
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		)
	else:
		camera_3d.set_current(false)

	
func _input(event: InputEvent):
	if is_multiplayer_authority() && can_control:
		if event is InputEventMouseMotion:
			rotate_y(deg_to_rad(-event.relative.x * mouse_sens))
			head.rotate_x(deg_to_rad(-event.relative.y * mouse_sens))
			head.rotation.x = clamp(head.rotation.x, deg_to_rad(-89), deg_to_rad(89))
			

func _process(delta: float) -> void:
	if is_multiplayer_authority():
		if Input.is_action_just_pressed("inventory"):
			Inventory.toggle_inventory()


func _physics_process(delta: float) -> void:
	if is_multiplayer_authority():
		movement(delta)
	
func movement(delta: float) -> void:
	if Input.is_action_pressed("crouch") and can_control:
		current_speed = crouching_speed
		head.position.y = lerp(head.position.y, starting_height + crouch_depth, delta * lerp_speed)
		crouch_collision_shape.disabled = false
		standing_collision_shape.disabled = true
	elif !uncrouch_raycast.is_colliding():
		head.position.y = lerp(head.position.y, starting_height, delta * lerp_speed)
		crouch_collision_shape.disabled = true
		standing_collision_shape.disabled = false
	
		if Input.is_action_pressed("sprint"):
			current_speed = sprinting_speed
		else:
			current_speed = walking_speed
	
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor() and can_control:
		velocity.y = jump_velocity

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("left", "right", "forward", "backward") if can_control else Vector2.ZERO
	direction = lerp(direction, (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(), delta * lerp_speed)
	
	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)

	move_and_slide()


func get_drop_position() -> Vector3:
	var direction = - camera_3d.global_transform.basis.z
	return camera_3d.global_position + direction
