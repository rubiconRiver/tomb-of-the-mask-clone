extends Area2D
class_name Goal

var time = 0.0
var portal_points = []

signal player_reached_goal

func _ready():
	# Create a spinning portal effect
	update_portal()

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
	var radius = 25.0
	
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
		print("Goal detection - Player pos: ", body.position, " Goal pos: ", position)
		print("Distance: ", body.position.distance_to(position))
		
		emit_signal("player_reached_goal")
		
		# Visual feedback
		var tween = get_tree().create_tween()
		tween.set_parallel(true)
		tween.tween_property(self, "scale", Vector2(2, 2), 0.3)
		tween.tween_property(self, "modulate:a", 0.0, 0.3)

func _on_animation_timer_timeout():
	# Additional animation updates if needed
	pass