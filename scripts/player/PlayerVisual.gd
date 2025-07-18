extends Node2D

var player_shader = preload("res://shaders/player_orb.gdshader")
var player_material: ShaderMaterial

func _ready():
	# Create the orb material
	player_material = ShaderMaterial.new()
	player_material.shader = player_shader
	
	# Set default colors and parameters
	player_material.set_shader_parameter("core_color", Color(0.0, 1.0, 0.8, 1.0))  # Cyan
	player_material.set_shader_parameter("inner_glow_color", Color(0.0, 0.8, 1.0, 1.0))  # Bright blue
	player_material.set_shader_parameter("outer_glow_color", Color(1.0, 1.0, 1.0, 1.0))  # White
	player_material.set_shader_parameter("core_size", 0.25)
	player_material.set_shader_parameter("inner_glow_size", 0.5)
	player_material.set_shader_parameter("outer_glow_size", 0.8)
	player_material.set_shader_parameter("pulse_strength", 0.2)
	player_material.set_shader_parameter("rotation_speed", 1.0)
	player_material.set_shader_parameter("energy_flow_speed", 2.0)
	player_material.set_shader_parameter("beat_pulse", 0.0)
	
	# Apply to sprite
	var sprite = get_parent().get_node_or_null("Sprite2D")
	if sprite:
		# Create a circular texture for the orb
		var image = Image.create(48, 48, false, Image.FORMAT_RGBA8)
		image.fill(Color.WHITE)
		var texture = ImageTexture.create_from_image(image)
		sprite.texture = texture
		sprite.material = player_material
		sprite.modulate = Color.WHITE

func pulse_on_beat(strength: float = 1.0):
	if player_material:
		var tween = get_tree().create_tween()
		tween.tween_property(player_material, "shader_parameter/beat_pulse", strength, 0.1)
		tween.tween_property(player_material, "shader_parameter/beat_pulse", 0.0, 0.3)

func set_timing_quality_color(quality: int):
	if not player_material:
		return
		
	var colors = {
		0: Color(1.0, 0.0, 1.0, 1.0),  # PERFECT - Magenta
		1: Color(0.0, 1.0, 1.0, 1.0),  # GREAT - Cyan
		2: Color(0.0, 1.0, 0.0, 1.0),  # GOOD - Green
		3: Color(1.0, 1.0, 1.0, 1.0)   # OFF_BEAT - White
	}
	
	if quality in colors:
		var tween = get_tree().create_tween()
		tween.tween_property(player_material, "shader_parameter/core_color", colors[quality], 0.2)
		tween.tween_property(player_material, "shader_parameter/core_color", Color(0.0, 1.0, 0.8, 1.0), 0.5)