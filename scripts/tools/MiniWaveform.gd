extends Control
class_name MiniWaveform

# Mini waveform display for the synth editor
# Shows a simplified representation of the current sound

var waveform_data = PackedFloat32Array()
var sound_type = 0
var sound_parameters = {}

func _ready():
	custom_minimum_size = Vector2(200, 150)
	
func update_waveform(new_sound_type: int, new_parameters: Dictionary):
	sound_type = new_sound_type
	sound_parameters = new_parameters
	generate_preview_waveform()
	queue_redraw()

func generate_preview_waveform():
	# Generate a simplified waveform for visualization
	var samples = 500  # Simplified for display
	waveform_data.clear()
	waveform_data.resize(samples)
	
	match sound_type:
		0: generate_kick_preview()    # Kick
		1: generate_snare_preview()   # Snare
		2: generate_hihat_preview()   # Hi-hat
		3: generate_chime_preview()   # Coin chime
		4: generate_tom_preview()     # Tom fill
		5: generate_guitar_preview()  # Guitar
		_: fill_silence()

func generate_kick_preview():
	var frequency = sound_parameters.get("frequency", 60)
	var decay = sound_parameters.get("decay", 0.15)
	
	for i in range(waveform_data.size()):
		var t = float(i) / waveform_data.size() * decay
		var freq = frequency * exp(-t * 20.0)
		var envelope = exp(-t * 15.0)
		waveform_data[i] = sin(2.0 * PI * freq * t * 10) * envelope

func generate_snare_preview():
	var tone = sound_parameters.get("tone", 200)
	var noise = sound_parameters.get("noise", 0.7)
	
	for i in range(waveform_data.size()):
		var t = float(i) / waveform_data.size() * 0.1
		var tone_component = sin(2.0 * PI * tone * t * 5) * (1.0 - noise)
		var noise_component = (randf() * 2.0 - 1.0) * noise
		var envelope = exp(-t * 30.0)
		waveform_data[i] = (tone_component + noise_component) * envelope

func generate_hihat_preview():
	var brightness = sound_parameters.get("brightness", 10000)
	var length = sound_parameters.get("length", 0.05)
	
	for i in range(waveform_data.size()):
		var t = float(i) / waveform_data.size() * length
		var high_freq = sin(2.0 * PI * brightness * 0.001 * t * 20)
		var envelope = exp(-t * 50.0)
		waveform_data[i] = high_freq * envelope * 0.7

func generate_chime_preview():
	var pitch = sound_parameters.get("pitch", 1200)
	var sustain = sound_parameters.get("sustain", 0.2)
	
	for i in range(waveform_data.size()):
		var t = float(i) / waveform_data.size() * sustain
		var fundamental = sin(2.0 * PI * pitch * 0.01 * t)
		var harmonic = sin(2.0 * PI * pitch * 0.02 * t) * 0.3
		var envelope = exp(-t * 8.0)
		waveform_data[i] = (fundamental + harmonic) * envelope

func generate_tom_preview():
	var power = sound_parameters.get("power", 0.4)
	
	for i in range(waveform_data.size()):
		var t = float(i) / waveform_data.size() * power
		var sample = 0.0
		
		# Three descending toms
		if t < power / 3.0:
			sample = sin(2.0 * PI * 180 * t * 5) * exp(-t * 25.0)
		elif t < power * 2.0 / 3.0:
			var tom_t = t - power / 3.0
			sample = sin(2.0 * PI * 140 * tom_t * 5) * exp(-tom_t * 25.0)
		else:
			var tom_t = t - power * 2.0 / 3.0
			sample = sin(2.0 * PI * 100 * tom_t * 5) * exp(-tom_t * 25.0) * 1.2
		
		waveform_data[i] = sample

func generate_guitar_preview():
	var warmth = sound_parameters.get("warmth", 300)
	var vibrato = sound_parameters.get("vibrato", 0.005)
	
	for i in range(waveform_data.size()):
		var t = float(i) / waveform_data.size() * 0.5
		var freq_mod = 1.0 + sin(2.0 * PI * 5.0 * t) * vibrato * 100
		var sample = sin(2.0 * PI * warmth * 0.1 * t * freq_mod) * 0.7
		var envelope = min(t * 4.0, 1.0) * exp(-t * 0.5)
		waveform_data[i] = sample * envelope

func fill_silence():
	for i in range(waveform_data.size()):
		waveform_data[i] = 0.0

func _draw():
	var rect = get_rect()
	
	# Background
	draw_rect(rect, Color(0.1, 0.1, 0.15))
	
	# Grid lines
	var center_y = rect.size.y * 0.5
	draw_line(Vector2(0, center_y), Vector2(rect.size.x, center_y), Color(0.3, 0.3, 0.4), 1.0)
	
	# Waveform
	if waveform_data.size() > 1:
		var color = get_waveform_color()
		
		for i in range(waveform_data.size() - 1):
			var x1 = float(i) / waveform_data.size() * rect.size.x
			var x2 = float(i + 1) / waveform_data.size() * rect.size.x
			var y1 = center_y - waveform_data[i] * rect.size.y * 0.4
			var y2 = center_y - waveform_data[i + 1] * rect.size.y * 0.4
			
			draw_line(Vector2(x1, y1), Vector2(x2, y2), color, 2.0)

func get_waveform_color() -> Color:
	match sound_type:
		0: return Color(0.8, 0.3, 0.3)  # Kick - red
		1: return Color(0.8, 0.8, 0.3)  # Snare - yellow
		2: return Color(0.3, 0.8, 0.8)  # Hi-hat - cyan
		3: return Color(1.0, 0.8, 0.3)  # Coin - gold
		4: return Color(0.8, 0.3, 0.8)  # Tom - magenta
		5: return Color(0.3, 0.8, 0.3)  # Guitar - green
		_: return Color.WHITE