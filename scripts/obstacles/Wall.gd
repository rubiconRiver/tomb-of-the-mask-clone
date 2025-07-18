extends StaticBody2D

var particle_scene = preload("res://scenes/effects/WallParticles.tscn")
var particles: GPUParticles2D

func _ready():
	# Generate smooth wall texture
	var sprite = $Sprite2D
	if sprite:
		# For now, just use a simple white square that the shader will process
		var image = Image.create(64, 64, false, Image.FORMAT_RGBA8)
		image.fill(Color.WHITE)
		var texture = ImageTexture.create_from_image(image)
		sprite.texture = texture
		
		# The material will be applied by the LevelGenerator via BeatVisualizer
		sprite.modulate = Color.WHITE  # Remove the gray tint
	
	# Add particle system
	particles = particle_scene.instantiate()
	add_child(particles)
	
	# Connect to beat system if available
	var game_manager = get_tree().get_first_node_in_group("game_manager")
	if game_manager and game_manager.has_signal("beat_occurred"):
		game_manager.beat_occurred.connect(_on_beat)

func _on_beat():
	if particles and randf() < 0.3:  # 30% chance to emit particles on beat
		particles.restart()
		particles.emitting = true