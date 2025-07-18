extends Label
class_name TimingFeedback

var velocity = Vector2(0, -100)
var lifetime = 1.0
var elapsed = 0.0

func setup(text: String, color: Color, start_position: Vector2):
	self.text = text
	self.modulate = color
	self.position = start_position
	
	# Basic text settings
	add_theme_font_size_override("font_size", 24)
	
func _ready():
	# Center the text
	pivot_offset = size / 2

func _process(delta):
	elapsed += delta
	
	# Move upward
	position += velocity * delta
	
	# Fade out
	modulate.a = 1.0 - (elapsed / lifetime)
	
	# Scale effect
	var scale_factor = 1.0 + (elapsed * 0.5)
	scale = Vector2(scale_factor, scale_factor)
	
	# Remove when done
	if elapsed >= lifetime:
		queue_free()