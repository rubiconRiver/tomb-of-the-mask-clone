extends CharacterBody2D
class_name Player

const MOVE_SPEED = 800.0
const GRID_SIZE = 64

var is_moving = false
var move_direction = Vector2.ZERO
var target_position = Vector2.ZERO
var grid_position = Vector2i.ZERO
var trail_effect: TrailEffect

@onready var area = $Area2D

signal moved
signal died
signal collected_coin

func _ready():
	snap_to_grid()
	if area:
		area.area_entered.connect(_on_area_entered)
	
	# Add trail effect
	var trail_script = preload("res://scripts/visual/TrailEffect.gd")
	trail_effect = trail_script.new()
	add_child(trail_effect)
	trail_effect.set_trail_color(Color(0.0, 1.0, 0.8, 0.8))  # Cyan trail

func _physics_process(delta):
	if is_moving:
		velocity = move_direction * MOVE_SPEED
		move_and_slide()
		
		# Add trail points while moving
		if trail_effect:
			trail_effect.add_point(global_position)
		
		if position.distance_to(target_position) <= 5.0:
			position = target_position
			is_moving = false
			velocity = Vector2.ZERO
			emit_signal("moved")
			
		for i in get_slide_collision_count():
			var collision = get_slide_collision(i)
			var collider = collision.get_collider()
			
			if collider.is_in_group("walls"):
				position = target_position
				is_moving = false
				velocity = Vector2.ZERO
				emit_signal("moved")
				break
			elif collider.is_in_group("hazards"):
				die()
				break

func move(direction: Vector2):
	if is_moving:
		return
		
	move_direction = direction.normalized()
	is_moving = true
	
	var ray = RayCast2D.new()
	add_child(ray)
	ray.position = Vector2.ZERO
	ray.target_position = move_direction * 2000
	ray.force_raycast_update()
	
	if ray.is_colliding():
		var collision_point = ray.get_collision_point()
		var distance_to_wall = position.distance_to(collision_point)
		
		# Calculate cells to wall without subtracting 1
		var cells_to_wall = int(distance_to_wall / GRID_SIZE)
		
		target_position = position + move_direction * cells_to_wall * GRID_SIZE
		target_position = target_position.snapped(Vector2(GRID_SIZE, GRID_SIZE))
	else:
		target_position = position + move_direction * 2000
		
	ray.queue_free()

func snap_to_grid():
	position = position.snapped(Vector2(GRID_SIZE, GRID_SIZE))
	grid_position = Vector2i(position / GRID_SIZE)

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