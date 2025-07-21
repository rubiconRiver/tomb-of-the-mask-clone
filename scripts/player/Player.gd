extends CharacterBody2D
class_name Player

@export var move_speed = 1024.0  # Exactly 8 cells per beat at 120 BPM
const GRID_SIZE = 64

var is_moving = false
var move_direction = Vector2.ZERO
var target_position = Vector2.ZERO
var grid_position = Vector2i.ZERO
var trail_effect: TrailEffect
var player_visual: Node2D
var last_timing_quality = -1
var movement_ray: RayCast2D
var buffered_direction = Vector2.ZERO  # For input buffering in fast sections

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
		
		# Log position relative to beat every 0.25 seconds for debugging
		if not has_meta("last_beat_log") or Time.get_ticks_msec() - get_meta("last_beat_log") > 250:
			set_meta("last_beat_log", Time.get_ticks_msec())
			var grid_pos = Vector2i(position / GRID_SIZE)
			var beat_progress = AudioManager.get_beat_progress() if AudioManager else 0.0
			var current_beat = AudioManager.get_current_beat() if AudioManager else 0
			print("[MOVEMENT] Grid pos: ", grid_pos, " | Beat: ", current_beat % 4 + 1, " | Beat progress: ", snapped(beat_progress, 0.01))
		
		# NEVER REMOVE - Critical for debugging movement glitches
		var distance_to_target = position.distance_to(target_position)
		if distance_to_target > 100:  # Only log when far from target to reduce spam
			print("Moving: pos=", position, " target=", target_position, " dist=", int(distance_to_target))
		
		if distance_to_target <= 5.0:
			# NEVER REMOVE - Critical for debugging movement glitches
			var current_beat = AudioManager.get_current_beat() if AudioManager else 0
			var beat_progress = AudioManager.get_beat_progress() if AudioManager else 0.0
			var start_grid = Vector2i(get_meta("move_start_pos", position) / GRID_SIZE)
			var end_grid = Vector2i(target_position / GRID_SIZE)
			var blocks_traveled = abs(end_grid.x - start_grid.x) + abs(end_grid.y - start_grid.y)
			print("=== MOVEMENT COMPLETE ===")
			print("Final position: ", target_position, " Grid: ", end_grid)
			print("Blocks traveled: ", blocks_traveled)
			print("Ended on Beat ", current_beat % 4 + 1, " (progress: ", snapped(beat_progress, 0.01), ")")
			print("Distance error: ", distance_to_target, " pixels")
			
			position = target_position
			is_moving = false
			velocity = Vector2.ZERO
			
			# NEVER REMOVE - Critical for debugging movement glitches
			validate_position()
			
			emit_signal("moved")
			
			# Check for buffered input
			if buffered_direction != Vector2.ZERO:
				var next_direction = buffered_direction
				buffered_direction = Vector2.ZERO
				print("Executing buffered move: ", next_direction)
				move(next_direction)
			
		for i in get_slide_collision_count():
			var collision = get_slide_collision(i)
			var collider = collision.get_collider()
			
			if collider.is_in_group("walls"):
				# NEVER REMOVE - Critical for debugging movement glitches
				var current_beat = AudioManager.get_current_beat() if AudioManager else 0
				var beat_progress = AudioManager.get_beat_progress() if AudioManager else 0.0
				var start_grid = Vector2i(get_meta("move_start_pos", position) / GRID_SIZE)
				print("=== WALL HIT DURING MOVEMENT ===")
				print("Hit wall at position: ", position)
				print("Ended on Beat ", current_beat % 4 + 1, " (progress: ", snapped(beat_progress, 0.01), ")")
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
				var end_grid = Vector2i(corrected_position / GRID_SIZE)
				var blocks_traveled = abs(end_grid.x - start_grid.x) + abs(end_grid.y - start_grid.y)
				print("Corrected to grid position: ", corrected_position, " Grid: ", end_grid)
				print("Blocks traveled: ", blocks_traveled)
				validate_position()
				
				emit_signal("hit_wall")
				emit_signal("moved")
				
				# Check for buffered input after hitting wall
				if buffered_direction != Vector2.ZERO:
					var next_direction = buffered_direction
					buffered_direction = Vector2.ZERO
					print("Executing buffered move after wall hit: ", next_direction)
					move(next_direction)
				
				break
			elif collider.is_in_group("hazards"):
				die()
				break

func move(direction: Vector2):
	if is_moving:
		return
	
	# NEVER REMOVE - Critical for debugging movement glitches
	var move_id = Time.get_ticks_msec()
	var current_beat = AudioManager.get_current_beat() if AudioManager else 0
	var beat_progress = AudioManager.get_beat_progress() if AudioManager else 0.0
	print("=== MOVE START [", move_id, "] ===")
	print("Start position: ", position, " Grid: ", Vector2i(position / GRID_SIZE))
	print("Direction: ", direction)
	print("Starting on Beat ", current_beat % 4 + 1, " (progress: ", snapped(beat_progress, 0.01), ")")
		
	move_direction = direction.normalized()
	is_moving = true
	
	# Store start position for tracking blocks traveled
	set_meta("move_start_pos", position)
	
	# Just set a far target and let collision detection handle walls
	target_position = position + move_direction * 10000
	target_position = target_position.snapped(Vector2(GRID_SIZE, GRID_SIZE))
	
	# NEVER REMOVE - Critical for debugging movement glitches
	print("Target position: ", target_position, " Grid: ", Vector2i(target_position / GRID_SIZE))
	print("=== MOVE SETUP COMPLETE [", move_id, "] ===")

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