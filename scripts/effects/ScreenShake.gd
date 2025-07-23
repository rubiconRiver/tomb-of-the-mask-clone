extends Node
class_name ScreenShake

# Screen shake singleton for juicy game feedback
signal shake_finished

var camera: Camera2D
var original_position: Vector2
var shake_intensity: float = 0.0
var shake_duration: float = 0.0
var shake_timer: float = 0.0
var shake_frequency: float = 30.0  # Shakes per second
var is_shaking: bool = false

# Shake presets for different events
var SHAKE_PRESETS = {
	"wall_hit": {"intensity": 8.0, "duration": 0.15, "frequency": 40.0},
	"coin_collect": {"intensity": 3.0, "duration": 0.1, "frequency": 25.0},
	"landing": {"intensity": 4.0, "duration": 0.12, "frequency": 35.0},
	"death": {"intensity": 15.0, "duration": 0.4, "frequency": 20.0},
	"level_complete": {"intensity": 6.0, "duration": 0.25, "frequency": 15.0}
}

func _ready():
	set_process(false)  # Only process when shaking

func set_camera(cam: Camera2D):
	camera = cam
	if camera:
		original_position = camera.offset

func _process(delta):
	if not is_shaking or not camera:
		return
	
	shake_timer -= delta
	
	if shake_timer <= 0:
		# Shake finished
		stop_shake()
		return
	
	# Calculate shake offset with decay
	var decay = shake_timer / shake_duration
	var current_intensity = shake_intensity * decay * decay  # Quadratic decay
	
	# Generate random shake offset
	var shake_x = randf_range(-current_intensity, current_intensity)
	var shake_y = randf_range(-current_intensity, current_intensity)
	
	# Apply frequency modulation for more realistic shake
	var time_factor = sin(Time.get_ticks_msec() * 0.001 * shake_frequency)
	shake_x *= time_factor
	shake_y *= time_factor
	
	# Apply shake
	camera.offset = original_position + Vector2(shake_x, shake_y)

func start_shake(intensity: float, duration: float, frequency: float = 30.0):
	if not camera:
		print("Warning: ScreenShake - No camera set")
		return
	
	shake_intensity = intensity
	shake_duration = duration
	shake_timer = duration
	shake_frequency = frequency
	is_shaking = true
	
	set_process(true)

func shake_preset(preset_name: String):
	if not SHAKE_PRESETS.has(preset_name):
		print("Warning: ScreenShake - Unknown preset: ", preset_name)
		return
	
	var preset = SHAKE_PRESETS[preset_name]
	start_shake(preset.intensity, preset.duration, preset.frequency)

func stop_shake():
	is_shaking = false
	shake_timer = 0.0
	set_process(false)
	
	if camera:
		camera.offset = original_position
	
	emit_signal("shake_finished")

func add_trauma(amount: float):
	# Add trauma-based shake (for multiple overlapping effects)
	if is_shaking:
		shake_intensity += amount
		shake_timer = max(shake_timer, 0.2)  # Extend shake slightly
	else:
		start_shake(amount, 0.2)
