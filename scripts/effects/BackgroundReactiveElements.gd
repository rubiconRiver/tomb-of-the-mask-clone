extends Node2D
class_name BackgroundReactiveElements

# Background elements that react to music and gameplay
var floating_shapes: Array[Node2D] = []
var shape_count: int = 15
var viewport_size: Vector2
var beat_pulse_strength: float = 0.3
var audio_reactive: bool = true

# Shape types and properties
var shape_types = ["triangle", "diamond", "circle", "hexagon"]
var base_colors = [
	Color("#94fbe6"),  # Player cyan
	Color("#dcfb94"),  # Wall green
	Color("#fb94dc"),  # Pink accent
	Color("#94dcfb")   # Blue accent
]

func _ready():
	viewport_size = get_viewport().get_visible_rect().size
	create_floating_shapes()
	connect_to_audio_systems()

func create_floating_shapes():
	for i in range(shape_count):
		var shape = create_reactive_shape(i)
		add_child(shape)
		floating_shapes.append(shape)

func create_reactive_shape(index: int) -> Node2D:
	var shape_container = Node2D.new()
	shape_container.name = "FloatingShape_" + str(index)
	
	# Random position
	var pos = Vector2(
		randf_range(0, viewport_size.x),
		randf_range(0, viewport_size.y)
	)
	shape_container.position = pos
	
	# Create visual component
	var shape_visual = Control.new()
	shape_visual.custom_minimum_size = Vector2(20, 20)
	shape_visual.draw.connect(_draw_shape.bind(shape_visual, index))
	shape_container.add_child(shape_visual)
	
	# Add floating movement
	start_floating_animation(shape_container, index)
	
	# Store shape properties
	var shape_type = shape_types[index % shape_types.size()]
	var color = base_colors[index % base_colors.size()]
	shape_container.set_meta("shape_type", shape_type)
	shape_container.set_meta("color", color)
	shape_container.set_meta("base_scale", randf_range(0.3, 0.8))
	shape_container.set_meta("beat_responsiveness", randf_range(0.5, 1.5))
	
	return shape_container

func _draw_shape(shape_visual: Control, index: int):
	var parent = shape_visual.get_parent()
	var shape_type = parent.get_meta("shape_type", "circle")
	var color = parent.get_meta("color", Color.WHITE)
	var base_scale = parent.get_meta("base_scale", 0.5)
	
	var size = 20 * base_scale * parent.scale.x
	var center = Vector2(10, 10)
	
	match shape_type:
		"circle":
			shape_visual.draw_circle(center, size / 2, color)
		"diamond":
			var points = PackedVector2Array([
				center + Vector2(0, -size/2),
				center + Vector2(size/2, 0),
				center + Vector2(0, size/2),
				center + Vector2(-size/2, 0)
			])
			shape_visual.draw_colored_polygon(points, color)
		"triangle":
			var points = PackedVector2Array([
				center + Vector2(0, -size/2),
				center + Vector2(size/2, size/2),
				center + Vector2(-size/2, size/2)
			])
			shape_visual.draw_colored_polygon(points, color)
		"hexagon":
			var points = PackedVector2Array()
			for i in range(6):
				var angle = i * TAU / 6
				points.append(center + Vector2(cos(angle), sin(angle)) * size/2)
			shape_visual.draw_colored_polygon(points, color)

func start_floating_animation(shape: Node2D, index: int):
	# Create slow, continuous floating movement
	var tween = create_tween()
	tween.set_loops()
	
	# Random movement parameters
	var speed = randf_range(10.0, 30.0)
	var amplitude_x = randf_range(50, 150)
	var amplitude_y = randf_range(30, 100)
	var phase_offset = index * 0.5
	
	# Create smooth floating pattern using sin waves
	tween.tween_method(
		func(t): update_floating_position(shape, t, amplitude_x, amplitude_y, phase_offset),
		0.0,
		TAU,
		10.0 + randf_range(-2, 2)  # Slight variation in speed
	)

func update_floating_position(shape: Node2D, time: float, amp_x: float, amp_y: float, phase: float):
	var base_pos = shape.get_meta("base_position", shape.position)
	if not shape.has_meta("base_position"):
		shape.set_meta("base_position", shape.position)
	
	var offset = Vector2(
		sin(time + phase) * amp_x,
		cos(time * 0.7 + phase) * amp_y
	)
	
	shape.position = base_pos + offset
	
	# Keep shapes within viewport bounds
	shape.position.x = wrapf(shape.position.x, -50, viewport_size.x + 50)
	shape.position.y = wrapf(shape.position.y, -50, viewport_size.y + 50)

func connect_to_audio_systems():
	# Connect to AudioManager
	if AudioManager:
		if AudioManager.has_signal("beat_occurred"):
			AudioManager.beat_occurred.connect(_on_beat)
	
	# Connect to GameManager's audio analyzer if available
	var game_manager = get_tree().get_first_node_in_group("game_manager")
	if game_manager and game_manager.get("audio_analyzer"):
		var analyzer = game_manager.audio_analyzer
		analyzer.beat_detected.connect(_on_audio_beat_detected)
		analyzer.audio_spectrum_updated.connect(_on_spectrum_updated)

func _on_beat(beat_count: int):
	# Pulse shapes on musical beats
	pulse_shapes(beat_pulse_strength, 0.2)
	
	# Every 4th beat, create a wave effect
	if beat_count % 4 == 0:
		create_wave_effect()

func _on_audio_beat_detected(strength: float, frequency_band: String):
	if not audio_reactive:
		return
	
	# React differently based on frequency band
	match frequency_band:
		"bass":
			pulse_shapes(strength * 0.5, 0.15)
			if strength > 0.8:
				shake_shapes(strength * 10.0)
		"mid":
			flash_shapes(strength)
		"treble":
			sparkle_effect(strength)

func _on_spectrum_updated(spectrum_data: Array):
	if not audio_reactive or spectrum_data.size() == 0:
		return
	
	# Use spectrum data to color shapes dynamically
	for i in range(min(floating_shapes.size(), spectrum_data.size())):
		var shape = floating_shapes[i]
		var energy = spectrum_data[i].get("normalized", 0.0)
		
		# Modulate shape opacity and size based on frequency energy
		shape.modulate.a = lerp(0.3, 1.0, energy)
		var scale_factor = lerp(0.8, 1.2, energy)
		shape.scale = Vector2.ONE * scale_factor

func pulse_shapes(intensity: float, duration: float):
	for shape in floating_shapes:
		var responsiveness = shape.get_meta("beat_responsiveness", 1.0)
		var pulse_amount = intensity * responsiveness
		
		var tween = create_tween()
		tween.set_parallel(true)
		
		# Scale pulse
		var original_scale = shape.scale
		var target_scale = original_scale * (1.0 + pulse_amount)
		
		shape.scale = target_scale
		tween.tween_property(shape, "scale", original_scale, duration)
		
		# Color flash
		var original_modulate = shape.modulate
		var flash_modulate = Color.WHITE * (1.0 + pulse_amount * 0.5)
		
		shape.modulate = flash_modulate
		tween.tween_property(shape, "modulate", original_modulate, duration * 0.7)

func flash_shapes(intensity: float):
	for shape in floating_shapes:
		var tween = create_tween()
		var flash_color = Color.WHITE * (1.0 + intensity)
		shape.modulate = flash_color
		tween.tween_property(shape, "modulate", Color.WHITE, 0.1)

func shake_shapes(intensity: float):
	for shape in floating_shapes:
		var original_pos = shape.position
		var shake_offset = Vector2(
			randf_range(-intensity, intensity),
			randf_range(-intensity, intensity)
		)
		
		var tween = create_tween()
		shape.position = original_pos + shake_offset
		tween.tween_property(shape, "position", original_pos, 0.1)

func sparkle_effect(intensity: float):
	# Create temporary sparkle particles
	var sparkle_count = int(intensity * 5)
	for i in range(sparkle_count):
		create_sparkle_particle()

func create_sparkle_particle():
	var sparkle = Node2D.new()
	add_child(sparkle)
	
	# Random position
	sparkle.position = Vector2(
		randf_range(0, viewport_size.x),
		randf_range(0, viewport_size.y)
	)
	
	# Visual component
	var visual = Control.new()
	visual.custom_minimum_size = Vector2(6, 6)
	visual.draw.connect(func(): visual.draw_circle(Vector2(3, 3), 3, Color.WHITE))
	sparkle.add_child(visual)
	
	# Animate and cleanup
	var tween = create_tween()
	tween.set_parallel(true)
	
	sparkle.scale = Vector2.ZERO
	tween.tween_property(sparkle, "scale", Vector2.ONE * 2.0, 0.1)
	tween.tween_property(sparkle, "scale", Vector2.ZERO, 0.2).set_delay(0.1)
	tween.tween_property(sparkle, "modulate:a", 0.0, 0.3)
	
	await tween.finished
	sparkle.queue_free()

func create_wave_effect():
	# Create a wave that spreads across shapes
	var center = viewport_size / 2
	var shapes_by_distance = []
	
	for shape in floating_shapes:
		var distance = shape.position.distance_to(center)
		shapes_by_distance.append({"shape": shape, "distance": distance})
	
	shapes_by_distance.sort_custom(func(a, b): return a.distance < b.distance)
	
	# Animate shapes in order of distance from center
	for i in range(shapes_by_distance.size()):
		var shape_data = shapes_by_distance[i]
		var shape = shape_data.shape
		var delay = i * 0.05  # 50ms delay between shapes
		
		await get_tree().create_timer(delay).timeout
		
		var tween = create_tween()
		tween.set_parallel(true)
		
		shape.scale = Vector2.ONE * 1.5
		shape.modulate = Color.YELLOW
		
		tween.tween_property(shape, "scale", Vector2.ONE, 0.3)
		tween.tween_property(shape, "modulate", Color.WHITE, 0.2)

func set_audio_reactive(enabled: bool):
	audio_reactive = enabled

func set_visibility(visible_state: bool):
	visible = visible_state

func set_intensity(intensity: float):
	beat_pulse_strength = clamp(intensity, 0.1, 1.0)