extends Node
class_name SwipeDetector

signal swiped(direction: Vector2)

var swipe_start = Vector2.ZERO
var swipe_threshold = 50.0
var is_swiping = false

func _input(event):
	if event is InputEventScreenTouch:
		if event.pressed:
			swipe_start = event.position
			is_swiping = true
		else:
			is_swiping = false
			
	elif event is InputEventScreenDrag and is_swiping:
		var swipe_current = event.position
		var swipe_vector = swipe_current - swipe_start
		
		if swipe_vector.length() > swipe_threshold:
			var direction = get_swipe_direction(swipe_vector)
			if direction != Vector2.ZERO:
				emit_signal("swiped", direction)
				is_swiping = false
				
	elif event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			swipe_start = event.position
			is_swiping = true
		elif not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			is_swiping = false
			
	elif event is InputEventMouseMotion and is_swiping:
		var swipe_current = event.position
		var swipe_vector = swipe_current - swipe_start
		
		if swipe_vector.length() > swipe_threshold:
			var direction = get_swipe_direction(swipe_vector)
			if direction != Vector2.ZERO:
				emit_signal("swiped", direction)
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