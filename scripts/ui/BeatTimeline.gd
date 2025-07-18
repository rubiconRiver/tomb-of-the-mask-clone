extends Control
class_name BeatTimeline

var beat_timer: float = 0.0
var beat_interval: float = 0.5
var upcoming_beat_indicator: Control

func _ready():
	custom_minimum_size = Vector2(600, 60)
	position = Vector2(60, 500)
	
	# Create timeline background
	var background = ColorRect.new()
	background.color = Color(0.1, 0.1, 0.1, 0.8)
	background.size = custom_minimum_size
	add_child(background)
	
	# Create center line (the "now" marker)
	var center_line = ColorRect.new()
	center_line.color = Color(1.0, 1.0, 1.0, 1.0)
	center_line.size = Vector2(4, 60)
	center_line.position = Vector2(custom_minimum_size.x / 2 - 2, 0)
	add_child(center_line)
	
	# Create upcoming beat indicator
	upcoming_beat_indicator = ColorRect.new()
	upcoming_beat_indicator.color = Color(0.0, 1.0, 1.0, 1.0)
	upcoming_beat_indicator.size = Vector2(8, 60)
	add_child(upcoming_beat_indicator)
	
	# Add timing window indicators
	create_timing_windows()

func create_timing_windows():
	var center_x = custom_minimum_size.x / 2
	var pixels_per_second = 400.0  # How many pixels = 1 second
	
	# Perfect window (±50ms)
	var perfect_rect = ColorRect.new()
	perfect_rect.color = Color(1.0, 0.0, 1.0, 0.3)  # Magenta
	perfect_rect.size = Vector2(0.1 * pixels_per_second, 60)  # 100ms total width
	perfect_rect.position = Vector2(center_x - perfect_rect.size.x / 2, 0)
	add_child(perfect_rect)
	
	# Great window (±150ms)
	var great_rect = ColorRect.new()
	great_rect.color = Color(0.0, 1.0, 1.0, 0.2)  # Cyan
	great_rect.size = Vector2(0.3 * pixels_per_second, 60)  # 300ms total width
	great_rect.position = Vector2(center_x - great_rect.size.x / 2, 0)
	add_child(great_rect)
	
	# Good window (±300ms)
	var good_rect = ColorRect.new()
	good_rect.color = Color(0.0, 1.0, 0.0, 0.1)  # Green
	good_rect.size = Vector2(0.6 * pixels_per_second, 60)  # 600ms total width
	good_rect.position = Vector2(center_x - good_rect.size.x / 2, 0)
	add_child(good_rect)

func update_beat(timer: float, interval: float):
	beat_timer = timer
	beat_interval = interval
	
	# Calculate position of next beat
	var time_to_beat = beat_interval - beat_timer
	var pixels_per_second = 400.0
	var beat_x = (custom_minimum_size.x / 2) + (time_to_beat * pixels_per_second)
	
	# Position the beat indicator
	upcoming_beat_indicator.position.x = beat_x - 4
	
	# Pulse effect when close to center
	if abs(time_to_beat) < 0.05:
		upcoming_beat_indicator.modulate = Color(1.0, 1.0, 0.0, 1.0)  # Yellow flash
		upcoming_beat_indicator.size = Vector2(12, 60)
		upcoming_beat_indicator.position.x -= 2
	else:
		upcoming_beat_indicator.modulate = Color(0.0, 1.0, 1.0, 1.0)  # Cyan
		upcoming_beat_indicator.size = Vector2(8, 60)