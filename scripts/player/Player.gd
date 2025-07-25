extends CharacterBody2D
class_name Player

@export var move_speed = 1024.0  # Will be calculated based on BPM
const GRID_SIZE = 64
const BLOCKS_PER_QUARTER_NOTE = 4  # Movement speed: 4 blocks per quarter note

var is_moving = false
var move_direction = Vector2.ZERO
var target_position = Vector2.ZERO
var grid_position = Vector2i.ZERO
var trail_effect: TrailEffect
var player_visual: Node2D
var last_timing_quality = -1
var movement_ray: RayCast2D
var buffered_direction = Vector2.ZERO  # For input buffering in fast sections

# Input buffering system
var buffered_input: Vector2 = Vector2.ZERO
var input_buffer_time: float = 0.15  # Buffer input for 150ms
var input_buffer_timer: float = 0.0

# Movement enhancement
var base_speed: float = 1024.0
var current_momentum: float = 1.0
var momentum_buildup: float = 0.1
var momentum_decay: float = 0.05
var max_momentum: float = 1.3

# Effect systems
var screen_shake: ScreenShake
var particle_manager: ParticleManager

@onready var area = $Area2D

signal moved
signal died
signal collected_coin
signal hit_wall

func update_speed_from_bpm(bpm: float):
	# Calculate speed for 4 blocks per quarter note
	# Speed = (blocks per beat × pixels per block) ÷ seconds per beat
	var beat_duration = 60.0 / bpm  # seconds per quarter note
	var pixels_per_beat = BLOCKS_PER_QUARTER_NOTE * GRID_SIZE  # 4 blocks × 64 pixels = 256 pixels
	var calculated_speed = pixels_per_beat / beat_duration
	
	base_speed = calculated_speed
	move_speed = base_speed * current_momentum
	
	print("[Player] Speed updated for ", bpm, " BPM:")
	print("  Beat duration: ", beat_duration, "s")
	print("  Pixels per beat: ", pixels_per_beat, " pixels")
	print("  Base speed: ", base_speed, " pixels/s")
	print("  Current speed (with momentum): ", move_speed, " pixels/s")

func reset():
	is_moving = false
	move_direction = Vector2.ZERO
	velocity = Vector2.ZERO
	snap_to_grid()

func _ready():
	snap_to_grid()
	if area:
		area.area_entered.connect(_on_area_entered)
	
	# Initialize speed from default BPM (120)
	update_speed_from_bpm(120.0)
	
	# Add trail effect
	var trail_script = preload("res://scripts/visual/TrailEffect.gd")
	trail_effect = trail_script.new()
	add_child(trail_effect)
	trail_effect.set_trail_color(Color("#94fbe6"))  # Match player color
	
	# Add player visual controller
	var visual_script = preload("res://scripts/player/PlayerVisual.gd")
	player_visual = visual_script.new()
	add_child(player_visual)
	
	# Get effect systems from game manager and connect to beat system
	var game_manager = get_tree().get_first_node_in_group("game_manager")
	if game_manager:
		screen_shake = game_manager.get("screen_shake")
		particle_manager = game_manager.get("particle_manager")
		
		# Connect to beat system
		if game_manager.has_signal("beat_occurred"):
			game_manager.beat_occurred.connect(_on_beat)

func _physics_process(delta):
	# Handle input buffering
	if input_buffer_timer > 0:
		input_buffer_timer -= delta
		if input_buffer_timer <= 0 and buffered_input != Vector2.ZERO:
			# Try to execute buffered input
			if not is_moving:
				move(buffered_input)
			buffered_input = Vector2.ZERO
	
	# Update momentum
	update_momentum(delta)
	
	if is_moving:
		# Apply momentum to movement speed
		var effective_speed = base_speed * current_momentum
		velocity = move_direction * effective_speed
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
			
			# Add landing effects
			if particle_manager:
				particle_manager.spawn_landing(global_position, get_parent())
			
			# Subtle landing screen shake
			if screen_shake:
				screen_shake.shake_preset("landing")
			
			# Build momentum for successful moves
			current_momentum = min(current_momentum + momentum_buildup, max_momentum)
			
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
				
				# Wall hit effects
				if particle_manager:
					particle_manager.spawn_wall_hit(collision.get_position(), get_parent())
				
				# Wall hit screen shake
				if screen_shake:
					screen_shake.shake_preset("wall_hit")
				
				# Reduce momentum on wall hit
				current_momentum = max(current_momentum - momentum_decay * 2.0, 0.8)
				
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
		# Buffer the input for later execution
		buffered_input = direction
		input_buffer_timer = input_buffer_time
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
	
	# Play whoosh sound for movement start
	if AudioManager:
		AudioManager.play_whoosh()
	
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
		# Trigger coin explosion effect if it has the method
		if other_area.has_method("_on_coin_collected"):
			other_area._on_coin_collected()
		else:
			# Fallback for coins without explosion effect
			other_area.queue_free()
		
		# Coin collection screen shake
		if screen_shake:
			screen_shake.shake_preset("coin_collect")
		
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
	
	# Update trail color based on timing
	if trail_effect:
		trail_effect.set_timing_quality(quality)
		
		# Special effect for perfect timing
		if quality == 3:  # Perfect timing
			trail_effect.pulse_for_perfect_timing()

func update_momentum(delta: float):
	# Gradually decay momentum when not building it up
	if not is_moving:
		current_momentum = max(current_momentum - momentum_decay * delta, 1.0)
	
	# Update move speed based on current momentum
	move_speed = base_speed * current_momentum

func get_momentum_factor() -> float:
	# Return current momentum as a factor (1.0 = normal, >1.0 = faster)
	return current_momentum

func reset_momentum():
	# Reset momentum to baseline (useful for level restart)
	current_momentum = 1.0
	move_speed = base_speed
