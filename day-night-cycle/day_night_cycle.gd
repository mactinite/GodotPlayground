extends Node3D

@export var world_environment: WorldEnvironment
@export var sun_light: DirectionalLight3D
@export var moon_light: DirectionalLight3D

# Sun and moon light settings
@export var sun_color: Color = Color(1.0, 0.95, 0.8)
@export var moon_color: Color = Color(0.7, 0.8, 1.0)
@export var sun_energy: float = 1.0
@export var moon_energy: float = 0.2

# The moon texture should be a full moon image (moon_phase=0.5) with a consistent white circle
# The shader will then apply the phase calculation to create the proper crescent shape
@export_range(0.0, 1.0) var moon_texture_phase: float = 0.5 # Default moon phase (0=new, 0.5=full, 1.0=new)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	TimeManager.time_updated.connect(_on_time_updated)
	_configure_lights()
	_update_moon_phase()
	
func _configure_lights() -> void:
	# Set the sun light properties
	if sun_light:
		sun_light.light_color = sun_color
		sun_light.light_energy = sun_energy
		
	# Set the moon light properties
	if moon_light:
		moon_light.light_color = moon_color
		moon_light.light_energy = moon_energy
		
	# Set material tints if available
	var env = world_environment.environment
	if env and env.sky and env.sky.sky_material and env.sky.sky_material is ShaderMaterial:
		var mat: ShaderMaterial = env.sky.sky_material
		mat.set_shader_parameter("sun_tint", sun_color)
		mat.set_shader_parameter("moon_tint", moon_color)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass # Time is now managed by time_manager

func _on_time_updated(time_of_day: float) -> void:
	_update_sun_rotation(time_of_day)
	# Only update moon phase if we're before dusk (e.g., late afternoon)
	if time_of_day >= 0.7 and time_of_day < 0.8:
		_update_moon_phase()

func _get_moon_phase() -> float:
	# Simple moon phase calculation: 29.53 days per lunar cycle
	var date = TimeManager.get_date()
	var days_since_epoch = (date["year"] - 2000) * 365 + int((date["year"] - 2000) / 4) # leap years
	for m in range(1, date["month"]):
		days_since_epoch += TimeManager.DAYS_IN_MONTH[m - 1]
		if m == 2 and TimeManager._is_leap_year(date["year"]):
			days_since_epoch += 1
	days_since_epoch += date["day"]
	var lunar_cycle = 29.53
	# Returns phase between 0.0 and 1.0 (0 = new moon, 0.5 = full moon, 1.0 = new moon again)
	return fmod(days_since_epoch, lunar_cycle) / lunar_cycle

func _update_moon_phase():
	# Calculate the current moon phase and update the shader parameter
	var phase = _get_moon_phase()
	_apply_moon_phase(phase)
		
func set_manual_moon_phase(phase: float) -> void:
	# For debugging or special effects - manually set moon phase
	moon_texture_phase = clamp(phase, 0.0, 1.0)
	_apply_moon_phase(moon_texture_phase)
	
func _apply_moon_phase(phase: float) -> void:
	# Apply moon phase to shader with proper validation
	var env = world_environment.environment
	if env and env.sky and env.sky.sky_material and env.sky.sky_material is ShaderMaterial:
		var mat: ShaderMaterial = env.sky.sky_material
		mat.set_shader_parameter("moon_phase", phase)

func _update_sun_rotation(time_of_day: float):
	if sun_light:
		var sun_angle = time_of_day * 360.0 + 90.0
		sun_light.rotation_degrees.x = sun_angle
	if moon_light:
		# Moon is opposite the sun (180 degrees apart)
		var moon_angle = fmod(time_of_day * 360.0 + 270.0, 360.0)
		moon_light.rotation_degrees.x = moon_angle
