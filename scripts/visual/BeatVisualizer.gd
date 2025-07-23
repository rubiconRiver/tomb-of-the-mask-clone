class_name BeatVisualizer
extends Node

signal beat_pulse()

# Visual effect intensities
var player_pulse_strength = 0.25
var wall_pulse_strength = 0.1
var coin_pulse_strength = 0.4
var spike_pulse_strength = 0.3
var ui_pulse_strength = 0.15

var beat_time = 0.0
var current_pulse = 0.0
var pulse_decay = 3.0  # How fast the pulse fades

# Colors for different elements
var player_glow_color = Color(0.0, 1.0, 0.8, 1.0)  # Cyan
var wall_glow_color = Color(0.5, 0.0, 1.0, 1.0)   # Purple
var coin_glow_color = Color(1.0, 0.9, 0.0, 1.0)   # Gold
var spike_glow_color = Color(1.0, 0.0, 0.3, 1.0)  # Red

# Shader materials
var techno_shader = preload("res://shaders/techno_pulse.gdshader")
var wall_shader = preload("res://shaders/tetris_effect_wall.gdshader")
var player_material: ShaderMaterial
var wall_material: ShaderMaterial
var coin_material: ShaderMaterial
var spike_material: ShaderMaterial

func _ready():
	# Create shader materials for each element type
	player_material = ShaderMaterial.new()
	player_material.shader = techno_shader
	player_material.set_shader_parameter("glow_color", player_glow_color)
	player_material.set_shader_parameter("pulse_strength", player_pulse_strength)
	
	wall_material = ShaderMaterial.new()
	wall_material.shader = wall_shader
	wall_material.set_shader_parameter("base_color", Color("#dcfb94"))  # Light green
	wall_material.set_shader_parameter("glow_color", Color(0.0, 0.74, 0.83, 1.0))  # Cyan
	wall_material.set_shader_parameter("accent_color", Color(0.91, 0.12, 0.39, 1.0))  # Magenta
	wall_material.set_shader_parameter("glow_intensity", 0.8)
	wall_material.set_shader_parameter("edge_softness", 0.1)
	wall_material.set_shader_parameter("pattern_scale", 4.0)
	wall_material.set_shader_parameter("flow_speed", 0.5)
	
	coin_material = ShaderMaterial.new()
	coin_material.shader = techno_shader
	coin_material.set_shader_parameter("glow_color", coin_glow_color)
	coin_material.set_shader_parameter("pulse_strength", coin_pulse_strength)
	coin_material.set_shader_parameter("glow_strength", 1.0)
	
	spike_material = ShaderMaterial.new()
	spike_material.shader = techno_shader
	spike_material.set_shader_parameter("glow_color", spike_glow_color)
	spike_material.set_shader_parameter("pulse_strength", spike_pulse_strength)
	spike_material.set_shader_parameter("glow_strength", 0.8)

func _process(delta):
	# Update pulse based on beat
	if current_pulse > 0:
		current_pulse = max(0, current_pulse - delta * pulse_decay)
		_update_all_materials()

func trigger_beat(_beat_count: int):
	current_pulse = 1.0
	beat_pulse.emit()
	_update_all_materials()

func _update_all_materials():
	# Update shader parameters with current pulse
	var pulse_multiplier = _ease_out_cubic(current_pulse)
	
	if player_material:
		player_material.set_shader_parameter("pulse_strength", player_pulse_strength * pulse_multiplier)
		player_material.set_shader_parameter("glow_strength", 0.5 + 0.5 * pulse_multiplier)
	
	if wall_material:
		wall_material.set_shader_parameter("beat_pulse", pulse_multiplier)
		wall_material.set_shader_parameter("beat_time", beat_time)
		wall_material.set_shader_parameter("glow_intensity", 0.6 + 0.4 * pulse_multiplier)
	
	if coin_material:
		coin_material.set_shader_parameter("pulse_strength", coin_pulse_strength * pulse_multiplier)
		coin_material.set_shader_parameter("glow_strength", 0.8 + 0.4 * pulse_multiplier)
	
	if spike_material:
		spike_material.set_shader_parameter("pulse_strength", spike_pulse_strength * pulse_multiplier)
		spike_material.set_shader_parameter("glow_strength", 0.6 + 0.4 * pulse_multiplier)

func _ease_out_cubic(t: float) -> float:
	return 1.0 - pow(1.0 - t, 3.0)

func get_material_for_type(type: String) -> ShaderMaterial:
	match type:
		"player":
			return player_material
		"wall":
			return wall_material
		"coin":
			return coin_material
		"spike":
			return spike_material
		_:
			return null

func set_element_importance(type: String, importance: float):
	# Adjust pulse strength based on importance (0.0 to 1.0)
	match type:
		"player":
			player_pulse_strength = 0.1 + 0.3 * importance
		"wall":
			wall_pulse_strength = 0.05 + 0.1 * importance
		"coin":
			coin_pulse_strength = 0.2 + 0.4 * importance
		"spike":
			spike_pulse_strength = 0.15 + 0.3 * importance