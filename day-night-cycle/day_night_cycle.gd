extends Node3D

@export var world_environment: WorldEnvironment
@export var sun_light: DirectionalLight3D
@export var day_material: ShaderMaterial
@export var night_material: ShaderMaterial
@export var dusk_material: ShaderMaterial


# Sun and moon light settings
@export var sun_color: Color = Color(1.0, 0.95, 0.8)
@export var moon_color: Color = Color(0.7, 0.8, 1.0)
@export var sun_energy: float = 1.0
@export var moon_energy: float = 0.2

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	TimeManager.time_updated.connect(_on_time_updated)

@export var day_night_curve: Curve

# Utility: 3-way lerp for night, dusk, day
func lerp3(night_val, dusk_val, day_val, t: float) -> Variant:
	# t: 0 = night, 0.5 = dusk, 1 = day
	if t <= 0.5:
		return lerp(night_val, dusk_val, t * 2.0)
	else:
		return lerp(dusk_val, day_val, (t - 0.5) * 2.0)

func _get_blend(time_of_day: float) -> float:
	# Use the curve to control the blend factor (0 = night, 1 = day)
	if day_night_curve:
		return clamp(day_night_curve.sample(time_of_day), 0.0, 1.0)
	else:
		return clamp(sin(time_of_day * PI * 2.0 - PI / 2.0) * 0.5 + 0.5, 0.0, 1.0)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass # Time is now managed by time_manager

func _on_time_updated(time_of_day: float) -> void:
	_update_sky_shader(time_of_day)
	_update_sun_rotation(time_of_day)

func _update_sky_shader(time_of_day: float):
	var blend: float = _get_blend(time_of_day) # 0=night, 0.5=dusk, 1=day
	var env = world_environment.environment
	if env and env.sky and env.sky.sky_material and env.sky.sky_material is ShaderMaterial and day_material and night_material and dusk_material:
		var mat: ShaderMaterial = env.sky.sky_material
		for parameter in mat.shader.get_shader_uniform_list():
			var day_val = day_material.get_shader_parameter(parameter.name)
			var night_val = night_material.get_shader_parameter(parameter.name)
			var dusk_val = dusk_material.get_shader_parameter(parameter.name)
			var val = day_val
			if typeof(day_val) in [TYPE_FLOAT, TYPE_COLOR]:
				val = lerp3(night_val, dusk_val, day_val, float(blend))
			elif typeof(day_val) == TYPE_INT:
				val = int(round(lerp3(float(night_val), float(dusk_val), float(day_val), float(blend))))
			mat.set_shader_parameter(parameter.name, val)

func _update_sun_rotation(time_of_day: float):
	if sun_light:
		var sun_angle = time_of_day * 360.0 + 90.0
		sun_light.rotation_degrees.x = sun_angle
