class_name MultiplierIndicator
extends Control

@onready var multiplier_label = $MultiplierLabel

const FLAME_COLORS = {
	1: Color(0.5, 0.5, 0.5),   # Gray - no flame
	2: Color(1.0, 0.8, 0.0),   # Yellow - small flame
	3: Color(1.0, 0.5, 0.0),   # Orange - growing flame
	4: Color(1.0, 0.3, 0.0),   # Red-orange - medium flame
	5: Color(1.0, 0.0, 0.0),   # Red - large flame
	6: Color(0.8, 0.0, 0.8),   # Magenta - intense flame
	7: Color(0.5, 0.0, 1.0),   # Purple - powerful flame
	8: Color(0.0, 0.5, 1.0)    # Blue - max flame (octave!)
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
		# Clamp to valid range
		var clamped_multiplier = clamp(multiplier, 1, 8)
		multiplier_label.modulate = FLAME_COLORS[clamped_multiplier]
		
		# Scale text based on multiplier (slightly less scaling for 8 levels)
		var scale = 1.0 + (clamped_multiplier - 1) * 0.1
		multiplier_label.scale = Vector2(scale, scale)

func play_increase_animation():
	# Simple pulse effect
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(multiplier_label, "scale", Vector2(1.3, 1.3), 0.2)
	tween.tween_property(multiplier_label, "scale", multiplier_label.scale, 0.3)

func play_decrease_animation():
	# Simple shake effect
	var tween = create_tween()
	var original_pos = multiplier_label.position
	tween.tween_property(multiplier_label, "position", original_pos + Vector2(5, 0), 0.05)
	tween.tween_property(multiplier_label, "position", original_pos - Vector2(5, 0), 0.05)
	tween.tween_property(multiplier_label, "position", original_pos, 0.05)