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

# Push audio samples directly to a playback buffer (for real-time generation)
static func push_samples_to_playback(playback: AudioStreamGeneratorPlayback, audio_data: PackedFloat32Array, volume: float = 1.0):
	# Convert to stereo frames and push
	for sample in audio_data:
		var frame = Vector2(sample, sample) * volume
		playback.push_frame(frame)

# ========== DRUM SOUNDS ==========

# Kick drum - deep bass thump
static func generate_kick_drum() -> PackedFloat32Array:
	var duration = 0.15
	var samples = int(SAMPLE_RATE * duration)
	var audio_data = PackedFloat32Array()
	
	for i in samples:
		var time = float(i) / SAMPLE_RATE
		var envelope = exp(-time * 20.0)
		
		# Main tone around 60 Hz with fast decay
		var frequency = 60.0 * exp(-time * 35.0)  # Pitch drop effect
		var main_tone = sin(2.0 * PI * frequency * time)
		
		# Add click attack for punch
		var click = sin(2.0 * PI * 1500.0 * time) * exp(-time * 100.0)
		
		var sample = (main_tone * 0.8 + click * 0.2) * envelope
		audio_data.append(sample)
	
	return audio_data

# Snare drum - noise burst with tonal component
static func generate_snare_drum() -> PackedFloat32Array:
	var duration = 0.1
	var samples = int(SAMPLE_RATE * duration)
	var audio_data = PackedFloat32Array()
	
	for i in samples:
		var time = float(i) / SAMPLE_RATE
		var envelope = exp(-time * 25.0)
		
		# Snare drum component (noise burst)
		var noise = (randf() * 2.0 - 1.0) * 0.7
		
		# Tonal component
		var tone = sin(2.0 * PI * 200.0 * time) * 0.3
		
		var sample = (noise + tone) * envelope
		audio_data.append(sample)
	
	return audio_data

# Hi-hat - high frequency noise burst
static func generate_hihat_sound() -> PackedFloat32Array:
	var duration = 0.05  # Very short for crisp hi-hat
	var samples = int(SAMPLE_RATE * duration)
	var audio_data = PackedFloat32Array()
	
	for i in samples:
		var time = float(i) / SAMPLE_RATE
		var envelope = exp(-time * 40.0)  # Very fast decay
		
		# Generate hi-hat with high-frequency noise and metallic shimmer
		var noise = (randf() * 2.0 - 1.0) * 0.8
		var metallic1 = sin(2.0 * PI * 8000.0 * time) * 0.3
		var metallic2 = sin(2.0 * PI * 12000.0 * time) * 0.2
		
		var sample = (noise + metallic1 + metallic2) * envelope
		audio_data.append(sample)
	
	return audio_data

# Tom fill - descending toms
static func generate_wall_hit_tom_fill() -> PackedFloat32Array:
	var duration = 0.4  # Slightly longer for 3-note fill
	var samples = int(SAMPLE_RATE * duration)
	var audio_data = PackedFloat32Array()
	
	for i in samples:
		var time = float(i) / SAMPLE_RATE
		var envelope = exp(-time * 10.0)  # Moderate decay for punchy tom sequence
		
		# Three tom hits: du-du-DUH pattern (high-high-low)
		var tom1_freq = 180.0  # High tom (du)
		var tom2_freq = 160.0  # High tom (du) 
		var tom3_freq = 80.0   # Low tom (DUH!)
		
		# Timing: tom1 (0-0.08s), tom2 (0.08-0.16s), tom3 (0.16-0.32s)
		var tom_sample = 0.0
		if time < 0.08:
			# First tom (du) - crisp and high
			tom_sample = sin(2.0 * PI * tom1_freq * time) * exp(-time * 30.0) * 0.8
		elif time < 0.16:
			# Second tom (du) - similar pitch, slight variation
			var tom2_time = time - 0.08
			tom_sample = sin(2.0 * PI * tom2_freq * tom2_time) * exp(-tom2_time * 30.0) * 0.8
		elif time < 0.32:
			# Third tom (DUH!) - deep and punchy
			var tom3_time = time - 0.16
			tom_sample = sin(2.0 * PI * tom3_freq * tom3_time) * exp(-tom3_time * 20.0) * 1.2  # Louder for emphasis
		
		# Add noise for realistic tom texture
		var noise = (randf() * 2.0 - 1.0) * 0.25 * envelope
		var final_sample = (tom_sample + noise) * envelope * 0.75
		audio_data.append(final_sample)
	
	return audio_data

# ========== MELODIC SOUNDS ==========

# Coin chime - beautiful melodic sound
static func generate_coin_chime() -> PackedFloat32Array:
	var duration = 0.2  # Shorter for 8th note frequency
	var samples = int(SAMPLE_RATE * duration)
	var audio_data = PackedFloat32Array()
	
	# Three beautiful coin chime variations - pleasing melodic intervals
	var chime_sets = [
		[1046.5, 1318.5, 1568.0],  # C6, E6, G6 (major triad - bright & happy)
		[1174.7, 1318.5, 1568.0],  # D6, E6, G6 (sus2 harmony - dreamy)
		[1046.5, 1244.5, 1568.0]   # C6, D#6, G6 (major with color tone - mystical)
	]
	
	# Randomly choose one of the three chime sets
	var chime_frequencies = chime_sets[randi() % chime_sets.size()]
	
	for i in samples:
		var time = float(i) / SAMPLE_RATE
		var envelope = exp(-time * 12.0)  # Faster decay for crisp 8th note timing
		
		var chime_sample = 0.0
		for freq in chime_frequencies:
			# Add harmonics for bell-like quality
			var fundamental = sin(2.0 * PI * freq * time) * 0.6
			var harmonic2 = sin(2.0 * PI * freq * 2.0 * time) * 0.2
			var harmonic3 = sin(2.0 * PI * freq * 3.0 * time) * 0.1
			chime_sample += (fundamental + harmonic2 + harmonic3) / 3.0
		
		var final_sample = chime_sample * envelope * 0.35  # Slightly quieter for frequent use
		audio_data.append(final_sample)
	
	return audio_data

# ========== AMBIENT SOUNDS ==========

# Ambient guitar chord chunk (for continuous playback)
static func generate_guitar_chord_chunk(time_position: float, chunk_size: int, sample_rate: float) -> PackedFloat32Array:
	var audio_data = PackedFloat32Array()
	
	# Define a nice ambient chord (Cmaj7 - C, E, G, B)
	var chord_frequencies = [261.63, 329.63, 392.00, 493.88]  # C4, E4, G4, B4
	
	for i in chunk_size:
		var time = time_position + float(i) / sample_rate
		var sample = 0.0
		
		# Mix all chord notes
		for freq in chord_frequencies:
			# Add slight vibrato for warmth
			var vibrato = 1.0 + sin(2.0 * PI * 5.0 * time) * 0.005
			sample += sin(2.0 * PI * freq * vibrato * time) * 0.25
		
		# Soft constant volume for continuous playback
		sample *= 0.3
		
		audio_data.append(sample)
	
	return audio_data

# Ambient guitar chord (one-shot)
static func generate_guitar_chord(duration: float) -> PackedFloat32Array:
	var samples = int(SAMPLE_RATE * duration)
	var audio_data = PackedFloat32Array()
	
	# Define a nice ambient chord (Cmaj7 - C, E, G, B)
	var chord_frequencies = [261.63, 329.63, 392.00, 493.88]  # C4, E4, G4, B4
	
	for i in samples:
		var time = float(i) / SAMPLE_RATE
		var sample = 0.0
		
		# Mix all chord notes
		for freq in chord_frequencies:
			# Add slight vibrato for warmth
			var vibrato = 1.0 + sin(2.0 * PI * 5.0 * time) * 0.005
			sample += sin(2.0 * PI * freq * vibrato * time) * 0.25
		
		# Soft envelope
		var envelope = min(time * 2.0, 1.0) * (1.0 - time / duration)
		sample *= envelope * 0.3
		
		audio_data.append(sample)
	
	return audio_data