extends Area2D

var base_scale = Vector2(0.225, 0.225)  # 22.5% of wall size (75% of previous 30%)
var snare_scale = 0.285  # 28.5% size on snare hits (75% of previous 38%)
var tween: Tween
var particles: GPUParticles2D
var coin_color = Color("#94fbe6")  # Light cyan color

func _ready():
	# Create rotated square block (same as wall but rotated 45 degrees)
	var sprite = $Sprite2D
	if sprite:
		# Create higher resolution image for crisp edges
		var image = Image.create(128, 128, false, Image.FORMAT_RGBA8)
		
		# Fill with transparent first
		image.fill(Color.TRANSPARENT)
		
		# Fill solid square (like wall but no border) - centered for crisp rotation
		var border = 16  # 16 pixel border on each side for clean rotation
		for y in range(border, 128 - border):
			for x in range(border, 128 - border):
				image.set_pixel(x, y, coin_color)
		
		var texture = ImageTexture.create_from_image(image)
		sprite.texture = texture
		sprite.modulate = Color.WHITE
		
		# Disable texture filtering for crisp pixel-perfect edges
		texture.set_image(image)
		
		# Apply transformations: 45 degree rotation and 30% scale
		sprite.rotation_degrees = 45
		scale = base_scale
	
	# Create particle system
	particles = GPUParticles2D.new()
	add_child(particles)
	
	# Configure particle system for subtle explosion effect
	var material = ParticleProcessMaterial.new()
	
	# Emission
	particles.emitting = false
	particles.amount = 15  # More particles for better visibility
	particles.lifetime = 1.0  # Longer lifetime
	particles.one_shot = true
	
	# Shape and direction - burst in all directions
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	material.direction = Vector3(0, -1, 0)
	material.initial_velocity_min = 80.0  # Much faster particles
	material.initial_velocity_max = 140.0
	material.angular_velocity_min = -360.0
	material.angular_velocity_max = 360.0
	material.spread = 45.0  # Spread in all directions
	
	# Size and scale - bigger particles
	material.scale_min = 0.5
	material.scale_max = 1.2
	
	# Color and fade
	material.color = coin_color
	material.color_ramp = create_fade_ramp()
	
	# Gravity and physics
	material.gravity = Vector3(0, 30, 0)  # Even less gravity for wider spread
	material.linear_accel_min = -30.0
	material.linear_accel_max = 30.0
	
	particles.process_material = material
	particles.texture = create_particle_texture()
	
	# Connect to beat system
	var game_manager = get_tree().get_first_node_in_group("game_manager")
	if game_manager:
		if game_manager.has_signal("beat_occurred"):
			game_manager.beat_occurred.connect(_on_beat)
		# Also try AudioManager if available
		if AudioManager and AudioManager.has_signal("beat_occurred"):
			AudioManager.beat_occurred.connect(_on_beat)

func _on_beat(beat_count: int = 0):
	# Stop any existing tween
	if tween:
		tween.kill()
	
	# Only animate on snare beats (2,4) - smoother, more apparent animation
	var beat_in_measure = (beat_count % 4) + 1
	
	if beat_in_measure == 2 or beat_in_measure == 4:
		# Create smooth, elastic animation
		tween = create_tween()
		tween.set_parallel(true)  # Allow multiple properties to animate
		
		# Subtle, smooth scale animation
		var target_scale = Vector2(snare_scale, snare_scale)
		tween.tween_property(self, "scale", target_scale, 0.06)
		tween.tween_property(self, "scale", target_scale, 0.06).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
		
		# Gentle return to base size
		await tween.finished
		tween = create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_SINE)
		tween.tween_property(self, "scale", base_scale, 0.2)

func create_fade_ramp() -> Gradient:
	var gradient = Gradient.new()
	gradient.add_point(0.0, Color(1, 1, 1, 1))  # Full opacity at start
	gradient.add_point(0.7, Color(1, 1, 1, 0.8))  # Slight fade
	gradient.add_point(1.0, Color(1, 1, 1, 0))  # Fully transparent at end
	return gradient

func create_particle_texture() -> ImageTexture:
	# Create larger, more visible diamond particle texture
	var image = Image.create(16, 16, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	
	# Larger diamond shape for better visibility
	for y in range(16):
		for x in range(16):
			var dx = abs(x - 8)
			var dy = abs(y - 8)
			if dx + dy <= 6:  # Bigger diamond
				image.set_pixel(x, y, Color.WHITE)
	
	var texture = ImageTexture.create_from_image(image)
	return texture

func trigger_particle_explosion():
	if particles:
		particles.restart()
		particles.emitting = true

func _on_coin_collected():
	# Trigger explosion when coin is collected
	trigger_particle_explosion()
	
	# Hide the coin sprite but keep the particles visible
	var sprite = $Sprite2D
	if sprite:
		sprite.visible = false
	
	# Disable collision so it can't be collected again
	var collision = $CollisionShape2D
	if collision:
		collision.disabled = true
	
	# Wait for particles to finish, then queue_free the coin
	await get_tree().create_timer(1.2).timeout
	queue_free()
