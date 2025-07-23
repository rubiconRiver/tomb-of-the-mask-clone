class_name TrailEffect
extends Node2D

var trail_points = []
var max_points = 10
var point_lifetime = 0.5
var trail_color = Color(0.0, 1.0, 0.8, 0.8)
var trail_width = 20.0

# Timing responsiveness
var base_trail_color = Color(0.0, 1.0, 0.8, 0.8)
var perfect_timing_color = Color(1.0, 0.9, 0.0, 1.0)  # Gold
var good_timing_color = Color(0.2, 1.0, 0.4, 0.9)    # Green
var poor_timing_color = Color(1.0, 0.3, 0.3, 0.7)    # Red
var current_timing_quality = 0  # 0=off, 1=poor, 2=good, 3=perfect

func _ready():
	set_process(true)
	z_index = -1  # Draw behind parent

func _process(delta):
	# Update trail points
	var needs_redraw = false
	for i in range(trail_points.size() - 1, -1, -1):
		trail_points[i].lifetime -= delta
		if trail_points[i].lifetime <= 0:
			trail_points.remove_at(i)
			needs_redraw = true
	
	if needs_redraw:
		queue_redraw()

func add_point(pos: Vector2):
	trail_points.append({
		"position": pos,
		"lifetime": point_lifetime
	})
	
	# Limit trail length
	if trail_points.size() > max_points:
		trail_points.pop_front()
	
	# Redraw when new point added
	queue_redraw()

func _draw():
	if trail_points.size() < 2:
		return
	
	for i in range(trail_points.size() - 1):
		var start_point = trail_points[i]
		var end_point = trail_points[i + 1]
		
		# Calculate alpha based on lifetime
		var alpha1 = start_point.lifetime / point_lifetime
		var alpha2 = end_point.lifetime / point_lifetime
		
		# Calculate width based on position in trail
		var width1 = trail_width * (float(i) / float(trail_points.size()))
		var width2 = trail_width * (float(i + 1) / float(trail_points.size()))
		
		# Draw line segment with gradient
		var color1 = Color(trail_color.r, trail_color.g, trail_color.b, trail_color.a * alpha1)
		var color2 = Color(trail_color.r, trail_color.g, trail_color.b, trail_color.a * alpha2)
		
		# Convert to local coordinates
		var local_start = to_local(start_point.position)
		var local_end = to_local(end_point.position)
		
		draw_line(local_start, local_end, color1, width1)
		
		# Add single glow effect (reduced from 3 passes)
		var glow_width = width1 * 2.0
		var glow_alpha = alpha1 * 0.2
		var glow_color = Color(trail_color.r, trail_color.g, trail_color.b, glow_alpha)
		draw_line(local_start, local_end, glow_color, glow_width)

func set_trail_color(color: Color):
	base_trail_color = color
	trail_color = color

func set_timing_quality(quality: int):
	current_timing_quality = quality
	update_trail_color_for_timing()

func update_trail_color_for_timing():
	match current_timing_quality:
		3: # Perfect
			trail_color = perfect_timing_color
			trail_width = 25.0  # Wider trail for perfect timing
		2: # Good
			trail_color = good_timing_color
			trail_width = 22.0
		1: # Poor
			trail_color = poor_timing_color
			trail_width = 18.0
		_: # Off beat or default
			trail_color = base_trail_color
			trail_width = 20.0

func pulse_for_perfect_timing():
	# Special effect for perfect timing
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Temporary width increase
	var original_width = trail_width
	trail_width = original_width * 1.5
	tween.tween_method(func(w): trail_width = w, trail_width, original_width, 0.3)
	
	# Color flash
	var flash_color = Color.WHITE
	var original_color = trail_color
	trail_color = flash_color
	tween.tween_method(func(c): trail_color = c, flash_color, original_color, 0.2)

func clear_trail():
	trail_points.clear()
	queue_redraw()