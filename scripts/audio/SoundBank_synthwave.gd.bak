class_name SoundBank
extends RefCounted

# ============================================
# CENTRAL SOUND BANK - ALL GAME SOUNDS
# ============================================
# This file contains ALL sound generation for the game.
# To change any sound, just modify the appropriate function below.
# Your synthesizer friend can replace any of these with their own sounds!

const SAMPLE_RATE = 44100

# Cache for pre-generated sounds
static var cached_sounds = {}
static var _initialized = false

static func initialize():
	if _initialized:
		return
	
	print("[SoundBank] Pre-generating all game sounds...")
	
	# Pre-generate all sounds that don't change
	_cache_drum_sounds()
	_cache_sfx_sounds()
	_cache_melodic_sounds()
	# _cache_ambient_sounds()  # Guitar disabled for performance
	
	_initialized = true
	print("[SoundBank] Cached ", cached_sounds.size(), " sounds")

# ============================================
# DRUM SOUNDS
# ============================================

static func _cache_drum_sounds():
	cached_sounds["kick"] = generate_kick()
	cached_sounds["snare"] = generate_snare()
	cached_sounds["hihat"] = generate_hihat()
	cached_sounds["hihat_open"] = generate_hihat_open()
	cached_sounds["tom_high"] = generate_tom_high()
	cached_sounds["tom_mid"] = generate_tom_mid()
	cached_sounds["tom_low"] = generate_tom_low()

static func get_kick() -> PackedFloat32Array:
	return cached_sounds.get("kick", PackedFloat32Array())

static func get_snare() -> PackedFloat32Array:
	return cached_sounds.get("snare", PackedFloat32Array())

static func get_hihat() -> PackedFloat32Array:
	return cached_sounds.get("hihat", PackedFloat32Array())

# Synthwave Kick - deep analog 808-style with sub bass
static func generate_kick() -> PackedFloat32Array:
	var duration = 0.25  # Longer for that laidback feel
	var samples = int(SAMPLE_RATE * duration)
	var audio_data = PackedFloat32Array()
	
	for i in samples:
		var time = float(i) / SAMPLE_RATE
		var envelope = exp(-time * 12.0)  # Slower decay for more groove
		
		# Deep sub bass around 45 Hz with analog-style pitch sweep
		var frequency = 45.0 * exp(-time * 25.0)
		var main_tone = sin(2.0 * PI * frequency * time)
		
		# Add analog-style saturation using tanh
		main_tone = tanh(main_tone * 2.0) * 0.5
		
		# Subtle analog click attack
		var click = sin(2.0 * PI * 1200.0 * time) * exp(-time * 80.0) * 0.15
		
		# Add subtle harmonic for warmth
		var harmonic = sin(2.0 * PI * frequency * 2.0 * time) * 0.2 * envelope
		
		var sample = (main_tone * 0.75 + click + harmonic) * envelope * 1.2
		audio_data.append(soft_clip(sample, 0.9))
	
	return audio_data

# Synthwave Snare - gated reverb-style with analog warmth
static func generate_snare() -> PackedFloat32Array:
	var duration = 0.18  # Longer for that gated reverb tail
	var samples = int(SAMPLE_RATE * duration)
	var audio_data = PackedFloat32Array()
	
	for i in samples:
		var time = float(i) / SAMPLE_RATE
		
		# Classic gated reverb envelope - quick attack, sustain, then gate off
		var envelope = 1.0
		if time < 0.02:
			envelope = time / 0.02  # Attack
		elif time < 0.08:
			envelope = 1.0  # Sustain
		else:
			envelope = exp(-(time - 0.08) * 35.0)  # Gated decay
		
		# Analog-style filtered noise
		var noise = (randf() * 2.0 - 1.0) * 0.8
		# Simple lowpass filtering simulation
		noise = tanh(noise * 1.5) * 0.7
		
		# Warm tonal component at 220Hz (slightly higher for synthwave)
		var tone = sin(2.0 * PI * 220.0 * time) * 0.4
		
		# Add subtle harmonic content
		var harmonic = sin(2.0 * PI * 440.0 * time) * 0.15 * envelope
		
		var sample = (noise * 0.7 + tone * 0.8 + harmonic) * envelope * 0.9
		audio_data.append(soft_clip(sample, 0.85))
	
	return audio_data

# Synthwave Hi-hat - crisp analog-style with filtered noise
static func generate_hihat() -> PackedFloat32Array:
	var duration = 0.08  # Slightly longer for more groove
	var samples = int(SAMPLE_RATE * duration)
	var audio_data = PackedFloat32Array()
	
	for i in samples:
		var time = float(i) / SAMPLE_RATE
		var envelope = exp(-time * 30.0)
		
		# Filtered high frequency noise for analog warmth
		var noise = (randf() * 2.0 - 1.0) * 0.9
		# Simulate analog filter resonance
		noise = tanh(noise * 2.0) * 0.6
		
		# Warm metallic overtones (lower frequencies for synthwave)
		var metallic1 = sin(2.0 * PI * 6000.0 * time) * 0.25
		var metallic2 = sin(2.0 * PI * 9000.0 * time) * 0.15
		
		# Add subtle FM modulation for character
		var mod_freq = sin(2.0 * PI * 80.0 * time) * 0.1
		var fm_tone = sin(2.0 * PI * 7000.0 * time + mod_freq) * 0.2
		
		var sample = (noise * 0.7 + metallic1 + metallic2 + fm_tone) * envelope * 0.8
		audio_data.append(soft_clip(sample, 0.8))
	
	return audio_data

# Synthwave Open Hi-hat - lush decay with analog character
static func generate_hihat_open() -> PackedFloat32Array:
	var duration = 0.22  # Longer for that lush synthwave decay
	var samples = int(SAMPLE_RATE * duration)
	var audio_data = PackedFloat32Array()
	
	for i in samples:
		var time = float(i) / SAMPLE_RATE
		var envelope = exp(-time * 7.0)  # Even slower decay for laidback feel
		
		# Filtered noise with analog character
		var noise = (randf() * 2.0 - 1.0) * 0.8
		noise = tanh(noise * 1.8) * 0.65
		
		# Warm metallic resonances
		var metallic1 = sin(2.0 * PI * 5500.0 * time) * 0.35
		var metallic2 = sin(2.0 * PI * 8200.0 * time) * 0.25
		
		# Add subtle chorus-like modulation for width
		var lfo = sin(2.0 * PI * 3.2 * time) * 0.05
		var modulated = sin(2.0 * PI * 6500.0 * time * (1.0 + lfo)) * 0.2
		
		var sample = (noise * 0.6 + metallic1 + metallic2 + modulated) * envelope * 0.75
		audio_data.append(soft_clip(sample, 0.8))
	
	return audio_data

# Synthwave Tom drums - analog warmth with deeper resonance
static func generate_tom_high() -> PackedFloat32Array:
	return _generate_synthwave_tom(160.0, 0.12)  # Slightly lower and longer

static func generate_tom_mid() -> PackedFloat32Array:
	return _generate_synthwave_tom(120.0, 0.15)

static func generate_tom_low() -> PackedFloat32Array:
	return _generate_synthwave_tom(65.0, 0.22)   # Much deeper for synthwave

static func _generate_synthwave_tom(frequency: float, duration: float) -> PackedFloat32Array:
	var samples = int(SAMPLE_RATE * duration)
	var audio_data = PackedFloat32Array()
	
	for i in samples:
		var time = float(i) / SAMPLE_RATE
		var envelope = exp(-time * 8.0)  # Slower decay for more resonance
		
		# Analog-style pitch bend with smooth curve
		var bent_freq = frequency * exp(-time * 6.0)
		var fundamental = sin(2.0 * PI * bent_freq * time)
		
		# Add warm harmonic content
		var harmonic2 = sin(2.0 * PI * bent_freq * 2.0 * time) * 0.3
		var harmonic3 = sin(2.0 * PI * bent_freq * 0.5 * time) * 0.4  # Sub harmonic
		
		# Analog saturation
		var tom_tone = tanh((fundamental + harmonic2 + harmonic3) * 1.5) * 0.7
		
		# Subtle filtered noise for texture
		var noise = (randf() * 2.0 - 1.0) * 0.12
		noise = tanh(noise * 2.0) * 0.06
		
		var sample = (tom_tone + noise) * envelope * 1.1
		audio_data.append(soft_clip(sample, 0.9))
	
	return audio_data

# ============================================
# SFX SOUNDS (Sound Effects)
# ============================================

static func _cache_sfx_sounds():
	# Synthwave coin arpeggios - warmer, lower frequencies
	cached_sounds["coin_1"] = generate_coin_chime(523.25, 659.25, 783.99)  # C5, E5, G5
	cached_sounds["coin_2"] = generate_coin_chime(587.33, 659.25, 783.99)  # D5, E5, G5
	cached_sounds["coin_3"] = generate_coin_chime(523.25, 622.25, 783.99)  # C5, D#5, G5
	
	# Wall hit tom fill
	cached_sounds["wall_hit"] = generate_wall_hit_fill()
	
	# Game over sound
	cached_sounds["game_over"] = generate_game_over()

static func get_coin_chime() -> PackedFloat32Array:
	# Randomly select one of three coin variants
	var variant = randi() % 3 + 1
	return cached_sounds.get("coin_" + str(variant), PackedFloat32Array())

static func get_wall_hit() -> PackedFloat32Array:
	return cached_sounds.get("wall_hit", PackedFloat32Array())

static func get_game_over() -> PackedFloat32Array:
	return cached_sounds.get("game_over", PackedFloat32Array())

# Synthwave Coin - warm analog synth arpeggio
static func generate_coin_chime(freq1: float, freq2: float, freq3: float) -> PackedFloat32Array:
	var duration = 0.35  # Longer for laidback feel
	var samples = int(SAMPLE_RATE * duration)
	var audio_data = PackedFloat32Array()
	
	var frequencies = [freq1, freq2, freq3]
	
	for i in samples:
		var time = float(i) / SAMPLE_RATE
		var envelope = exp(-time * 6.0)  # Slower decay
		
		var chime_sample = 0.0
		for j in range(frequencies.size()):
			var freq = frequencies[j]
			
			# Analog-style detuned oscillators
			var detune = 1.0 + sin(2.0 * PI * 4.0 * time) * 0.003  # Subtle LFO
			var osc1 = sin(2.0 * PI * freq * detune * time)
			var osc2 = sin(2.0 * PI * freq * (detune * 1.007) * time)  # Slightly detuned
			
			# Analog filter simulation (simple lowpass)
			var cutoff_mod = 1.0 - time * 2.0  # Filter closes over time
			cutoff_mod = clamp(cutoff_mod, 0.3, 1.0)
			
			# Mix oscillators with analog warmth
			var mixed = (osc1 + osc2) * 0.5
			mixed = tanh(mixed * 1.2) * 0.8  # Soft saturation
			
			# Add subtle harmonic for warmth
			var harmonic = sin(2.0 * PI * freq * 0.5 * time) * 0.15 * envelope
			
			chime_sample += (mixed * cutoff_mod + harmonic) / 3.0
		
		var sample = chime_sample * envelope * 0.6
		audio_data.append(soft_clip(sample, 0.85))
	
	return audio_data

# Synthwave Wall Hit - deep analog tom fill with drive
static func generate_wall_hit_fill() -> PackedFloat32Array:
	var duration = 0.5  # Longer for more impact
	var samples = int(SAMPLE_RATE * duration)
	var audio_data = PackedFloat32Array()
	
	for i in samples:
		var time = float(i) / SAMPLE_RATE
		var envelope = exp(-time * 6.0)  # Slower decay for more resonance
		
		# Three tom hits with synthwave character
		var tom_sample = 0.0
		if time < 0.1:
			# High tom 1 - with pitch bend and analog warmth
			var bent_freq = 140.0 * exp(-time * 8.0)
			var fundamental = sin(2.0 * PI * bent_freq * time)
			var harmonic = sin(2.0 * PI * bent_freq * 0.5 * time) * 0.4
			tom_sample = tanh((fundamental + harmonic) * 1.8) * 0.7
		elif time < 0.2:
			# Mid tom - deeper and warmer
			var t = time - 0.1
			var bent_freq = 100.0 * exp(-t * 6.0)
			var fundamental = sin(2.0 * PI * bent_freq * t)
			var harmonic = sin(2.0 * PI * bent_freq * 0.5 * t) * 0.5
			tom_sample = tanh((fundamental + harmonic) * 2.0) * 0.8
		elif time < 0.4:
			# Low tom (THE big hit!)
			var t = time - 0.2
			var bent_freq = 55.0 * exp(-t * 4.0)  # Slower bend for more impact
			var fundamental = sin(2.0 * PI * bent_freq * t)
			var sub = sin(2.0 * PI * bent_freq * 0.5 * t) * 0.6  # Strong sub
			var harmonic = sin(2.0 * PI * bent_freq * 2.0 * t) * 0.3
			tom_sample = tanh((fundamental + sub + harmonic) * 2.5) * 1.3
		
		# Filtered noise for texture
		var noise = (randf() * 2.0 - 1.0) * 0.2
		noise = tanh(noise * 1.5) * 0.15 * envelope
		
		var sample = (tom_sample + noise) * envelope * 0.9
		audio_data.append(soft_clip(sample, 0.9))
	
	return audio_data

# Synthwave Game Over - melancholic analog pad sequence
static func generate_game_over() -> PackedFloat32Array:
	var duration = 1.2  # Longer for dramatic effect
	var samples = int(SAMPLE_RATE * duration)
	var audio_data = PackedFloat32Array()
	
	# Melancholic synthwave progression
	var notes = [
		{"freq": 329.63, "start": 0.0, "dur": 0.3},    # E4 (minor feel)
		{"freq": 293.66, "start": 0.3, "dur": 0.3},   # D4
		{"freq": 261.63, "start": 0.6, "dur": 0.3},   # C4
		{"freq": 220.00, "start": 0.9, "dur": 0.3}    # A3 (final resolution)
	]
	
	for i in samples:
		var time = float(i) / SAMPLE_RATE
		var sample = 0.0
		
		for note in notes:
			if time >= note.start and time < note.start + note.dur:
				var note_time = time - note.start
				
				# Analog-style ADSR envelope
				var note_env = 1.0
				var attack = 0.05
				var decay = 0.1
				var sustain = 0.6
				var release = 0.15
				
				if note_time < attack:
					note_env = note_time / attack
				elif note_time < attack + decay:
					var t = (note_time - attack) / decay
					note_env = 1.0 - (1.0 - sustain) * t
				elif note_time < note.dur - release:
					note_env = sustain
				else:
					var t = (note_time - (note.dur - release)) / release
					note_env = sustain * (1.0 - t)
				
				# Warm analog oscillators with detuning
				var osc1 = sin(2.0 * PI * note.freq * time)
				var osc2 = sin(2.0 * PI * note.freq * 1.003 * time)  # Slight detune
				var sub_osc = sin(2.0 * PI * note.freq * 0.5 * time) * 0.3
				
				# Filter simulation - closes over time for sadness
				var filter_env = 1.0 - (time - note.start) / note.dur * 0.7
				filter_env = clamp(filter_env, 0.2, 1.0)
				
				var mixed = (osc1 + osc2) * 0.5 + sub_osc
				mixed = tanh(mixed * 1.3) * 0.7 * filter_env
				
				sample += mixed * note_env * 0.6
		
		audio_data.append(soft_clip(sample, 0.8))
	
	return audio_data

# ============================================
# MELODIC SOUNDS (Musical notes)
# ============================================

static func _cache_melodic_sounds():
	# Synthwave combo progression (A minor pentatonic for moodier vibe)
	var scale_frequencies = {
		1: 220.00,  # A3
		2: 261.63,  # C4  
		3: 293.66,  # D4
		4: 329.63,  # E4
		5: 392.00,  # G4
		6: 440.00,  # A4
		7: 523.25,  # C5
		8: 587.33   # D5
	}
	
	# Warm synthwave combo notes 1-7
	for i in range(1, 8):
		cached_sounds["combo_" + str(i)] = generate_simple_note(scale_frequencies[i], 0.4)  # Longer duration
	
	# Special celebration for combo 8
	cached_sounds["combo_8_special"] = generate_octave_celebration()
	
	# Multiplier increase notes - deeper and warmer
	cached_sounds["multiplier_2"] = generate_simple_note(329.63, 0.4)   # E4
	cached_sounds["multiplier_3"] = generate_simple_note(440.00, 0.4)   # A4  
	cached_sounds["multiplier_4"] = generate_simple_note(523.25, 0.4)   # C5
	cached_sounds["multiplier_5"] = generate_simple_note(659.25, 0.4)   # E5

static func get_combo_sound(combo: int) -> PackedFloat32Array:
	if combo == 8:
		return cached_sounds.get("combo_8_special", PackedFloat32Array())
	else:
		return cached_sounds.get("combo_" + str(clamp(combo, 1, 7)), PackedFloat32Array())

static func get_multiplier_sound(multiplier: int) -> PackedFloat32Array:
	return cached_sounds.get("multiplier_" + str(clamp(multiplier, 2, 5)), PackedFloat32Array())

# Synthwave Lead - warm analog synth with detuning and filter
static func generate_simple_note(frequency: float, duration: float) -> PackedFloat32Array:
	var samples = int(SAMPLE_RATE * duration)
	var audio_data = PackedFloat32Array()
	
	for i in samples:
		var time = float(i) / SAMPLE_RATE
		
		# Synthwave ADSR envelope - longer attack for smoothness
		var envelope = 1.0
		var attack = 0.03  # Slower attack for laidback feel
		var decay = 0.08
		var sustain = 0.7
		var release = 0.15  # Longer release for warmth
		
		if time < attack:
			envelope = time / attack
		elif time < attack + decay:
			var t = (time - attack) / decay
			envelope = 1.0 - (1.0 - sustain) * t
		elif time < duration - release:
			envelope = sustain
		else:
			var t = (time - (duration - release)) / release
			envelope = sustain * (1.0 - t)
		
		# Analog-style oscillators with subtle detuning
		var osc1 = sin(2.0 * PI * frequency * time)
		var osc2 = sin(2.0 * PI * frequency * 1.005 * time)  # Slight detune
		
		# Add subtle vibrato
		var vibrato = 1.0 + sin(2.0 * PI * 5.5 * time) * 0.008
		var main_osc = (osc1 + osc2) * 0.5 * vibrato
		
		# Analog filter simulation - opens up over time
		var filter_env = 0.6 + envelope * 0.4
		main_osc = tanh(main_osc * 1.4) * filter_env
		
		# Add subtle harmonic for warmth
		var harmonic = sin(2.0 * PI * frequency * 2.0 * time) * 0.15 * envelope
		
		var sample = (main_osc + harmonic) * envelope * 0.65
		audio_data.append(soft_clip(sample, 0.85))
	
	return audio_data

# Synthwave Octave Celebration - lush analog pad chord
static func generate_octave_celebration() -> PackedFloat32Array:
	var duration = 0.9  # Longer for dramatic effect
	var samples = int(SAMPLE_RATE * duration)
	var audio_data = PackedFloat32Array()
	
	# Rich synthwave chord (C major with extensions)
	var chord_freqs = [
		261.63,  # C4
		329.63,  # E4  
		392.00,  # G4
		523.25,  # C5 (octave)
		659.25   # E5 (for richness)
	]
	
	for i in samples:
		var time = float(i) / SAMPLE_RATE
		
		# Synthwave envelope - slow attack, long sustain
		var envelope = 1.0
		var attack = 0.1
		var decay = 0.2
		var sustain = 0.8
		var release = 0.6
		
		if time < attack:
			envelope = time / attack
		elif time < attack + decay:
			var t = (time - attack) / decay
			envelope = 1.0 - (1.0 - sustain) * t
		elif time < duration - release:
			envelope = sustain
		else:
			var t = (time - (duration - release)) / release
			envelope = sustain * (1.0 - t)
		
		var sample = 0.0
		for j in range(chord_freqs.size()):
			var freq = chord_freqs[j]
			
			# Each voice gets analog treatment
			var osc1 = sin(2.0 * PI * freq * time)
			var osc2 = sin(2.0 * PI * freq * 1.003 * time)  # Slight detune
			
			# Different vibrato rates for chorus effect
			var vibrato_rate = 4.5 + j * 0.3
			var vibrato = 1.0 + sin(2.0 * PI * vibrato_rate * time) * 0.006
			
			var voice = (osc1 + osc2) * 0.5 * vibrato
			
			# Analog saturation
			voice = tanh(voice * 1.2) * 0.8
			
			# Volume based on position in chord
			var amp = 0.25
			if j == 3:  # Octave
				amp = 0.4
			elif j == 4:  # Top note
				amp = 0.2
			
			sample += voice * amp
		
		sample = sample * envelope * 0.6
		audio_data.append(soft_clip(sample, 0.85))
	
	return audio_data

# ============================================
# AMBIENT SOUNDS (Background atmosphere)
# ============================================

static func _cache_ambient_sounds():
	# Pre-generate guitar loop - 2 seconds should be enough for seamless looping
	cached_sounds["guitar_loop"] = generate_ambient_guitar_loop(2.0)

static func get_guitar_loop() -> PackedFloat32Array:
	return cached_sounds.get("guitar_loop", PackedFloat32Array())

# Synthwave Ambient Pad - warm analog pad for movement atmosphere
static func generate_ambient_guitar_loop(duration: float) -> PackedFloat32Array:
	var samples = int(SAMPLE_RATE * duration)
	var audio_data = PackedFloat32Array()
	
	# Warm synthwave pad chord (Am7 for moodier feel)
	var chord_frequencies = [220.00, 261.63, 329.63, 392.00]  # A3, C4, E4, G4
	
	for i in samples:
		var time = float(i) / SAMPLE_RATE
		var sample = 0.0
		
		for j in range(chord_frequencies.size()):
			var freq = chord_frequencies[j]
			
			# Multiple analog-style oscillators per voice
			var osc1 = sin(2.0 * PI * freq * time)
			var osc2 = sin(2.0 * PI * freq * 1.004 * time)  # Detune
			var sub_osc = sin(2.0 * PI * freq * 0.5 * time) * 0.4
			
			# Individual vibrato for each voice
			var vibrato_rate = 4.8 + j * 0.2
			var vibrato = 1.0 + sin(2.0 * PI * vibrato_rate * time) * 0.008
			
			var voice = (osc1 + osc2) * 0.5 + sub_osc
			voice *= vibrato
			
			# Analog filter simulation - subtle movement
			var filter_lfo = sin(2.0 * PI * 0.3 * time + j) * 0.15 + 0.85
			voice = tanh(voice * 1.1) * filter_lfo * 0.25
			
			sample += voice
		
		# Overall analog saturation and gentle limiting
		sample = tanh(sample * 0.8) * 0.35  # Ambient volume for movement
		audio_data.append(soft_clip(sample, 0.7))
	
	return audio_data

# Ambient guitar chord - for continuous playback (DEPRECATED - use cached version)
static func generate_ambient_guitar_chunk(time_position: float, chunk_size: int) -> PackedFloat32Array:
	var audio_data = PackedFloat32Array()
	
	# Cmaj7 chord for peaceful ambience
	var chord_frequencies = [261.63, 329.63, 392.00, 493.88]  # C4, E4, G4, B4
	
	for i in chunk_size:
		var time = time_position + float(i) / SAMPLE_RATE
		var sample = 0.0
		
		for freq in chord_frequencies:
			# Slight vibrato for warmth
			var vibrato = 1.0 + sin(2.0 * PI * 5.0 * time) * 0.005
			sample += sin(2.0 * PI * freq * vibrato * time) * 0.25
		
		sample *= 0.3  # Ambient volume
		audio_data.append(sample)
	
	return audio_data

# ============================================
# ADVANCED SOUNDS (For future synthesizer)
# ============================================

# Your friend can add new sound categories here!
# Examples:
# - generate_synth_lead()
# - generate_bass_line()
# - generate_pad_sound()
# - generate_arpeggio()
# etc.

# ============================================
# UTILITY FUNCTIONS
# ============================================

# Soft clipping to prevent distortion
static func soft_clip(value: float, threshold: float = 0.8) -> float:
	if abs(value) <= threshold:
		return value
	else:
		var sign_val = sign(value)
		var excess = abs(value) - threshold
		return sign_val * (threshold + tanh(excess * 2.0) * (1.0 - threshold))

# Apply soft clipping to an entire audio buffer
static func apply_soft_limiting(audio_data: PackedFloat32Array, threshold: float = 0.8) -> PackedFloat32Array:
	var limited_data = PackedFloat32Array()
	for sample in audio_data:
		limited_data.append(soft_clip(sample, threshold))
	return limited_data