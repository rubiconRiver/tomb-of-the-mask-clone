extends RefCounted
class_name AudioGenerator

# Audio generation utilities for creating sounds programmatically
# Can be swapped out later for loading .wav files instead

const SAMPLE_RATE = 44100

# Basic waveform generation
static func generate_sine_wave(frequency: float, duration: float, amplitude: float = 0.5) -> PackedFloat32Array:
	var samples = int(SAMPLE_RATE * duration)
	var audio_data = PackedFloat32Array()
	
	for i in range(samples):
		var t = float(i) / float(SAMPLE_RATE)
		var envelope = calculate_envelope(t, duration)
		var sample = sin(2.0 * PI * frequency * t) * envelope * amplitude
		audio_data.append(sample)
	
	return audio_data

# Sine wave with vibrato (pitch modulation)
static func generate_sine_with_vibrato(frequency: float, duration: float, amplitude: float, 
                                      vibrato_rate: float, vibrato_depth: float) -> PackedFloat32Array:
	var samples = int(SAMPLE_RATE * duration)
	var audio_data = PackedFloat32Array()
	
	for i in range(samples):
		var t = float(i) / float(SAMPLE_RATE)
		var envelope = calculate_envelope(t, duration)
		var vibrato = 1.0 + sin(2.0 * PI * vibrato_rate * t) * vibrato_depth
		var sample = sin(2.0 * PI * frequency * vibrato * t) * envelope * amplitude
		audio_data.append(sample)
	
	return audio_data

# Sine wave with tremolo (amplitude modulation)
static func generate_sine_with_tremolo(frequency: float, duration: float, amplitude: float,
                                      tremolo_rate: float, tremolo_depth: float) -> PackedFloat32Array:
	var samples = int(SAMPLE_RATE * duration)
	var audio_data = PackedFloat32Array()
	
	for i in range(samples):
		var t = float(i) / float(SAMPLE_RATE)
		var envelope = calculate_envelope(t, duration)
		var tremolo = 1.0 - (sin(2.0 * PI * tremolo_rate * t) * tremolo_depth * 0.5 + tremolo_depth * 0.5)
		var sample = sin(2.0 * PI * frequency * t) * envelope * amplitude * tremolo
		audio_data.append(sample)
	
	return audio_data

# Multiple detuned voices for chorus effect
static func generate_sine_with_chorus(frequency: float, duration: float, amplitude: float, 
                                     voices: int) -> PackedFloat32Array:
	var samples = int(SAMPLE_RATE * duration)
	var audio_data = PackedFloat32Array()
	
	# Initialize with zeros
	for i in range(samples):
		audio_data.append(0.0)
	
	# Add multiple slightly detuned voices
	for v in range(voices):
		var detune = 1.0 + (v - voices/2.0) * 0.005  # Slight detuning
		var phase = randf() * 2.0 * PI  # Random phase
		
		for i in range(samples):
			var t = float(i) / float(SAMPLE_RATE)
			var envelope = calculate_envelope(t, duration)
			var sample = sin(2.0 * PI * frequency * detune * t + phase) * envelope * amplitude / voices
			audio_data[i] += sample
	
	return audio_data

# Arpeggio effect - rapid sequence of notes
static func generate_arpeggio_effect(frequencies: Array, duration: float, note_duration: float) -> PackedFloat32Array:
	var samples = int(SAMPLE_RATE * duration)
	var audio_data = PackedFloat32Array()
	
	for i in range(samples):
		var t = float(i) / float(SAMPLE_RATE)
		var note_index = int(t / note_duration) % frequencies.size()
		var frequency = frequencies[note_index]
		var envelope = calculate_envelope(t, duration) * 0.7
		var sample = sin(2.0 * PI * frequency * t) * envelope
		audio_data.append(sample)
	
	return audio_data

# Square wave for retro sounds
static func generate_square_wave(frequency: float, duration: float, amplitude: float = 0.5) -> PackedFloat32Array:
	var samples = int(SAMPLE_RATE * duration)
	var audio_data = PackedFloat32Array()
	
	for i in range(samples):
		var t = float(i) / float(SAMPLE_RATE)
		var envelope = calculate_envelope(t, duration)
		var sine_value = sin(2.0 * PI * frequency * t)
		var sample = sign(sine_value) * envelope * amplitude
		audio_data.append(sample)
	
	return audio_data

# Triangle wave for softer retro sounds
static func generate_triangle_wave(frequency: float, duration: float, amplitude: float = 0.5) -> PackedFloat32Array:
	var samples = int(SAMPLE_RATE * duration)
	var audio_data = PackedFloat32Array()
	
	for i in range(samples):
		var t = float(i) / float(SAMPLE_RATE)
		var envelope = calculate_envelope(t, duration)
		var phase = fmod(t * frequency, 1.0)
		var sample = 0.0
		
		if phase < 0.25:
			sample = phase * 4.0
		elif phase < 0.75:
			sample = 2.0 - phase * 4.0
		else:
			sample = phase * 4.0 - 4.0
		
		sample *= envelope * amplitude
		audio_data.append(sample)
	
	return audio_data

# Sawtooth wave for harsh/bright sounds
static func generate_sawtooth_wave(frequency: float, duration: float, amplitude: float = 0.5) -> PackedFloat32Array:
	var samples = int(SAMPLE_RATE * duration)
	var audio_data = PackedFloat32Array()
	
	for i in range(samples):
		var t = float(i) / float(SAMPLE_RATE)
		var envelope = calculate_envelope(t, duration)
		var phase = fmod(t * frequency, 1.0)
		var sample = (phase * 2.0 - 1.0) * envelope * amplitude
		audio_data.append(sample)
	
	return audio_data

# White noise for percussion/effects
static func generate_white_noise(duration: float, amplitude: float = 0.5) -> PackedFloat32Array:
	var samples = int(SAMPLE_RATE * duration)
	var audio_data = PackedFloat32Array()
	
	for i in range(samples):
		var t = float(i) / float(SAMPLE_RATE)
		var envelope = calculate_envelope(t, duration)
		var sample = (randf() * 2.0 - 1.0) * envelope * amplitude
		audio_data.append(sample)
	
	return audio_data

# ADSR Envelope calculation
static func calculate_envelope(t: float, duration: float, 
                              attack: float = 0.01, decay: float = 0.05, 
                              sustain: float = 0.8, release: float = 0.1) -> float:
	if t < attack:
		return t / attack
	elif t < attack + decay:
		var decay_progress = (t - attack) / decay
		return 1.0 - (1.0 - sustain) * decay_progress
	elif t < duration - release:
		return sustain
	else:
		var release_progress = (t - (duration - release)) / release
		return sustain * (1.0 - release_progress)

# Convert audio data to AudioStreamGenerator format
static func create_audio_stream_from_samples(audio_data: PackedFloat32Array) -> AudioStreamGenerator:
	var stream = AudioStreamGenerator.new()
	stream.mix_rate = SAMPLE_RATE
	stream.buffer_length = 0.5
	return stream

# Play audio data on an AudioStreamPlayer
static func play_samples_on_player(player: AudioStreamPlayer, audio_data: PackedFloat32Array, volume_db: float = 0.0):
	var stream = create_audio_stream_from_samples(audio_data)
	player.stream = stream
	player.volume_db = volume_db
	player.play()
	
	# Push audio data to playback
	var playback = player.get_stream_playback() as AudioStreamGeneratorPlayback
	if playback:
		# Convert to stereo frames
		var stereo_frames = PackedVector2Array()
		for sample in audio_data:
			stereo_frames.append(Vector2(sample, sample))
		
		# Push frames in chunks for better performance
		var chunk_size = 1024
		for i in range(0, stereo_frames.size(), chunk_size):
			var end_idx = min(i + chunk_size, stereo_frames.size())
			var chunk = stereo_frames.slice(i, end_idx)
			playback.push_buffer(chunk)