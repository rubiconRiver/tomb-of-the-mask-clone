class_name MultiplierIndicator
extends Control

@onready var multiplier_label = $MultiplierLabel
@onready var flame_container = $FlameContainer
@onready var animation_player = $AnimationPlayer

const FLAME_COLORS = {
	1: Color(0.5, 0.5, 0.5),  # Gray - no flame
	2: Color(1.0, 0.5, 0.0),  # Orange - small flame
	3: Color(1.0, 0.3, 0.0),  # Red-orange - medium flame
	4: Color(1.0, 0.0, 0.0),  # Red - large flame
	5: Color(0.0, 0.5, 1.0)   # Blue - max flame
}

var current_multiplier = 1

func _ready():
	custom_minimum_size = Vector2(150, 100)
	update_display(1)

func update_multiplier(new_multiplier: int):
	if new_multiplier == current_multiplier:
		return
		
	var old_multiplier = current_multiplier
	current_multiplier = new_multiplier
	
	update_display(new_multiplier)
	
	# Play animation based on change
	if new_multiplier > old_multiplier:
		play_increase_animation()
	else:
		play_decrease_animation()

func update_display(multiplier: int):
	if multiplier_label:
		multiplier_label.text = str(multiplier) + "x"
		multiplier_label.modulate = FLAME_COLORS[multiplier]
		
		# Scale text based on multiplier
		var scale = 1.0 + (multiplier - 1) * 0.15
		multiplier_label.scale = Vector2(scale, scale)

func play_increase_animation():
	if animation_player and animation_player.has_animation("multiplier_increase"):
		animation_player.play("multiplier_increase")
	else:
		# Simple pulse effect
		var tween = create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_ELASTIC)
		tween.tween_property(multiplier_label, "scale", Vector2(1.3, 1.3), 0.2)
		tween.tween_property(multiplier_label, "scale", multiplier_label.scale, 0.3)

func play_decrease_animation():
	if animation_player and animation_player.has_animation("multiplier_decrease"):
		animation_player.play("multiplier_decrease")
	else:
		# Simple shake effect
		var tween = create_tween()
		var original_pos = multiplier_label.position
		tween.tween_property(multiplier_label, "position", original_pos + Vector2(5, 0), 0.05)
		tween.tween_property(multiplier_label, "position", original_pos - Vector2(5, 0), 0.05)
		tween.tween_property(multiplier_label, "position", original_pos, 0.05)