class_name BeatTimeline
extends Control

var beat_timer: float = 0.0
var beat_interval: float = 0.5
var upcoming_beat_indicator: Control
var instructions_label: Label
var is_visible: bool = true

func _ready():
	custom_minimum_size = Vector2(600, 120)
	position = Vector2(60, 400)
	
	# Create semi-transparent background
	var background = ColorRect.new()
	background.color = Color(0.05, 0.05, 0.05, 0.9)
	background.size = custom_minimum_size
	add_child(background)
	
	# Create center line (the "now" marker)
	var center_line = ColorRect.new()
	center_line.color = Color(1.0, 1.0, 1.0, 1.0)
	center_line.size = Vector2(4, 60)
	center_line.position = Vector2(custom_minimum_size.x / 2 - 2, 0)
	add_child(center_line)
	
	# Create upcoming beat indicator (circle)
	upcoming_beat_indicator = Control.new()
	upcoming_beat_indicator.custom_minimum_size = Vector2(40, 40)
	add_child(upcoming_beat_indicator)
	
	# Add instructions
	instructions_label = Label.new()
	instructions_label.text = "Make sure the beat lines up - use LEFT/RIGHT keys to adjust the delay.\nHit ESC to close/open"
	instructions_label.position = Vector2(10, 65)
	instructions_label.size = Vector2(580, 50)
	instructions_label.add_theme_font_size_override("font_size", 14)
	instructions_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	instructions_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(instructions_label)
	
	# Add timing window indicators
	create_timing_windows()

func create_timing_windows():
	var center_x = custom_minimum_size.x / 2
	var pixels_per_second = 400.0  # How many pixels = 1 second
	
	# Perfect window (±120ms)
	var perfect_rect = ColorRect.new()
	perfect_rect.color = Color(1.0, 0.0, 1.0, 0.3)  # Magenta
	perfect_rect.size = Vector2(0.24 * pixels_per_second, 60)  # 240ms total width
	perfect_rect.position = Vector2(center_x - perfect_rect.size.x / 2, 0)
	add_child(perfect_rect)
	
	# Great window (±250ms)
	var great_rect = ColorRect.new()
	great_rect.color = Color(0.0, 1.0, 1.0, 0.2)  # Cyan
	great_rect.size = Vector2(0.5 * pixels_per_second, 60)  # 500ms total width
	great_rect.position = Vector2(center_x - great_rect.size.x / 2, 0)
	add_child(great_rect)
	
	# Good window (±400ms)
	var good_rect = ColorRect.new()
	good_rect.color = Color(0.0, 1.0, 0.0, 0.1)  # Green
	good_rect.size = Vector2(0.8 * pixels_per_second, 60)  # 800ms total width
	good_rect.position = Vector2(center_x - good_rect.size.x / 2, 0)
	add_child(good_rect)

func update_beat(timer: float, interval: float):
	beat_timer = timer
	beat_interval = interval
	
	# Calculate position of next beat
	var time_to_beat = beat_interval - beat_timer
	var pixels_per_second = 400.0
	var beat_x = (custom_minimum_size.x / 2) + (time_to_beat * pixels_per_second)
	
	# Position the beat indicator (centered)
	upcoming_beat_indicator.position = Vector2(beat_x - 20, 10)
	
	# Clear previous drawing
	upcoming_beat_indicator.queue_redraw()

func _draw():
	if upcoming_beat_indicator:
		var center = upcoming_beat_indicator.position + Vector2(20, 20)
		var time_to_beat = beat_interval - beat_timer
		
		# Draw circle - make it pulse and change color when on beat
		if abs(time_to_beat) < 0.05:
			# ON BEAT - Big white circle with high contrast
			draw_circle(center, 25, Color(1.0, 1.0, 1.0, 1.0))
			draw_circle(center, 20, Color(0.0, 0.0, 0.0, 1.0))
			draw_circle(center, 15, Color(1.0, 0.0, 1.0, 1.0))  # Magenta center
		else:
			# Approaching beat - Cyan circle
			draw_circle(center, 15, Color(0.0, 1.0, 1.0, 0.8))
			draw_circle(center, 12, Color(0.0, 0.0, 0.0, 0.8))
			draw_circle(center, 10, Color(0.0, 1.0, 1.0, 1.0))

func _process(_delta):
	queue_redraw()  # Continuously redraw for smooth animation
	
func toggle_visibility():
	visible = not visible
	is_visible = visible