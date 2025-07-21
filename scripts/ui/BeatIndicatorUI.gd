extends Control
class_name BeatIndicatorUI

# Visual rhythm guide to help players sync with the beat

var beat_circles: Array[Control] = []
var center_circle: Control
var beat_indicator_size: float = 80.0
var pulse_intensity: float = 1.0

# Beat tracking
var current_beat: int = 0
var beats_per_measure: int = 4
var beat_timer: float = 0.0
var beat_interval: float = 0.5  # 120 BPM default

# Visual configuration
var active_color = Color("#94fbe6")    # Cyan for active beat
var inactive_color = Color("#333333")  # Dark gray for inactive
var accent_color = Color("#dcfb94")    # Light green for emphasis
var pulse_color = Color("#ffffff")     # White for pulse effect

# Animation
var tween: Tween
var pulse_scale: float = 1.2
var animation_duration: float = 0.1

func _ready():
	setup_ui()
	connect_to_audio_system()

func setup_ui():
	# Set up layout - manually position at bottom center
	anchor_left = 0.5
	anchor_right = 0.5  
	anchor_top = 1.0
	anchor_bottom = 1.0
	offset_left = -175  # Half of width (350/2)
	offset_right = 175
	offset_top = -100   # Height
	offset_bottom = 0
	size = Vector2(350, 100)
	position.y -= 120  # Position above bottom edge
	
	# Create background panel
	var background = Panel.new()
	background.anchor_left = 0.0
	background.anchor_right = 1.0
	background.anchor_top = 0.0
	background.anchor_bottom = 1.0
	background.offset_left = 0
	background.offset_right = 0
	background.offset_top = 0
	background.offset_bottom = 0
	
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.1, 0.1, 0.1, 0.8)
	style_box.corner_radius_top_left = 15
	style_box.corner_radius_top_right = 15
	style_box.corner_radius_bottom_left = 15
	style_box.corner_radius_bottom_right = 15
	style_box.border_width_left = 2
	style_box.border_width_right = 2
	style_box.border_width_top = 2
	style_box.border_width_bottom = 2
	style_box.border_color = Color(0.3, 0.3, 0.3, 0.6)
	
	background.add_theme_stylebox_override("panel", style_box)
	add_child(background)
	
	# Create beat circles layout
	var hbox = HBoxContainer.new()
	hbox.anchor_left = 0.5
	hbox.anchor_right = 0.5
	hbox.anchor_top = 0.5
	hbox.anchor_bottom = 0.5
	hbox.offset_left = -150  # Approximate half width
	hbox.offset_right = 150
	hbox.offset_top = -40   # Approximate half height
	hbox.offset_bottom = 40
	hbox.add_theme_constant_override("separation", 15)
	add_child(hbox)
	
	# Create individual beat circles
	for i in range(beats_per_measure):
		var circle = create_beat_circle(i)
		hbox.add_child(circle)
		beat_circles.append(circle)
	
	# Initialize first beat as active
	update_beat_display(0)

func create_beat_circle(beat_index: int) -> Control:
	var circle_container = Control.new()
	circle_container.custom_minimum_size = Vector2(beat_indicator_size, beat_indicator_size)
	
	# Create circle visual
	var circle = Control.new()
	circle.set_anchors_preset(Control.PRESET_FULL_RECT)
	circle.custom_minimum_size = Vector2(beat_indicator_size, beat_indicator_size)
	circle_container.add_child(circle)
	
	# Draw circle in _draw
	circle.draw.connect(_draw_beat_circle.bind(circle, beat_index))
	
	# Add beat number label
	var label = Label.new()
	label.text = str(beat_index + 1)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.anchor_left = 0.0
	label.anchor_right = 1.0
	label.anchor_top = 0.0
	label.anchor_bottom = 1.0
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", Color.WHITE)
	circle_container.add_child(label)
	
	return circle_container

func _draw_beat_circle(circle: Control, beat_index: int):
	var radius = beat_indicator_size / 2.0 - 5
	var center = Vector2(beat_indicator_size / 2.0, beat_indicator_size / 2.0)
	
	# Determine circle color and size based on beat state
	var color = inactive_color
	var scale = 1.0
	
	if beat_index == current_beat:
		color = active_color
		scale = pulse_scale if is_pulsing() else 1.0
	elif beat_index == 0:  # Emphasize downbeat
		color = accent_color.lerp(inactive_color, 0.7)
	
	# Draw circle
	circle.draw_circle(center, radius * scale, color)
	
	# Draw border
	circle.draw_arc(center, radius * scale, 0, TAU, 32, Color.WHITE, 2.0)

func connect_to_audio_system():
	# Connect to AudioManager beat signal
	if AudioManager:
		if AudioManager.has_signal("beat_occurred"):
			AudioManager.beat_occurred.connect(_on_beat)
		if AudioManager.has_signal("eighth_note_occurred"):
			AudioManager.eighth_note_occurred.connect(_on_eighth_note)

func _on_beat(beat_count: int):
	current_beat = beat_count % beats_per_measure
	animate_beat_pulse()
	update_beat_display(current_beat)

func _on_eighth_note():
	# Optional: Could add subtle eighth note indicators
	pass

func animate_beat_pulse():
	if tween:
		tween.kill()
	
	tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	
	# Pulse the current beat circle
	var current_circle = beat_circles[current_beat]
	var circle_visual = current_circle.get_child(0)  # The visual circle
	
	# Scale animation
	circle_visual.scale = Vector2.ONE * pulse_scale
	tween.tween_property(circle_visual, "scale", Vector2.ONE, animation_duration)
	
	# Force redraw
	circle_visual.queue_redraw()

func update_beat_display(beat_index: int):
	# Update colors and states of all circles
	for i in range(beat_circles.size()):
		var circle = beat_circles[i].get_child(0)  # Get visual circle
		circle.queue_redraw()

func is_pulsing() -> bool:
	return tween && tween.is_valid()

func set_beat_interval(interval: float):
	beat_interval = interval
	
	# Update BPM display if needed
	var bpm = 60.0 / interval
	print("[BeatIndicator] BPM: ", int(bpm))

func set_time_signature(beats: int):
	if beats == beats_per_measure:
		return
	
	beats_per_measure = beats
	current_beat = 0
	
	# Rebuild UI with new beat count
	for circle in beat_circles:
		circle.queue_free()
	beat_circles.clear()
	
	# Wait a frame for cleanup
	await get_tree().process_frame
	setup_ui()

func set_visibility(visible_state: bool):
	visible = visible_state

func set_pulse_intensity(intensity: float):
	pulse_intensity = clamp(intensity, 0.5, 2.0)
	pulse_scale = 1.0 + (0.2 * pulse_intensity)

func set_position_preset(preset: String):
	match preset:
		"bottom_center":
			anchor_left = 0.5
			anchor_right = 0.5
			anchor_top = 1.0
			anchor_bottom = 1.0
			offset_left = -175
			offset_right = 175
			offset_top = -220  # 100 height + 120 margin
			offset_bottom = -120
		"top_center":
			anchor_left = 0.5
			anchor_right = 0.5
			anchor_top = 0.0
			anchor_bottom = 0.0
			offset_left = -175
			offset_right = 175
			offset_top = 50
			offset_bottom = 150
		"center":
			anchor_left = 0.5
			anchor_right = 0.5
			anchor_top = 0.5
			anchor_bottom = 0.5
			offset_left = -175
			offset_right = 175
			offset_top = -50
			offset_bottom = 50
		_:
			# Default to bottom center
			anchor_left = 0.5
			anchor_right = 0.5
			anchor_top = 1.0
			anchor_bottom = 1.0
			offset_left = -175
			offset_right = 175
			offset_top = -220
			offset_bottom = -120

# Responsive to audio analysis
func set_audio_reactive(enabled: bool):
	if enabled and AudioManager:
		# Could connect to audio analyzer for more reactive behavior
		pass

func highlight_timing_window(window_start: float, window_end: float):
	# Highlight the optimal timing window for player input
	# Could be used to show when moves should be executed
	pass
