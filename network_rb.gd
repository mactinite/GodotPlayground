extends RigidBody3D
class_name NetworkRigidBody3D

enum {
	FRAME,
	ORIGIN,
	QUAT,
	ANG_VEL,
	LIN_VEL,
}

@export var linear_threshold := 0.05
@export var angular_threshold := 0.05
@export var rest_duration := 1.0

var frame_buffer: Array = []
var frame: int = 0

var _rest_timer := 0.0
var _is_resting := false

func _ready() -> void:
	if is_multiplayer_authority():
		freeze = false
	else:
		freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
		freeze = true

func _physics_process(delta: float) -> void:

	#--- 2. If I’m the server/host, send updates ---
	if is_multiplayer_authority():
		frame += 1
		send_frame_data.rpc(_serialize_state())
		return

	#--- 3. Otherwise I’m a client, interpolate in between frames ---
	if frame_buffer.size() == 0:
		return

	if frame_buffer.size() == 1:
		_apply_frame(frame_buffer[0])
	else:
		var a = frame_buffer[0]
		var b = frame_buffer[1]
		var physics_fps = ProjectSettings.get_setting("physics/common/physics_ticks_per_second", 60.0)
		var alpha = clamp(delta * physics_fps, 0.0, 1.0)

		global_transform.origin = a[ORIGIN].lerp(b[ORIGIN], alpha)
		global_transform.basis = Basis(a[QUAT].slerp(b[QUAT], alpha))

		linear_velocity  = b[LIN_VEL]
		angular_velocity = b[ANG_VEL]
	# (no need to call _check_resting here again — we already did it up top)

@rpc("authority", "call_local", "unreliable")
func send_frame_data(frame_data: Array) -> void:
	frame_buffer.append(frame_data)
	if frame_buffer.size() > 2:
		frame_buffer.pop_front()

func _serialize_state() -> Array:
	var frame_data := []
	frame_data.resize(5)
	frame_data[FRAME] = frame
	frame_data[ORIGIN] = global_transform.origin
	frame_data[QUAT] = global_transform.basis.get_rotation_quaternion()
	frame_data[LIN_VEL] = linear_velocity
	frame_data[ANG_VEL] = angular_velocity
	return frame_data

func _apply_frame(frame_data: Array) -> void:
	global_transform.origin = frame_data[ORIGIN]
	global_transform.basis = Basis(frame_data[QUAT])
	linear_velocity = frame_data[LIN_VEL]
	angular_velocity = frame_data[ANG_VEL]
