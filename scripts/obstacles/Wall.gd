extends StaticBody2D

var particle_scene = preload("res://scenes/effects/WallParticles.tscn")
var particles: GPUParticles2D

func _ready():
	# Apply themed wall texture
	var sprite = $Sprite2D
	if sprite:
		# Try to get themed texture first
		var themed_texture = VisualThemeManager.get_wall_texture()
		
		if themed_texture:
			sprite.texture = themed_texture
		else:
			# Fallback: Generate wall texture with solid color and transparent border
			var image = Image.create(64, 64, false, Image.FORMAT_RGBA8)
			var wall_color = Color("#dcfb94")  # Light green color
			
			# Fill entire image with transparent first
			image.fill(Color.TRANSPARENT)
			
			# Fill inner area (leaving 1px border transparent)
			for y in range(1, 63):
				for x in range(1, 63):
					image.set_pixel(x, y, wall_color)
			
			var texture = ImageTexture.create_from_image(image)
			sprite.texture = texture
		
		sprite.modulate = Color.WHITE
	
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