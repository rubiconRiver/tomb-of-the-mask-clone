extends Node
class_name SwipeDetector

signal swiped(direction: Vector2)

var swipe_start = Vector2.ZERO
var swipe_threshold = 40.0  # Reduced for more responsive mobile
var is_swiping = false
var swipe_start_time = 0.0
var max_swipe_time = 0.5  # Maximum time for a valid swipe
var min_swipe_speed = 100.0  # Minimum pixels per second for swipe

func _input(event):
	if event is InputEventScreenTouch:
		if event.pressed:
			start_swipe(event.position)
		else:
			end_swipe(event.position)
			
	elif event is InputEventScreenDrag and is_swiping:
		check_swipe(event.position)
				
	elif event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			start_swipe(event.position)
		elif not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			end_swipe(event.position)
			
	elif event is InputEventMouseMotion and is_swiping:
		check_swipe(event.position)

func start_swipe(position: Vector2):
	swipe_start = position
	swipe_start_time = Time.get_ticks_msec() / 1000.0
	is_swiping = true

func check_swipe(current_position: Vector2):
	if not is_swiping:
		return
		
	var swipe_vector = current_position - swipe_start
	var swipe_distance = swipe_vector.length()
	
	if swipe_distance > swipe_threshold:
		var current_time = Time.get_ticks_msec() / 1000.0
		var swipe_time = current_time - swipe_start_time
		var swipe_speed = swipe_distance / swipe_time
		
		# Check if swipe is fast enough and not too slow
		if swipe_time <= max_swipe_time and swipe_speed >= min_swipe_speed:
			var direction = get_swipe_direction(swipe_vector)
			if direction != Vector2.ZERO:
				emit_signal("swiped", direction)
				is_swiping = false

func end_swipe(end_position: Vector2):
	if is_swiping:
		# Check final swipe on release
		check_swipe(end_position)
		is_swiping = false

func get_swipe_direction(swipe_vector: Vector2) -> Vector2:
	var abs_x = abs(swipe_vector.x)
	var abs_y = abs(swipe_vector.y)
	
	if abs_x > abs_y:
		if swipe_vector.x > 0:
			return Vector2.RIGHT
		else:
			return Vector2.LEFT
	else:
		if swipe_vector.y > 0:
			return Vector2.DOWN
		else:
			return Vector2.UP
			
	return Vector2.ZERO