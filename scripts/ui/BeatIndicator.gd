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
		var is_fourth_beat = (beat_count % 4 == 0)
		
		# Outer ring that expands - bigger on 4th beat
		var ring_expansion = 15 if not is_fourth_beat else 25
		var ring_radius = 25 + (1.0 - progress) * ring_expansion
		var ring_width = 3.0 + progress * 2.0
		var ring_color = Color(1.0, 1.0, 1.0, progress) if not is_fourth_beat else Color(1.0, 0.0, 1.0, progress)
		draw_arc(center, ring_radius, 0, TAU, 64, ring_color, ring_width)
		
		# Inner filled circle that flashes - different color on 4th beat
		var inner_radius = 20 + sin(progress * PI) * 5
		var circle_color = Color(0.0, 1.0, 1.0, 0.8 + progress * 0.2) if not is_fourth_beat else Color(1.0, 0.0, 1.0, 0.9 + progress * 0.1)
		draw_circle(center, inner_radius, circle_color)
		
		# Beat number in center - bigger on 4th beat
		var font = ThemeDB.fallback_font
		var text = "4!" if is_fourth_beat else str((beat_count % 4) + 1)
		var font_size = 24 if not is_fourth_beat else 32
		var text_size = font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
		draw_string(font, center - text_size / 2 + Vector2(0, 8), text, 
					HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, Color(0.0, 0.0, 0.0, 1.0))
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

func pulse_strong():
	# Longer, stronger pulse for 4th beat
	pulse_timer = pulse_duration * 1.5
	beat_count += 1
	queue_redraw()
	print("[BEAT] Beat 4 (PURPLE) - beat_count: ", beat_count)