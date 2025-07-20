extends CharacterBody2D
class_name Player

@export var move_speed = 1280.0  # Exactly 10 cells per beat at 120 BPM
const GRID_SIZE = 64

var is_moving = false
var move_direction = Vector2.ZERO
var target_position = Vector2.ZERO
var grid_position = Vector2i.ZERO
var trail_effect: TrailEffect
var player_visual: Node2D
var last_timing_quality = -1

@onready var area = $Area2D

signal moved
signal died
signal collected_coin
signal hit_wall

func reset():
	is_moving = false
	move_direction = Vector2.ZERO
	velocity = Vector2.ZERO
	snap_to_grid()

func _ready():
	snap_to_grid()
	if area:
		area.area_entered.connect(_on_area_entered)
	
	# Add trail effect
	var trail_script = preload("res://scripts/visual/TrailEffect.gd")
	trail_effect = trail_script.new()
	add_child(trail_effect)
	trail_effect.set_trail_color(Color(0.0, 1.0, 0.8, 0.8))  # Cyan trail
	
	# Add player visual controller
	var visual_script = preload("res://scripts/player/PlayerVisual.gd")
	player_visual = visual_script.new()
	add_child(player_visual)
	
	# Connect to beat system
	var game_manager = get_tree().get_first_node_in_group("game_manager")
	if game_manager and game_manager.has_signal("beat_occurred"):
		game_manager.beat_occurred.connect(_on_beat)

func _physics_process(delta):
	if is_moving:
		velocity = move_direction * move_speed
		move_and_slide()
		
		# Add trail points while moving
		if trail_effect:
			trail_effect.add_point(global_position)
		
		# NEVER REMOVE - Critical for debugging movement glitches
		var distance_to_target = position.distance_to(target_position)
		if distance_to_target > 100:  # Only log when far from target to reduce spam
			print("Moving: pos=", position, " target=", target_position, " dist=", int(distance_to_target))
		
		if distance_to_target <= 5.0:
			# NEVER REMOVE - Critical for debugging movement glitches
			print("=== MOVEMENT COMPLETE ===")
			print("Final position: ", target_position, " Grid: ", Vector2i(target_position / GRID_SIZE))
			print("Distance error: ", distance_to_target, " pixels")
			
			position = target_position
			is_moving = false
			velocity = Vector2.ZERO
			
			# NEVER REMOVE - Critical for debugging movement glitches
			validate_position()
			
			emit_signal("moved")
			
		for i in get_slide_collision_count():
			var collision = get_slide_collision(i)
			var collider = collision.get_collider()
			
			if collider.is_in_group("walls"):
				# NEVER REMOVE - Critical for debugging movement glitches
				print("=== WALL HIT DURING MOVEMENT ===")
				print("Hit wall at position: ", position)
				print("Original target was: ", target_position)
				print("Collision point: ", collision.get_position())
				
				# Stop at current position instead of jumping to target
				# Find the last valid grid position before the wall
				var grid_pos = Vector2i(position / GRID_SIZE)
				var corrected_position = Vector2(grid_pos * GRID_SIZE)
				
				# Make sure we're not inside the wall
				if collider.global_position.distance_to(corrected_position) < GRID_SIZE:
					# We're too close, back up one cell
					corrected_position -= move_direction * GRID_SIZE
				
				position = corrected_position
				is_moving = false
				velocity = Vector2.ZERO
				
				# NEVER REMOVE - Critical for debugging movement glitches
				print("Corrected to grid position: ", corrected_position, " Grid: ", Vector2i(corrected_position / GRID_SIZE))
				validate_position()
				
				emit_signal("hit_wall")
				emit_signal("moved")
				break
			elif collider.is_in_group("hazards"):
				die()
				break

func move(direction: Vector2):
	if is_moving:
		return
	
	# NEVER REMOVE - Critical for debugging movement glitches
	var move_id = Time.get_ticks_msec()
	print("=== MOVE START [", move_id, "] ===")
	print("Start position: ", position, " Grid: ", Vector2i(position / GRID_SIZE))
	print("Direction: ", direction)
		
	move_direction = direction.normalized()
	is_moving = true
	
	var ray = RayCast2D.new()
	add_child(ray)
	ray.position = Vector2.ZERO
	ray.target_position = move_direction * 10000
	ray.force_raycast_update()
	
	if ray.is_colliding():
		var collision_point = ray.get_collision_point()
		var distance_to_wall = position.distance_to(collision_point)
		
		# NEVER REMOVE - Critical for debugging movement glitches
		print("Wall collision detected at: ", collision_point)
		print("Distance to wall: ", distance_to_wall, " pixels")
		
		# Calculate cells to wall - account for player radius (32 pixels = half cell)
		var adjusted_distance = distance_to_wall - 32  # Player radius
		var cells_to_wall = max(0, int(adjusted_distance / GRID_SIZE))
		
		# NEVER REMOVE - Critical for debugging movement glitches
		print("Cells to wall (adjusted): ", cells_to_wall)
		
		target_position = position + move_direction * cells_to_wall * GRID_SIZE
		target_position = target_position.snapped(Vector2(GRID_SIZE, GRID_SIZE))
		
		# NEVER REMOVE - Critical for debugging movement glitches
		print("Calculated target: ", target_position, " Grid: ", Vector2i(target_position / GRID_SIZE))
	else:
		target_position = position + move_direction * 10000
		target_position = target_position.snapped(Vector2(GRID_SIZE, GRID_SIZE))
		
		# NEVER REMOVE - Critical for debugging movement glitches
		print("No wall found, moving max distance to: ", target_position)
	
	# NEVER REMOVE - Critical for debugging movement glitches
	print("=== MOVE SETUP COMPLETE [", move_id, "] ===")
		
	ray.queue_free()

func snap_to_grid():
	position = position.snapped(Vector2(GRID_SIZE, GRID_SIZE))
	grid_position = Vector2i(position / GRID_SIZE)

# NEVER REMOVE - Critical for debugging movement glitches
func validate_position():
	var expected_grid_pos = Vector2i(position / GRID_SIZE)
	var actual_grid_pos = Vector2(expected_grid_pos * GRID_SIZE)
	var distance_from_grid = position.distance_to(actual_grid_pos)
	
	if distance_from_grid > 1.0:
		print("WARNING: Player not aligned to grid!")
		print("Position: ", position, " Expected: ", actual_grid_pos)
		print("Distance from grid: ", distance_from_grid)
		
		# Auto-correct if severely misaligned
		if distance_from_grid > GRID_SIZE / 4:
			print("AUTO-CORRECTING position to grid")
			position = actual_grid_pos
			
	return distance_from_grid <= 1.0

func die():
	is_moving = false
	emit_signal("died")
	set_physics_process(false)

func _on_area_entered(other_area):
	if other_area.is_in_group("coins"):
		other_area.queue_free()
		emit_signal("collected_coin")
	elif other_area.is_in_group("hazards"):
		die()

func _on_beat():
	if player_visual:
		player_visual.pulse_on_beat()

func set_timing_quality(quality: int):
	last_timing_quality = quality
	if player_visual:
		player_visual.set_timing_quality_color(quality)