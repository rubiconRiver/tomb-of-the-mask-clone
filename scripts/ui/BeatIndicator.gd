extends Control
class_name BeatIndicator

@onready var indicator_rect = ColorRect.new()
var pulse_duration = 0.1
var pulse_timer = 0.0
var is_pulsing = false

func _ready():
	custom_minimum_size = Vector2(100, 100)
	size = Vector2(100, 100)
	
	indicator_rect.color = Color.WHITE
	indicator_rect.size = Vector2(80, 80)
	indicator_rect.position = Vector2(10, 10)
	indicator_rect.pivot_offset = indicator_rect.size / 2
	add_child(indicator_rect)
	
	modulate.a = 0.5

func _process(delta):
	if is_pulsing:
		pulse_timer += delta
		
		var progress = pulse_timer / pulse_duration
		if progress >= 1.0:
			is_pulsing = false
			pulse_timer = 0.0
			indicator_rect.scale = Vector2.ONE
		else:
			var scale = 1.0 + sin(progress * PI) * 0.3
			indicator_rect.scale = Vector2(scale, scale)

func pulse():
	is_pulsing = true
	pulse_timer = 0.0