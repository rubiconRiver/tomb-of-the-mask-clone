class_name TrailEffect
extends Node2D

var trail_points = []
var max_points = 10
var point_lifetime = 0.5
var trail_color = Color(0.0, 1.0, 0.8, 0.8)
var trail_width = 20.0

func _ready():
	set_process(true)
	z_index = -1  # Draw behind parent

func _process(delta):
	# Update trail points
	for i in range(trail_points.size() - 1, -1, -1):
		trail_points[i].lifetime -= delta
		if trail_points[i].lifetime <= 0:
			trail_points.remove_at(i)
	
	queue_redraw()

func add_point(pos: Vector2):
	trail_points.append({
		"position": pos,
		"lifetime": point_lifetime
	})
	
	# Limit trail length
	if trail_points.size() > max_points:
		trail_points.pop_front()

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
		
		# Add glow effect
		for j in range(3):
			var glow_width = width1 * (1.5 + j * 0.5)
			var glow_alpha = alpha1 * 0.2 / (j + 1)
			var glow_color = Color(trail_color.r, trail_color.g, trail_color.b, glow_alpha)
			draw_line(local_start, local_end, glow_color, glow_width)

func set_trail_color(color: Color):
	trail_color = color

func clear_trail():
	trail_points.clear()
	queue_redraw()