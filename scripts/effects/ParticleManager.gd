extends Node
class_name ParticleManager

# Centralized particle system manager for consistent effects across the game

var wall_hit_particles: PackedScene
var landing_particles: PackedScene
var dust_particles: PackedScene

func _ready():
	# Initialize particle scenes
	create_particle_scenes()

func create_particle_scenes():
	# Create reusable particle configurations
	wall_hit_particles = create_wall_hit_scene()
	landing_particles = create_landing_scene()
	dust_particles = create_dust_scene()

func create_wall_hit_scene() -> PackedScene:
	var scene = PackedScene.new()
	var particles = GPUParticles2D.new()
	var material = ParticleProcessMaterial.new()
	
	# Configure wall hit particles
	particles.emitting = false
	particles.amount = 20
	particles.lifetime = 0.8
	particles.one_shot = true
	
	# Burst pattern
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	material.direction = Vector3(0, -1, 0)
	material.initial_velocity_min = 60.0
	material.initial_velocity_max = 120.0
	material.angular_velocity_min = -180.0
	material.angular_velocity_max = 180.0
	material.spread = 60.0
	
	# Visual properties
	material.scale_min = 0.3
	material.scale_max = 0.8
	material.color = Color("#dcfb94")  # Match wall color
	material.color_ramp = create_dust_fade_ramp()
	
	# Physics
	material.gravity = Vector3(0, 98, 0)
	material.linear_accel_min = -30.0
	material.linear_accel_max = 30.0
	
	particles.process_material = material
	particles.texture = create_dust_texture()
	
	scene.pack(particles)
	return scene

func create_landing_scene() -> PackedScene:
	var scene = PackedScene.new()
	var particles = GPUParticles2D.new()
	var material = ParticleProcessMaterial.new()
	
	# Configure landing particles (subtle ground impact)
	particles.emitting = false
	particles.amount = 8
	particles.lifetime = 0.4
	particles.one_shot = true
	
	# Ground spread pattern
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	material.direction = Vector3(0, -1, 0)
	material.initial_velocity_min = 20.0
	material.initial_velocity_max = 40.0
	material.spread = 30.0
	
	# Subtle visual properties
	material.scale_min = 0.2
	material.scale_max = 0.5
	material.color = Color("#94fbe6")  # Match player color
	material.color_ramp = create_dust_fade_ramp()
	
	# Light physics
	material.gravity = Vector3(0, 50, 0)
	material.linear_accel_min = -15.0
	material.linear_accel_max = 15.0
	
	particles.process_material = material
	particles.texture = create_dust_texture()
	
	scene.pack(particles)
	return scene

func create_dust_scene() -> PackedScene:
	var scene = PackedScene.new()
	var particles = GPUParticles2D.new()
	var material = ParticleProcessMaterial.new()
	
	# Configure generic dust particles
	particles.emitting = false
	particles.amount = 12
	particles.lifetime = 0.6
	particles.one_shot = true
	
	# Dust cloud pattern
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	material.direction = Vector3(0, -1, 0)
	material.initial_velocity_min = 30.0
	material.initial_velocity_max = 60.0
	material.spread = 45.0
	
	# Dust visual properties
	material.scale_min = 0.3
	material.scale_max = 0.7
	material.color = Color(0.7, 0.7, 0.7, 0.6)  # Gray dust
	material.color_ramp = create_dust_fade_ramp()
	
	# Floating physics
	material.gravity = Vector3(0, 20, 0)
	material.linear_accel_min = -10.0
	material.linear_accel_max = 10.0
	
	particles.process_material = material
	particles.texture = create_dust_texture()
	
	scene.pack(particles)
	return scene

func create_dust_fade_ramp() -> Gradient:
	var gradient = Gradient.new()
	gradient.add_point(0.0, Color(1, 1, 1, 0.8))  # Start visible
	gradient.add_point(0.3, Color(1, 1, 1, 0.6))  # Maintain opacity
	gradient.add_point(1.0, Color(1, 1, 1, 0))    # Fade to transparent
	return gradient

func create_dust_texture() -> ImageTexture:
	var image = Image.create(8, 8, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	
	# Create soft circular dust particle
	var center = 4
	for y in range(8):
		for x in range(8):
			var dist = Vector2(x - center, y - center).length()
			if dist <= 3.0:
				var alpha = 1.0 - (dist / 3.0)  # Soft edge
				image.set_pixel(x, y, Color(1, 1, 1, alpha))
	
	return ImageTexture.create_from_image(image)

# Spawn particle effects at world positions
func spawn_wall_hit(position: Vector2, parent: Node):
	var particles = wall_hit_particles.instantiate()
	parent.add_child(particles)
	particles.global_position = position
	particles.emitting = true
	
	# Auto-cleanup after lifetime
	await get_tree().create_timer(1.0).timeout
	if is_instance_valid(particles):
		particles.queue_free()

func spawn_landing(position: Vector2, parent: Node):
	var particles = landing_particles.instantiate()
	parent.add_child(particles)
	particles.global_position = position
	particles.emitting = true
	
	await get_tree().create_timer(0.6).timeout
	if is_instance_valid(particles):
		particles.queue_free()

func spawn_dust(position: Vector2, parent: Node, color: Color = Color.WHITE):
	var particles = dust_particles.instantiate()
	parent.add_child(particles)
	particles.global_position = position
	
	# Optionally tint the dust
	if color != Color.WHITE:
		particles.process_material.color = color
	
	particles.emitting = true
	
	await get_tree().create_timer(0.8).timeout
	if is_instance_valid(particles):
		particles.queue_free()