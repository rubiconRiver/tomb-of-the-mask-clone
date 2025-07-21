extends Node2D
class_name GridStarEffect

# Creates 4-point stars at grid intersections when background grid reaches peak brightness

var grid_size: float = 64.0
var star_particles: Array[Node2D] = []
var viewport_size: Vector2
var star_pool: Array[Node2D] = []  # Object pool for performance
var pool_size: int = 100

# Star configuration
var star_color = Color("#94fbe6")  # Cyan like the grid
var star_size: float = 8.0
var star_lifetime: float = 0.8
var stars_per_beat: int = 12

# Grid pulse tracking
var last_beat_time: float = 0.0
var beat_threshold: float = 0.1  # Time window to consider as "peak brightness"

func _ready():
	viewport_size = get_viewport().get_visible_rect().size
	initialize_star_pool()
	connect_to_audio_system()

func initialize_star_pool():
	# Pre-create star objects for performance
	for i in range(pool_size):
		var star = create_star_node()
		star.visible = false
		add_child(star)
		star_pool.append(star)

func create_star_node() -> Node2D:
	var star_container = Node2D.new()
	
	# Store star properties
	star_container.set_meta("lifetime", 0.0)
	star_container.set_meta("max_lifetime", star_lifetime)
	star_container.set_meta("base_scale", randf_range(0.5, 1.5))
	
	return star_container

func _draw():
	# Draw all active stars
	for star in star_particles:
		if star.visible:
			draw_star_at_position(star)

func draw_star_at_position(star: Node2D):
	var center = Vector2.ZERO
	var lifetime_ratio = star.get_meta("lifetime", 0.0) / star.get_meta("max_lifetime", 1.0)
	var alpha = 1.0 - lifetime_ratio  # Fade out over time
	var scale = star.get_meta("base_scale", 1.0) * star.scale.x
	
	# 4-point star shape (diamond with extended points)
	var outer_size = star_size * scale
	var inner_size = outer_size * 0.3
	
	var points = PackedVector2Array([
		center + Vector2(0, -outer_size),        # Top point
		center + Vector2(inner_size * 0.3, -inner_size * 0.3),  # Top-right inner
		center + Vector2(outer_size, 0),         # Right point
		center + Vector2(inner_size * 0.3, inner_size * 0.3),   # Bottom-right inner
		center + Vector2(0, outer_size),         # Bottom point
		center + Vector2(-inner_size * 0.3, inner_size * 0.3),  # Bottom-left inner
		center + Vector2(-outer_size, 0),        # Left point
		center + Vector2(-inner_size * 0.3, -inner_size * 0.3)  # Top-left inner
	])
	
	# Transform points to star's world position
	var transformed_points = PackedVector2Array()
	for point in points:
		transformed_points.append(point + star.global_position)
	
	var color = Color(star_color.r, star_color.g, star_color.b, star_color.a * alpha)
	draw_colored_polygon(transformed_points, color)
	
	# Optional glow effect
	if alpha > 0.5:
		var glow_points = PackedVector2Array()
		for point in transformed_points:
			var direction = (point - star.global_position).normalized()
			glow_points.append(point + direction * 2)
		var glow_color = Color(star_color.r, star_color.g, star_color.b, (alpha - 0.5) * 0.3)
		draw_colored_polygon(glow_points, glow_color)

func connect_to_audio_system():
	# Connect to AudioManager beat signal
	if AudioManager:
		if AudioManager.has_signal("beat_occurred"):
			AudioManager.beat_occurred.connect(_on_beat)

func _on_beat(beat_count: int):
	# Create stars at grid intersections when grid reaches peak brightness
	var current_time = Time.get_ticks_msec() * 0.001
	last_beat_time = current_time
	
	# Create stars on 4th beats (whole notes) when grid pulses strongest
	var beat_in_measure = beat_count % 4
	if beat_in_measure == 0:  # Every 4th beat (0, 4, 8, etc.)
		create_grid_stars()
		queue_redraw()  # Trigger redraw for stars

func create_grid_stars():
	# Calculate grid intersection points within viewport
	var grid_intersections = get_visible_grid_intersections()
	
	# Randomly select subset of intersections for stars
	var selected_points = select_random_intersections(grid_intersections, stars_per_beat)
	
	# Create stars at selected points
	for point in selected_points:
		spawn_star_at_position(point)

func get_visible_grid_intersections() -> Array[Vector2]:
	var intersections: Array[Vector2] = []
	
	# Get camera position to offset grid
	var camera_offset = Vector2.ZERO
	var camera = get_viewport().get_camera_2d()
	if camera:
		camera_offset = camera.global_position - viewport_size / 2
	
	# Calculate grid bounds with camera offset
	var start_x = int((camera_offset.x) / grid_size) * grid_size
	var start_y = int((camera_offset.y) / grid_size) * grid_size
	var end_x = start_x + viewport_size.x + grid_size
	var end_y = start_y + viewport_size.y + grid_size
	
	# Generate intersection points
	var x = start_x
	while x <= end_x:
		var y = start_y
		while y <= end_y:
			intersections.append(Vector2(x, y))
			y += grid_size
		x += grid_size
	
	return intersections

func select_random_intersections(intersections: Array[Vector2], count: int) -> Array[Vector2]:
	var selected: Array[Vector2] = []
	var available = intersections.duplicate()
	
	for i in range(min(count, available.size())):
		var index = randi() % available.size()
		selected.append(available[index])
		available.remove_at(index)
	
	return selected

func spawn_star_at_position(position: Vector2):
	var star = get_pooled_star()
	if not star:
		return  # Pool exhausted
	
	# Position star
	star.global_position = position
	star.visible = true
	
	# Reset properties
	star.set_meta("lifetime", 0.0)
	star.set_meta("max_lifetime", star_lifetime + randf_range(-0.2, 0.2))  # Slight variation
	star.scale = Vector2.ZERO  # Start invisible
	star.modulate = Color.WHITE
	
	# Animate star appearance
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Scale up quickly then down slowly
	tween.tween_property(star, "scale", Vector2.ONE * star.get_meta("base_scale", 1.0), 0.1)
	tween.tween_property(star, "scale", Vector2.ZERO, star_lifetime - 0.1).set_delay(0.1)
	
	# Color fade
	tween.tween_property(star, "modulate:a", 0.0, star_lifetime * 0.7).set_delay(star_lifetime * 0.3)
	
	# Add to active list
	star_particles.append(star)
	
	# Auto-cleanup
	await tween.finished
	return_star_to_pool(star)

func get_pooled_star() -> Node2D:
	for star in star_pool:
		if not star.visible:
			return star
	return null  # Pool exhausted

func return_star_to_pool(star: Node2D):
	star.visible = false
	star.scale = Vector2.ONE
	star.modulate = Color.WHITE
	
	# Remove from active list
	var index = star_particles.find(star)
	if index >= 0:
		star_particles.remove_at(index)

func _process(delta):
	# Update star lifetimes (backup cleanup)
	var need_redraw = false
	for i in range(star_particles.size() - 1, -1, -1):
		var star = star_particles[i]
		var lifetime = star.get_meta("lifetime", 0.0) + delta
		star.set_meta("lifetime", lifetime)
		
		if lifetime >= star.get_meta("max_lifetime", star_lifetime):
			return_star_to_pool(star)
			need_redraw = true
	
	# Only redraw if something changed
	if need_redraw:
		queue_redraw()

# Configuration functions
func set_star_color(color: Color):
	star_color = color

func set_star_density(density: int):
	stars_per_beat = clamp(density, 1, 30)

func set_star_size(size: float):
	star_size = clamp(size, 4.0, 20.0)

func set_star_lifetime(lifetime: float):
	star_lifetime = clamp(lifetime, 0.2, 2.0)

func trigger_manual_stars():
	# Manual trigger for testing
	create_grid_stars()

# Reactive to audio analysis
func set_audio_reactive(enabled: bool):
	if enabled:
		# Could connect to audio analyzer for frequency-based star variations
		var game_manager = get_tree().get_first_node_in_group("game_manager")
		if game_manager and game_manager.get("audio_analyzer"):
			var analyzer = game_manager.audio_analyzer
			if analyzer.has_signal("beat_detected"):
				analyzer.beat_detected.connect(_on_audio_beat_detected)

func _on_audio_beat_detected(strength: float, frequency_band: String):
	# Create more/fewer stars based on beat strength
	var original_count = stars_per_beat
	stars_per_beat = int(original_count * (0.5 + strength))
	
	# Restore original count after this beat
	await get_tree().create_timer(0.1).timeout
	stars_per_beat = original_count