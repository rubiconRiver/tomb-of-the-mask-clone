extends Control
class_name MiniWaveform

# Mini waveform display for the synth editor
var current_audio_data: PackedFloat32Array = PackedFloat32Array()
var current_sound_type: String = ""

# Colors for different sound types
var sound_colors = {
	"Kick Drum": Color(1.0, 0.3, 0.3),      # Red
	"Snare Drum": Color(1.0, 0.8, 0.3),     # Orange  
	"Hi-Hat": Color(1.0, 1.0, 0.3),         # Yellow
	"Coin Chime": Color(0.3, 1.0, 0.8),     # Cyan
	"Wall Hit (Tom Fill)": Color(0.8, 0.3, 1.0), # Purple
	"Guitar Chord": Color(0.3, 0.8, 0.3)    # Green
}

func _init():
	name = "MiniWaveform"

func _ready():
	# Set up background
	var background = StyleBoxFlat.new()
	background.bg_color = Color(0.1, 0.1, 0.15)
	background.border_width_left = 1
	background.border_width_right = 1
	background.border_width_top = 1
	background.border_width_bottom = 1
	background.border_color = Color(0.3, 0.3, 0.4)
	add_theme_stylebox_override("panel", background)

func update_waveform(audio_data: PackedFloat32Array, sound_type: String):
	current_audio_data = audio_data
	current_sound_type = sound_type
	queue_redraw()

func _draw():
	if current_audio_data.size() == 0:
		return
	
	var rect = get_rect()
	var center_y = rect.size.y * 0.5
	var width = rect.size.x
	var height = rect.size.y * 0.8  # Leave some margin
	
	# Get color for current sound type
	var waveform_color = sound_colors.get(current_sound_type, Color.WHITE)
	
	# Draw waveform
	var samples_to_draw = min(current_audio_data.size(), int(width))
	var step = float(current_audio_data.size()) / float(samples_to_draw)
	
	var points = PackedVector2Array()
	
	for i in range(samples_to_draw):
		var sample_index = int(i * step)
		if sample_index < current_audio_data.size():
			var sample = current_audio_data[sample_index]
			var x = float(i) / float(samples_to_draw - 1) * width
			var y = center_y - (sample * height * 0.5)
			points.append(Vector2(x, y))
	
	# Draw the waveform line
	if points.size() > 1:
		for i in range(points.size() - 1):
			draw_line(points[i], points[i + 1], waveform_color, 2.0)
	
	# Draw center line
	draw_line(Vector2(0, center_y), Vector2(width, center_y), Color(0.3, 0.3, 0.3), 1.0)
	
	# Draw sound type label
	var font = ThemeDB.fallback_font
	var font_size = 12
	var text = current_sound_type
	var text_size = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var text_pos = Vector2(10, text_size.y + 5)
	draw_string(font, text_pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0.8, 0.8, 0.9))