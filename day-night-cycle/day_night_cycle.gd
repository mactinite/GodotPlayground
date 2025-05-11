extends Node3D

@export var world_environment: WorldEnvironment
@export var sun_light: DirectionalLight3D
@export var moon_light: DirectionalLight3D

# Sun and moon light settings
@export var sun_color: Color = Color(1.0, 0.95, 0.8)
@export var moon_color: Color = Color(0.7, 0.8, 1.0)
@export var sun_energy: float = 1.0
@export var moon_energy: float = 0.2

@export var moon_phase_textures: Array[Texture2D] = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	TimeManager.time_updated.connect(_on_time_updated)
	_update_moon_texture()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass # Time is now managed by time_manager

func _on_time_updated(time_of_day: float) -> void:
	_update_sun_rotation(time_of_day)
	# Only update moon texture if we're before dusk (e.g., late afternoon)
	if time_of_day >= 0.7 and time_of_day < 0.8:
		_update_moon_texture()

func _get_moon_phase_index() -> int:
	# Simple moon phase calculation: 29.53 days per lunar cycle
	var date = TimeManager.get_date()
	var days_since_epoch = (date["year"] - 2000) * 365 + int((date["year"] - 2000) / 4) # leap years
	for m in range(1, date["month"]):
		days_since_epoch += TimeManager.DAYS_IN_MONTH[m - 1]
		if m == 2 and TimeManager._is_leap_year(date["year"]):
			days_since_epoch += 1
	days_since_epoch += date["day"]
	var lunar_cycle = 29.53
	var phase = fmod(days_since_epoch, lunar_cycle) / lunar_cycle
	if moon_phase_textures.size() == 0:
		return 0
	return int(round(phase * (moon_phase_textures.size() - 1)))

func _update_moon_texture():
	# Always update on first call, or if called at dusk
	if moon_phase_textures.size() == 0:
		return
	var idx = _get_moon_phase_index()
	idx = clamp(idx, 0, moon_phase_textures.size() - 1)
	var env = world_environment.environment
	if env and env.sky and env.sky.sky_material and env.sky.sky_material is ShaderMaterial:
		var mat: ShaderMaterial = env.sky.sky_material
		mat.set_shader_parameter("moon_sampler", moon_phase_textures[idx])

func _update_sun_rotation(time_of_day: float):
	if sun_light:
		var sun_angle = time_of_day * 360.0 + 90.0
		sun_light.rotation_degrees.x = sun_angle
	if moon_light:
		# Moon is opposite the sun (180 degrees apart)
		var moon_angle = fmod(time_of_day * 360.0 + 270.0, 360.0)
		moon_light.rotation_degrees.x = moon_angle
