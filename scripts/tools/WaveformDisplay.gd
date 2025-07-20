extends Control
class_name WaveformDisplay

# WaveformDisplay provides real-time visual feedback for the audio synthesis
# Shows waveform, frequency spectrum, and other audio characteristics

var current_sound_type: AudioStudio.SoundType
var sound_shaper: SoundShaper
var waveform_data: PackedFloat32Array
var background_color = Color(0.1, 0.1, 0.15)
var waveform_color = Color(0.3, 0.8, 0.3)
var grid_color = Color(0.3, 0.3, 0.4, 0.5)

# Waveform generation settings
var sample_rate = 44100
var waveform_duration = 0.5  # Show 0.5 seconds of waveform
var waveform_samples = 2048  # Number of samples to display

func _ready():
	custom_minimum_size = Vector2(380, 300)
	
	# Initialize empty waveform data
	waveform_data.resize(waveform_samples)
	waveform_data.fill(0.0)

func set_sound_type(sound_type: AudioStudio.SoundType):
	current_sound_type = sound_type
	update_waveform()

func set_sound_shaper(shaper: SoundShaper):
	sound_shaper = shaper
	update_waveform()

func update_waveform():
	if sound_shaper == null:
		return
	
	# Generate waveform data based on current parameters
	generate_waveform_data()
	queue_redraw()

func generate_waveform_data():
	# Clear the waveform data
	waveform_data.fill(0.0)
	
	if sound_shaper == null:
		return
	
	# Generate waveform based on current sound type and parameters
	match current_sound_type:
		AudioStudio.SoundType.KICK_DRUM:
			generate_kick_waveform()
		AudioStudio.SoundType.SNARE_DRUM:
			generate_snare_waveform()
		AudioStudio.SoundType.HI_HAT:
			generate_hihat_waveform()
		AudioStudio.SoundType.COIN_CHIME:
			generate_coin_chime_waveform()
		AudioStudio.SoundType.WALL_HIT_TOM_FILL:
			generate_tom_fill_waveform()
		AudioStudio.SoundType.GUITAR_CHORD:
			generate_guitar_waveform()

func generate_kick_waveform():
	if sound_shaper == null:
		return
		
	var duration = sound_shaper.get_parameter("duration")
	var base_freq = sound_shaper.get_parameter("base_frequency")
	var pitch_sweep = sound_shaper.get_parameter("pitch_sweep_amount")
	var sweep_speed = sound_shaper.get_parameter("pitch_sweep_speed")
	var decay = sound_shaper.get_parameter("envelope_decay")
	
	var samples_for_duration = int(min(waveform_samples, duration * sample_rate))
	
	for i in range(samples_for_duration):
		var time = float(i) / sample_rate
		var envelope = exp(-time * decay)
		var frequency = base_freq + pitch_sweep * exp(-time * sweep_speed)
		var sample = sin(2.0 * PI * frequency * time) * envelope
		
		var index = int(float(i) / samples_for_duration * waveform_samples)
		if index < waveform_data.size():
			waveform_data[index] = sample

func generate_snare_waveform():
	if sound_shaper == null:
		return
		
	var duration = sound_shaper.get_parameter("duration")
	var tone_freq = sound_shaper.get_parameter("tone_frequency")
	var noise_ratio = sound_shaper.get_parameter("noise_ratio")
	var tone_amp = sound_shaper.get_parameter("tone_amplitude")
	var decay = sound_shaper.get_parameter("envelope_decay")
	
	var samples_for_duration = int(min(waveform_samples, duration * sample_rate))
	
	for i in range(samples_for_duration):
		var time = float(i) / sample_rate
		var envelope = exp(-time * decay)
		
		# For visualization, use deterministic "noise" (sine waves at different frequencies)
		var noise = sin(2.0 * PI * 5000.0 * time) * 0.3 + sin(2.0 * PI * 7000.0 * time) * 0.4
		noise *= noise_ratio
		var tone = sin(2.0 * PI * tone_freq * time) * tone_amp
		
		var sample = (noise + tone) * envelope
		
		var index = int(float(i) / samples_for_duration * waveform_samples)
		if index < waveform_data.size():
			waveform_data[index] = sample

func generate_hihat_waveform():
	if sound_shaper == null:
		return
		
	var duration = sound_shaper.get_parameter("duration")
	var metal_freq1 = sound_shaper.get_parameter("metallic_freq_1")
	var metal_freq2 = sound_shaper.get_parameter("metallic_freq_2")
	var metal_amp1 = sound_shaper.get_parameter("metallic_1_amplitude")
	var metal_amp2 = sound_shaper.get_parameter("metallic_2_amplitude")
	var noise_amp = sound_shaper.get_parameter("noise_amplitude")
	var decay = sound_shaper.get_parameter("envelope_decay")
	
	var samples_for_duration = int(min(waveform_samples, duration * sample_rate))
	
	for i in range(samples_for_duration):
		var time = float(i) / sample_rate
		var envelope = exp(-time * decay)
		
		# Deterministic high-frequency "noise" for visualization
		var noise = sin(2.0 * PI * 10000.0 * time) * 0.4 + sin(2.0 * PI * 13000.0 * time) * 0.3
		noise *= noise_amp
		var metallic1 = sin(2.0 * PI * metal_freq1 * time) * metal_amp1
		var metallic2 = sin(2.0 * PI * metal_freq2 * time) * metal_amp2
		
		var sample = (noise + metallic1 + metallic2) * envelope
		
		var index = int(float(i) / samples_for_duration * waveform_samples)
		if index < waveform_data.size():
			waveform_data[index] = sample

func generate_coin_chime_waveform():
	if sound_shaper == null:
		return
		
	var duration = sound_shaper.get_parameter("duration")
	var chord_type = int(sound_shaper.get_parameter("chord_type"))
	var base_octave = int(sound_shaper.get_parameter("base_octave"))
	var harmonic_richness = sound_shaper.get_parameter("harmonic_richness")
	var decay = sound_shaper.get_parameter("envelope_decay")
	
	# Define chord variations
	var chord_sets = [
		[1046.5, 1318.5, 1568.0],  # C major triad
		[1174.7, 1318.5, 1568.0],  # C sus2
		[1046.5, 1244.5, 1568.0]   # C with color tone
	]
	
	var frequencies = chord_sets[chord_type]
	var octave_multiplier = pow(2, base_octave - 6)
	for i in range(frequencies.size()):
		frequencies[i] *= octave_multiplier
	
	var samples_for_duration = int(min(waveform_samples, duration * sample_rate))
	
	for i in range(samples_for_duration):
		var time = float(i) / sample_rate
		var envelope = exp(-time * decay)
		
		var chime_sample = 0.0
		for freq in frequencies:
			var fundamental = sin(2.0 * PI * freq * time) * 0.6
			var harmonic2 = sin(2.0 * PI * freq * 2.0 * time) * harmonic_richness
			var harmonic3 = sin(2.0 * PI * freq * 3.0 * time) * (harmonic_richness * 0.5)
			chime_sample += (fundamental + harmonic2 + harmonic3) / 3.0
		
		var sample = chime_sample * envelope
		
		var index = int(float(i) / samples_for_duration * waveform_samples)
		if index < waveform_data.size():
			waveform_data[index] = sample

func generate_tom_fill_waveform():
	if sound_shaper == null:
		return
		
	var duration = sound_shaper.get_parameter("duration")
	var tom1_freq = sound_shaper.get_parameter("tom1_frequency")
	var tom2_freq = sound_shaper.get_parameter("tom2_frequency")
	var tom3_freq = sound_shaper.get_parameter("tom3_frequency")
	var tom1_decay = sound_shaper.get_parameter("tom1_decay")
	var tom2_decay = sound_shaper.get_parameter("tom2_decay")
	var tom3_decay = sound_shaper.get_parameter("tom3_decay")
	var noise_amount = sound_shaper.get_parameter("noise_amount")
	
	var samples_for_duration = int(min(waveform_samples, duration * sample_rate))
	
	for i in range(samples_for_duration):
		var time = float(i) / sample_rate
		var tom_sample = 0.0
		
		# Three tom hits with timing
		if time < 0.08:
			# First tom
			tom_sample = sin(2.0 * PI * tom1_freq * time) * exp(-time * tom1_decay) * 0.8
		elif time < 0.16:
			# Second tom
			var tom2_time = time - 0.08
			tom_sample = sin(2.0 * PI * tom2_freq * tom2_time) * exp(-tom2_time * tom2_decay) * 0.8
		elif time < 0.32:
			# Third tom
			var tom3_time = time - 0.16
			tom_sample = sin(2.0 * PI * tom3_freq * tom3_time) * exp(-tom3_time * tom3_decay) * 1.2
		
		# Add deterministic noise for visualization
		var noise = sin(2.0 * PI * 800.0 * time) * noise_amount
		var envelope = exp(-time * 10.0)
		var sample = (tom_sample + noise) * envelope
		
		var index = int(float(i) / samples_for_duration * waveform_samples)
		if index < waveform_data.size():
			waveform_data[index] = sample

func generate_guitar_waveform():
	if sound_shaper == null:
		return
		
	var chord_type = int(sound_shaper.get_parameter("chord_type"))
	var attack_time = sound_shaper.get_parameter("attack_time")
	var sustain_decay = sound_shaper.get_parameter("sustain_decay")
	var harmonic_content = sound_shaper.get_parameter("harmonic_content")
	var fundamental_amp = sound_shaper.get_parameter("fundamental_amplitude")
	
	# Define guitar chord variations
	var chord_frequencies = [
		[261.63, 329.63, 392.00, 493.88],  # Cmaj7
		[261.63, 311.13, 392.00, 466.16],  # Cmin7
		[261.63, 293.66, 392.00]           # Csus2
	]
	
	var frequencies = chord_frequencies[chord_type]
	
	# Show first 0.5 seconds of the guitar chord
	var display_duration = 0.5
	var samples_for_duration = int(display_duration * sample_rate)
	var display_samples = min(waveform_samples, samples_for_duration)
	
	for i in range(display_samples):
		var time = float(i) / sample_rate
		var envelope = 1.0 - exp(-time * attack_time)  # Attack
		envelope *= exp(-time * sustain_decay)  # Sustain decay
		
		var chord_sample = 0.0
		for freq in frequencies:
			var fundamental = sin(2.0 * PI * freq * time) * fundamental_amp
			var harmonic = sin(2.0 * PI * freq * 2.0 * time) * harmonic_content
			chord_sample += (fundamental + harmonic) / frequencies.size()
		
		var sample = chord_sample * envelope
		
		var index = int(float(i) / display_samples * waveform_samples)
		if index < waveform_data.size():
			waveform_data[index] = sample

func _draw():
	var rect = get_rect()
	
	# Draw background
	draw_rect(Rect2(Vector2.ZERO, rect.size), background_color)
	
	# Draw grid
	draw_grid(rect)
	
	# Draw waveform
	draw_waveform(rect)
	
	# Draw labels and info
	draw_labels(rect)

func draw_grid(rect: Rect2):
	var center_y = rect.size.y * 0.5
	
	# Horizontal center line
	draw_line(Vector2(0, center_y), Vector2(rect.size.x, center_y), grid_color, 1.0)
	
	# Horizontal grid lines
	for i in range(1, 5):
		var y = rect.size.y * i / 5.0
		draw_line(Vector2(0, y), Vector2(rect.size.x, y), grid_color * 0.5, 1.0)
	
	# Vertical grid lines
	for i in range(1, 10):
		var x = rect.size.x * i / 10.0
		draw_line(Vector2(x, 0), Vector2(x, rect.size.y), grid_color * 0.5, 1.0)

func draw_waveform(rect: Rect2):
	if waveform_data.size() < 2:
		return
	
	var center_y = rect.size.y * 0.5
	var scale_y = rect.size.y * 0.4  # Scale factor for amplitude
	var width = rect.size.x
	
	# Draw waveform as connected line segments
	for i in range(waveform_data.size() - 1):
		var x1 = float(i) / waveform_data.size() * width
		var x2 = float(i + 1) / waveform_data.size() * width
		var y1 = center_y - waveform_data[i] * scale_y
		var y2 = center_y - waveform_data[i + 1] * scale_y
		
		draw_line(Vector2(x1, y1), Vector2(x2, y2), waveform_color, 2.0)
	
	# Draw amplitude envelope as a subtle overlay
	draw_envelope_overlay(rect, center_y, scale_y)

func draw_envelope_overlay(rect: Rect2, center_y: float, scale_y: float):
	if sound_shaper == null:
		return
	
	var envelope_color = Color(1.0, 1.0, 0.3, 0.3)
	var width = rect.size.x
	
	# Get envelope parameters based on sound type
	var decay_rate = 10.0
	var duration = 0.2
	
	match current_sound_type:
		AudioStudio.SoundType.KICK_DRUM:
			decay_rate = sound_shaper.get_parameter("envelope_decay")
			duration = sound_shaper.get_parameter("duration")
		AudioStudio.SoundType.SNARE_DRUM:
			decay_rate = sound_shaper.get_parameter("envelope_decay")
			duration = sound_shaper.get_parameter("duration")
		AudioStudio.SoundType.HI_HAT:
			decay_rate = sound_shaper.get_parameter("envelope_decay")
			duration = sound_shaper.get_parameter("duration")
		AudioStudio.SoundType.COIN_CHIME:
			decay_rate = sound_shaper.get_parameter("envelope_decay")
			duration = sound_shaper.get_parameter("duration")
	
	# Draw envelope curve
	var envelope_points = PackedVector2Array()
	var steps = 100
	
	for i in range(steps + 1):
		var t = float(i) / steps
		var time = t * duration
		var envelope_value = exp(-time * decay_rate)
		
		var x = t * width
		var y = center_y - envelope_value * scale_y * 0.5
		envelope_points.append(Vector2(x, y))
	
	# Draw envelope lines
	for i in range(envelope_points.size() - 1):
		draw_line(envelope_points[i], envelope_points[i + 1], envelope_color, 1.5)

func draw_labels(rect: Rect2):
	var font = ThemeDB.fallback_font
	var font_size = 12
	
	# Draw amplitude labels
	draw_string(font, Vector2(5, 15), "1.0", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)
	draw_string(font, Vector2(5, rect.size.y * 0.5 + 5), "0.0", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)
	draw_string(font, Vector2(5, rect.size.y - 5), "-1.0", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)
	
	# Draw time labels (show duration)
	if sound_shaper:
		var duration = 0.5  # Default
		
		match current_sound_type:
			AudioStudio.SoundType.KICK_DRUM, AudioStudio.SoundType.SNARE_DRUM, AudioStudio.SoundType.HI_HAT, AudioStudio.SoundType.COIN_CHIME:
				duration = sound_shaper.get_parameter("duration")
			AudioStudio.SoundType.WALL_HIT_TOM_FILL:
				duration = sound_shaper.get_parameter("duration")
			AudioStudio.SoundType.GUITAR_CHORD:
				duration = 0.5  # Show first 0.5s for guitar
		
		draw_string(font, Vector2(rect.size.x - 50, rect.size.y - 5), "%.3fs" % duration, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)
	
	# Draw sound type label
	if current_sound_type != null:
		var sound_types = {
			AudioStudio.SoundType.KICK_DRUM: "Kick Drum",
			AudioStudio.SoundType.SNARE_DRUM: "Snare Drum", 
			AudioStudio.SoundType.HI_HAT: "Hi-Hat",
			AudioStudio.SoundType.COIN_CHIME: "Coin Chime",
			AudioStudio.SoundType.WALL_HIT_TOM_FILL: "Tom Fill",
			AudioStudio.SoundType.GUITAR_CHORD: "Guitar Chord"
		}
		
		var sound_name = sound_types.get(current_sound_type, "Unknown")
		var text_size = font.get_string_size(sound_name, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
		draw_string(font, Vector2(rect.size.x - text_size.x - 5, 15), sound_name, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, waveform_color)