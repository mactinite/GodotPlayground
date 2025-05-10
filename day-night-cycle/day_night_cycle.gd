extends Node3D

@export var world_environment: WorldEnvironment
@export var sun_light: DirectionalLight3D
@export var day_material: ShaderMaterial
@export var night_material: ShaderMaterial


var time_of_day := 0.0 # 0.0 = midnight, 0.5 = noon, 1.0 = next midnight
const SECONDS_PER_DAY := 60.0 # 1 min real time = 1 day (24h)

# Sun and moon light settings
@export var sun_color: Color = Color(1.0, 0.95, 0.8)
@export var moon_color: Color = Color(0.7, 0.8, 1.0)
@export var sun_energy: float = 1.0
@export var moon_energy: float = 0.2


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

@export var day_night_curve: Curve

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	time_of_day += delta / SECONDS_PER_DAY
	time_of_day = fmod(time_of_day, 1.0)
	_update_sky_shader()
	_update_sun_rotation()

func _get_blend() -> float:
	# Use the curve to control the blend factor (0 = night, 1 = day)
	if day_night_curve:
		return clamp(day_night_curve.sample(time_of_day), 0.0, 1.0)
	else:
		return clamp(sin(time_of_day * PI * 2.0 - PI / 2.0) * 0.5 + 0.5, 0.0, 1.0)

func _update_sky_shader():
	# Blend factor: 0 = night, 1 = day, smooth transition
	var blend: float = _get_blend()
	# Debug: print blend value
	#print("Blend factor: ", blend)
	var env = world_environment.environment
	if env and env.sky and env.sky.sky_material and env.sky.sky_material is ShaderMaterial and day_material and night_material:
		var mat: ShaderMaterial = env.sky.sky_material
		for parameter in mat.shader.get_shader_uniform_list():
			var day_val = day_material.get_shader_parameter(parameter.name)
			var night_val = night_material.get_shader_parameter(parameter.name)
			var val = day_val
			if typeof(day_val) in [TYPE_FLOAT, TYPE_INT, TYPE_COLOR]:
				val = lerp(night_val, day_val, blend)
			mat.set_shader_parameter(parameter.name, val)

func _update_sun_rotation():
	if sun_light:
		# 0.0 = midnight (below horizon), 0.25 = sunrise, 0.5 = noon, 0.75 = sunset
		var sun_angle = time_of_day * 360.0 + 90.0
		# Sun moves in X axis (pitch)
		sun_light.rotation_degrees.x = sun_angle
