extends Area2D
class_name Goal

var time = 0.0
var portal_points = []

signal player_reached_goal

func _ready():
	# Ensure goal is visible above other elements
	z_index = 10
	
	# Create a spinning portal effect
	update_portal()
	
	print("[Goal] Goal created at position: ", position, " with z_index: ", z_index)

func _process(delta):
	time += delta
	update_portal()
	
	# Pulse the visual
	var pulse = 0.8 + sin(time * 3.0) * 0.2
	$Visual.modulate.a = pulse
	
	# Rotate slowly
	rotation += delta * 0.5

func update_portal():
	portal_points.clear()
	var num_points = 16
	var radius = 20.0  # Smaller radius to fit within 64x64 grid
	
	for i in range(num_points + 1):
		var angle = (float(i) / num_points) * TAU + time * 2.0
		var offset = sin(time * 3.0 + i * 0.5) * 5.0
		var point = Vector2(
			cos(angle) * (radius + offset),
			sin(angle) * (radius + offset)
		)
		portal_points.append(point)
	
	$Portal.points = portal_points

func _on_body_entered(body):
	if body.is_in_group("player"):
		# More precise collision detection - check if player is actually in the goal square
		const GRID_SIZE = 64
		var distance = body.position.distance_to(position)
		
		# Convert world positions to grid coordinates (centered on grid cells)
		var goal_grid_x = int((position.x + GRID_SIZE/2) / GRID_SIZE)
		var goal_grid_y = int((position.y + GRID_SIZE/2) / GRID_SIZE)
		var player_grid_x = int((body.position.x + GRID_SIZE/2) / GRID_SIZE)
		var player_grid_y = int((body.position.y + GRID_SIZE/2) / GRID_SIZE)
		
		print("[Goal] Goal detection triggered:")
		print("  Goal pos: ", position, " (grid: ", goal_grid_x, ",", goal_grid_y, ")")
		print("  Player pos: ", body.position, " (grid: ", player_grid_x, ",", player_grid_y, ")")
		print("  Distance: ", distance)
		
		# Only trigger if player is in the exact same grid square as the goal
		if player_grid_x == goal_grid_x and player_grid_y == goal_grid_y:
			print("[Goal] ✓ Player is in goal square - completing level")
			emit_signal("player_reached_goal")
			
			# Visual feedback
			var tween = get_tree().create_tween()
			tween.set_parallel(true)
			tween.tween_property(self, "scale", Vector2(2, 2), 0.3)
			tween.tween_property(self, "modulate:a", 0.0, 0.3)
		else:
			print("[Goal] ✗ Player not in goal square - ignoring collision")

func _on_animation_timer_timeout():
	# Additional animation updates if needed
	pass