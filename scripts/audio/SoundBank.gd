class_name SoundBank
extends RefCounted

# ============================================
# CENTRAL SOUND BANK - FILE-BASED AUDIO
# ============================================
# This file loads all game sounds from WAV files.
# Supports theme switching for different sound packs.
# Maintains compatibility with the existing audio system.

const SAMPLE_RATE = 44100

# Cache for loaded sounds
static var cached_sounds = {}
static var _initialized = false
static var current_theme = "default"

# Note mappings for melodic sounds
static var note_names = {
	1: "c4",
	2: "d4",
	3: "e4",
	4: "f4",
	5: "g4",
	6: "a4",
	7: "b4",
	8: "c5_special"
}

static var multiplier_notes = {
	2: "g4",
	3: "c5",
	4: "e5",
	5: "g5"
}

static func initialize():
	if _initialized:
		return
	
	print("[SoundBank] Loading audio files for theme: ", current_theme)
	
	# Load all sounds for current theme
	_load_drum_sounds()
	_load_sfx_sounds()
	_load_melodic_sounds()
	_load_ambient_sounds()
	
	_initialized = true
	print("[SoundBank] Loaded ", cached_sounds.size(), " sounds")

# ============================================
# THEME MANAGEMENT
# ============================================

static func set_theme(theme_name: String):
	print("[SoundBank] Switching theme to: ", theme_name)
	current_theme = theme_name
	cached_sounds.clear()
	_initialized = false
	initialize()

static func get_available_themes() -> Array:
	# Could scan the audio directory for available themes
	# For now, just return known themes
	return ["default"]

# ============================================
# AUDIO FILE LOADING
# ============================================

static func _load_wav_file(path: String) -> AudioStream:
	var full_path = "res://assets/audio/" + current_theme + "/" + path
	
	# Load the audio file
	var audio_stream = load(full_path)
	if not audio_stream:
		push_error("[SoundBank] Failed to load audio file: " + full_path)
		return null
	
	return audio_stream

# Removed - no longer needed since we're using AudioStream directly

# ============================================
# DRUM SOUNDS
# ============================================

static func _load_drum_sounds():
	cached_sounds["kick"] = _load_wav_file("drums/kick_" + current_theme + ".wav")
	cached_sounds["snare"] = _load_wav_file("drums/snare_" + current_theme + ".wav")
	cached_sounds["hihat"] = _load_wav_file("drums/hihat_" + current_theme + ".wav")
	cached_sounds["hihat_open"] = _load_wav_file("drums/hihat_open_" + current_theme + ".wav")
	cached_sounds["tom_high"] = _load_wav_file("drums/tom_high_" + current_theme + ".wav")
	cached_sounds["tom_mid"] = _load_wav_file("drums/tom_mid_" + current_theme + ".wav")
	cached_sounds["tom_low"] = _load_wav_file("drums/tom_low_" + current_theme + ".wav")

static func get_kick() -> AudioStream:
	return cached_sounds.get("kick", null)

static func get_snare() -> AudioStream:
	return cached_sounds.get("snare", null)

static func get_hihat() -> AudioStream:
	return cached_sounds.get("hihat", null)

# Tom drum getters
static func generate_tom_high() -> AudioStream:
	return cached_sounds.get("tom_high", null)

static func generate_tom_mid() -> AudioStream:
	return cached_sounds.get("tom_mid", null)

static func generate_tom_low() -> AudioStream:
	return cached_sounds.get("tom_low", null)

# ============================================
# SFX SOUNDS
# ============================================

static func _load_sfx_sounds():
	# Load coin variations
	for i in range(1, 4):
		var key = "coin_" + str(i)
		cached_sounds[key] = _load_wav_file("sfx/coin_" + current_theme + "_" + str(i) + ".wav")
	
	cached_sounds["wall_hit"] = _load_wav_file("sfx/wall_hit_" + current_theme + ".wav")
	cached_sounds["game_over"] = _load_wav_file("sfx/game_over_" + current_theme + ".wav")

static func get_coin_chime() -> AudioStream:
	# Randomly select one of three coin variants
	var variant = randi() % 3 + 1
	return cached_sounds.get("coin_" + str(variant), null)

static func get_wall_hit() -> AudioStream:
	return cached_sounds.get("wall_hit", null)

static func get_game_over() -> AudioStream:
	return cached_sounds.get("game_over", null)

# ============================================
# MELODIC SOUNDS
# ============================================

static func _load_melodic_sounds():
	# Load combo sounds with note names
	for combo_num in range(1, 9):
		var note_name = note_names[combo_num]
		var key = "combo_" + str(combo_num)
		cached_sounds[key] = _load_wav_file("melodic/combo_" + current_theme + "_" + note_name + ".wav")
	
	# Load multiplier sounds
	for mult in multiplier_notes:
		var note_name = multiplier_notes[mult]
		var key = "multiplier_" + str(mult)
		cached_sounds[key] = _load_wav_file("melodic/multiplier_" + current_theme + "_" + note_name + ".wav")

static func get_combo_sound(combo: int) -> AudioStream:
	var key = "combo_" + str(clamp(combo, 1, 8))
	return cached_sounds.get(key, null)

static func get_multiplier_sound(multiplier: int) -> AudioStream:
	var key = "multiplier_" + str(clamp(multiplier, 2, 5))
	return cached_sounds.get(key, null)

# ============================================
# AMBIENT SOUNDS
# ============================================

static func _load_ambient_sounds():
	cached_sounds["ambient_guitar"] = _load_wav_file("ambient/guitar_chord_" + current_theme + ".wav")

static func get_guitar_loop() -> AudioStream:
	return cached_sounds.get("ambient_guitar", null)

# For ambient system compatibility - returns the ambient guitar stream
static func generate_ambient_guitar_chunk(time_position: float, chunk_size: int) -> AudioStream:
	# Just return the loaded ambient guitar stream
	return cached_sounds.get("ambient_guitar", null)

# ============================================
# UTILITY FUNCTIONS (for compatibility)
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

# ============================================
# COMPATIBILITY FUNCTIONS
# ============================================
# These functions exist for compatibility with code that expects sound generation

static func generate_kick() -> AudioStream:
	return get_kick()

static func generate_snare() -> AudioStream:
	return get_snare()

static func generate_hihat() -> AudioStream:
	return get_hihat()

static func generate_hihat_open() -> AudioStream:
	return cached_sounds.get("hihat_open", null)

static func generate_coin_chime(freq1: float, freq2: float, freq3: float) -> AudioStream:
	return get_coin_chime()

static func generate_wall_hit_fill() -> AudioStream:
	return get_wall_hit()

static func generate_game_over() -> AudioStream:
	return get_game_over()

static func generate_simple_note(frequency: float, duration: float) -> AudioStream:
	# For compatibility - return appropriate combo sound based on frequency
	# This is a rough mapping based on the original frequencies
	if frequency < 240: return get_combo_sound(1)  # A3 (220Hz)
	elif frequency < 280: return get_combo_sound(2)  # C4 (261Hz)
	elif frequency < 310: return get_combo_sound(3)  # D4 (293Hz)
	elif frequency < 350: return get_combo_sound(4)  # E4 (329Hz)
	elif frequency < 420: return get_combo_sound(5)  # G4 (392Hz)
	elif frequency < 480: return get_combo_sound(6)  # A4 (440Hz)
	elif frequency < 550: return get_combo_sound(7)  # C5 (523Hz)
	else: return get_combo_sound(8)  # D5 (587Hz)

static func generate_octave_celebration() -> AudioStream:
	return get_combo_sound(8)

static func generate_ambient_guitar_loop(duration: float) -> AudioStream:
	return get_guitar_loop()

# Cache initialization functions for compatibility
static func _cache_drum_sounds():
	_load_drum_sounds()

static func _cache_sfx_sounds():
	_load_sfx_sounds()

static func _cache_melodic_sounds():
	_load_melodic_sounds()

static func _cache_ambient_sounds():
	_load_ambient_sounds()