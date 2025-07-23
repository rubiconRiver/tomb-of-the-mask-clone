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

# Kick drum - deep bass thump
static func generate_kick() -> PackedFloat32Array:
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
static func generate_snare() -> PackedFloat32Array:
	var duration = 0.1
	var samples = int(SAMPLE_RATE * duration)
	var audio_data = PackedFloat32Array()
	
	for i in samples:
		var time = float(i) / SAMPLE_RATE
		var envelope = exp(-time * 25.0)
		
		# Snare noise
		var noise = (randf() * 2.0 - 1.0) * 0.7
		
		# Tonal component at 200Hz
		var tone = sin(2.0 * PI * 200.0 * time) * 0.3
		
		var sample = (noise + tone) * envelope
		audio_data.append(sample)
	
	return audio_data

# Hi-hat closed - short metallic burst
static func generate_hihat() -> PackedFloat32Array:
	var duration = 0.05
	var samples = int(SAMPLE_RATE * duration)
	var audio_data = PackedFloat32Array()
	
	for i in samples:
		var time = float(i) / SAMPLE_RATE
		var envelope = exp(-time * 40.0)
		
		# High frequency noise
		var noise = (randf() * 2.0 - 1.0) * 0.8
		
		# Metallic overtones
		var metallic1 = sin(2.0 * PI * 8000.0 * time) * 0.3
		var metallic2 = sin(2.0 * PI * 12000.0 * time) * 0.2
		
		var sample = (noise + metallic1 + metallic2) * envelope
		audio_data.append(sample)
	
	return audio_data

# Hi-hat open - longer decay
static func generate_hihat_open() -> PackedFloat32Array:
	var duration = 0.15
	var samples = int(SAMPLE_RATE * duration)
	var audio_data = PackedFloat32Array()
	
	for i in samples:
		var time = float(i) / SAMPLE_RATE
		var envelope = exp(-time * 10.0)  # Slower decay
		
		var noise = (randf() * 2.0 - 1.0) * 0.7
		var metallic1 = sin(2.0 * PI * 7000.0 * time) * 0.4
		var metallic2 = sin(2.0 * PI * 10000.0 * time) * 0.3
		
		var sample = (noise + metallic1 + metallic2) * envelope
		audio_data.append(sample)
	
	return audio_data

# Tom drums for fills
static func generate_tom_high() -> PackedFloat32Array:
	return _generate_tom(180.0, 0.08)

static func generate_tom_mid() -> PackedFloat32Array:
	return _generate_tom(140.0, 0.10)

static func generate_tom_low() -> PackedFloat32Array:
	return _generate_tom(80.0, 0.16)

static func _generate_tom(frequency: float, duration: float) -> PackedFloat32Array:
	var samples = int(SAMPLE_RATE * duration)
	var audio_data = PackedFloat32Array()
	
	for i in samples:
		var time = float(i) / SAMPLE_RATE
		var envelope = exp(-time * 15.0)
		
		# Tom tone with pitch bend
		var bent_freq = frequency * exp(-time * 10.0)
		var tone = sin(2.0 * PI * bent_freq * time)
		
		# Add some noise for realism
		var noise = (randf() * 2.0 - 1.0) * 0.15
		
		var sample = (tone * 0.85 + noise) * envelope
		audio_data.append(sample)
	
	return audio_data

# ============================================
# SFX SOUNDS (Sound Effects)
# ============================================

static func _cache_sfx_sounds():
	# Coin sounds
	cached_sounds["coin_1"] = generate_coin_chime(1046.5, 1318.5, 1568.0)  # C6, E6, G6
	cached_sounds["coin_2"] = generate_coin_chime(1174.7, 1318.5, 1568.0)  # D6, E6, G6
	cached_sounds["coin_3"] = generate_coin_chime(1046.5, 1244.5, 1568.0)  # C6, D#6, G6
	
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

# Coin collection - beautiful chime
static func generate_coin_chime(freq1: float, freq2: float, freq3: float) -> PackedFloat32Array:
	var duration = 0.2
	var samples = int(SAMPLE_RATE * duration)
	var audio_data = PackedFloat32Array()
	
	var frequencies = [freq1, freq2, freq3]
	
	for i in samples:
		var time = float(i) / SAMPLE_RATE
		var envelope = exp(-time * 12.0)
		
		var chime_sample = 0.0
		for freq in frequencies:
			# Fundamental + harmonics for bell-like quality
			var fundamental = sin(2.0 * PI * freq * time) * 0.6
			var harmonic2 = sin(2.0 * PI * freq * 2.0 * time) * 0.2
			var harmonic3 = sin(2.0 * PI * freq * 3.0 * time) * 0.1
			chime_sample += (fundamental + harmonic2 + harmonic3) / 3.0
		
		var sample = chime_sample * envelope * 0.35
		audio_data.append(sample)
	
	return audio_data

# Wall hit - tom fill sequence
static func generate_wall_hit_fill() -> PackedFloat32Array:
	var duration = 0.4
	var samples = int(SAMPLE_RATE * duration)
	var audio_data = PackedFloat32Array()
	
	for i in samples:
		var time = float(i) / SAMPLE_RATE
		var envelope = exp(-time * 10.0)
		
		# Three tom hits: du-du-DUH pattern
		var tom_sample = 0.0
		if time < 0.08:
			# High tom 1
			tom_sample = sin(2.0 * PI * 180.0 * time) * exp(-time * 30.0) * 0.8
		elif time < 0.16:
			# High tom 2
			var t = time - 0.08
			tom_sample = sin(2.0 * PI * 160.0 * t) * exp(-t * 30.0) * 0.8
		elif time < 0.32:
			# Low tom (DUH!)
			var t = time - 0.16
			tom_sample = sin(2.0 * PI * 80.0 * t) * exp(-t * 20.0) * 1.2
		
		# Add noise texture
		var noise = (randf() * 2.0 - 1.0) * 0.25 * envelope
		var sample = (tom_sample + noise) * envelope * 0.75
		audio_data.append(sample)
	
	return audio_data

# Game over - descending notes
static func generate_game_over() -> PackedFloat32Array:
	var duration = 0.8
	var samples = int(SAMPLE_RATE * duration)
	var audio_data = PackedFloat32Array()
	
	# Sad descending notes
	var notes = [
		{"freq": 392.0, "start": 0.0, "dur": 0.2},    # G4
		{"freq": 349.23, "start": 0.2, "dur": 0.2},   # F4
		{"freq": 329.63, "start": 0.4, "dur": 0.2},   # E4
		{"freq": 261.63, "start": 0.6, "dur": 0.2}    # C4
	]
	
	for i in samples:
		var time = float(i) / SAMPLE_RATE
		var sample = 0.0
		
		for note in notes:
			if time >= note.start and time < note.start + note.dur:
				var note_time = time - note.start
				var note_env = sin(PI * note_time / note.dur)  # Smooth envelope
				sample += sin(2.0 * PI * note.freq * time) * note_env * 0.5
		
		audio_data.append(sample)
	
	return audio_data

# ============================================
# MELODIC SOUNDS (Musical notes)
# ============================================

static func _cache_melodic_sounds():
	# Combo progression notes (C major scale)
	var scale_frequencies = {
		1: 261.63,  # C4
		2: 293.66,  # D4
		3: 329.63,  # E4
		4: 349.23,  # F4
		5: 392.00,  # G4
		6: 440.00,  # A4
		7: 493.88,  # B4
		8: 523.25   # C5
	}
	
	# Simple notes for combos 1-7
	for i in range(1, 8):
		cached_sounds["combo_" + str(i)] = generate_simple_note(scale_frequencies[i], 0.3)
	
	# Special octave sound for combo 8
	cached_sounds["combo_8_special"] = generate_octave_celebration()
	
	# Multiplier increase notes
	cached_sounds["multiplier_2"] = generate_simple_note(392.00, 0.3)   # G4
	cached_sounds["multiplier_3"] = generate_simple_note(523.25, 0.3)   # C5
	cached_sounds["multiplier_4"] = generate_simple_note(659.25, 0.3)   # E5
	cached_sounds["multiplier_5"] = generate_simple_note(783.99, 0.3)   # G5

static func get_combo_sound(combo: int) -> PackedFloat32Array:
	if combo == 8:
		return cached_sounds.get("combo_8_special", PackedFloat32Array())
	else:
		return cached_sounds.get("combo_" + str(clamp(combo, 1, 7)), PackedFloat32Array())

static func get_multiplier_sound(multiplier: int) -> PackedFloat32Array:
	return cached_sounds.get("multiplier_" + str(clamp(multiplier, 2, 5)), PackedFloat32Array())

# Simple melodic note with envelope
static func generate_simple_note(frequency: float, duration: float) -> PackedFloat32Array:
	var samples = int(SAMPLE_RATE * duration)
	var audio_data = PackedFloat32Array()
	
	for i in samples:
		var time = float(i) / SAMPLE_RATE
		
		# ADSR envelope
		var envelope = 1.0
		var attack = 0.01
		var decay = 0.05
		var sustain = 0.8
		var release = 0.1
		
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
		
		var sample = sin(2.0 * PI * frequency * time) * envelope * 0.5
		audio_data.append(sample)
	
	return audio_data

# Special celebration sound for combo 8 (octave)
static func generate_octave_celebration() -> PackedFloat32Array:
	var duration = 0.6
	var samples = int(SAMPLE_RATE * duration)
	var audio_data = PackedFloat32Array()
	
	# Full C major chord
	var chord_freqs = [
		261.63,  # C4
		329.63,  # E4
		392.00,  # G4
		523.25   # C5 (octave)
	]
	
	for i in samples:
		var time = float(i) / SAMPLE_RATE
		var envelope = 1.0 - (time / duration)  # Linear fade
		envelope *= envelope  # Make it quadratic for smoother fade
		
		var sample = 0.0
		for j in range(chord_freqs.size()):
			var freq = chord_freqs[j]
			var amp = 0.7 if j == 3 else 0.3  # Octave louder
			
			# Add slight vibrato to octave
			if j == 3:
				freq *= 1.0 + sin(2.0 * PI * 5.0 * time) * 0.005
			
			sample += sin(2.0 * PI * freq * time) * amp
		
		sample = sample * envelope * 0.4
		audio_data.append(sample)
	
	return audio_data

# ============================================
# AMBIENT SOUNDS (Background atmosphere)
# ============================================

# Ambient guitar chord - for continuous playback
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