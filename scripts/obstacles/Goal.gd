extends Area2D
class_name Goal

signal player_reached_goal

func _ready():
	# Ensure goal is visible above other elements
	z_index = 10
	print("[Goal] Simple blue goal created at position: ", position)

func _on_body_entered(body):
	if body.is_in_group("player"):
		print("[Goal] Player reached goal - completing level")
		print("  Goal pos: ", position)
		print("  Player pos: ", body.position)
		
		emit_signal("player_reached_goal")
		
		# Simple visual feedback
		var tween = get_tree().create_tween()
		tween.tween_property(self, "modulate", Color(1, 1, 1, 0), 0.5)

func _on_animation_timer_timeout():
	# Additional animation updates if needed
	pass