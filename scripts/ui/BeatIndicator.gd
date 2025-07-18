class_name BeatIndicator
extends Control

var pulse_timer = 0.0
var pulse_duration = 0.15
var beat_count = 0

func _ready():
	custom_minimum_size = Vector2(80, 80)
	position = Vector2(20, 20)

func _draw():
	var center = Vector2(40, 40)
	
	# Draw background circle
	draw_circle(center, 35, Color(0.1, 0.1, 0.1, 0.8))
	
	# Draw beat pulse
	if pulse_timer > 0:
		var progress = pulse_timer / pulse_duration
		
		# Outer ring that expands
		var ring_radius = 25 + (1.0 - progress) * 15
		var ring_width = 3.0 + progress * 2.0
		draw_arc(center, ring_radius, 0, TAU, 64, Color(1.0, 1.0, 1.0, progress), ring_width)
		
		# Inner filled circle that flashes
		var inner_radius = 20 + sin(progress * PI) * 5
		draw_circle(center, inner_radius, Color(0.0, 1.0, 1.0, 0.8 + progress * 0.2))
		
		# Beat number in center
		var font = ThemeDB.fallback_font
		var text = str(beat_count % 4 + 1)
		var text_size = font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, 24)
		draw_string(font, center - text_size / 2 + Vector2(0, 8), text, 
					HORIZONTAL_ALIGNMENT_CENTER, -1, 24, Color(0.0, 0.0, 0.0, 1.0))
	else:
		# Idle state - small cyan circle
		draw_circle(center, 20, Color(0.0, 0.5, 0.5, 0.5))

func _process(delta):
	if pulse_timer > 0:
		pulse_timer -= delta
		queue_redraw()

func pulse():
	pulse_timer = pulse_duration
	beat_count += 1
	queue_redraw()