extends Area2D
class_name Goal

signal player_reached_goal

func _ready():
	# Ensure goal is visible above other elements
	z_index = 10
	
	# Apply themed goal texture/visual
	setup_goal_visual()
	
	print("[Goal] Goal created at position: ", position)

func setup_goal_visual():
	# Try to get themed texture first
	var themed_texture = VisualThemeManager.get_goal_texture()
	
	# Look for existing visual nodes
	var visual_rect = get_node_or_null("Visual")
	var sprite_node = get_node_or_null("Sprite2D")
	
	if themed_texture:
		# Use sprite with themed texture
		if not sprite_node:
			sprite_node = Sprite2D.new()
			sprite_node.name = "Sprite2D"
			add_child(sprite_node)
		
		sprite_node.texture = themed_texture
		sprite_node.position = Vector2.ZERO
		
		# Hide ColorRect if it exists
		if visual_rect:
			visual_rect.visible = false
	else:
		# Fallback to ColorRect (current system)
		if visual_rect:
			visual_rect.visible = true
		# Keep the existing ColorRect setup

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