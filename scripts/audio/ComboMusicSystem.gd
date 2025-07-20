extends Node
class_name ComboMusicSystem

# C Major scale frequencies for 8-note progression
const SCALE_FREQUENCIES = {
	1: 261.63,  # C4
	2: 293.66,  # D4
	3: 329.63,  # E4
	4: 349.23,  # F4
	5: 392.00,  # G4
	6: 440.00,  # A4
	7: 493.88,  # B4
	8: 523.25   # C5 (octave)
}

# Audio settings
const SAMPLE_RATE = 44100  # Needed for compatibility
const BASE_VOLUME = -10.0
const QUIET_VOLUME = -16.0

var audio_players = {}  # Multiple players for layered sounds
var current_combo = 0

func _ready():
	print("[ComboMusic] Initializing combo music system")
	
	# Create multiple audio players for layering
	for i in range(4):  # Support up to 4 simultaneous sounds
		var player = AudioStreamPlayer.new()
		player.bus = "Master"
		add_child(player)
		audio_players[i] = player
	
	print("[ComboMusic] Ready with ", audio_players.size(), " audio players")

func play_combo_sound(combo: int, multiplier_increased: bool):
	if combo < 1 or combo > 8:
		return
		
	print("[ComboMusic] Playing combo ", combo, " sound (multiplier increased: ", multiplier_increased, ")")
	current_combo = combo
	
	# Call the appropriate combo function
	match combo:
		1: play_combo_1(multiplier_increased)
		2: play_combo_2(multiplier_increased)
		3: play_combo_3(multiplier_increased)
		4: play_combo_4(multiplier_increased)
		5: play_combo_5(multiplier_increased)
		6: play_combo_6(multiplier_increased)
		7: play_combo_7(multiplier_increased)
		8: play_combo_8(multiplier_increased)

# Combo 1: Simple C4
func play_combo_1(multiplier_increased: bool):
	var frequency = SCALE_FREQUENCIES[1]
	var duration = 0.3
	var volume = BASE_VOLUME if multiplier_increased else QUIET_VOLUME
	
	var audio_data = AudioGenerator.generate_sine_wave(frequency, duration, 0.5)
	play_audio_on_player(0, audio_data, volume)

# Combo 2: D4 with slight vibrato
func play_combo_2(multiplier_increased: bool):
	var frequency = SCALE_FREQUENCIES[2]
	var duration = 0.3
	var volume = BASE_VOLUME if multiplier_increased else QUIET_VOLUME
	
	var audio_data = AudioGenerator.generate_sine_with_vibrato(frequency, duration, 0.5, 2.0, 0.01)
	play_audio_on_player(0, audio_data, volume)

# Combo 3: E4 with bass harmony (C3)
func play_combo_3(multiplier_increased: bool):
	var main_freq = SCALE_FREQUENCIES[3]
	var bass_freq = SCALE_FREQUENCIES[1] / 2  # C3
	var duration = 0.35
	var volume = BASE_VOLUME if multiplier_increased else QUIET_VOLUME
	
	# Main note
	var main_audio = AudioGenerator.generate_sine_wave(main_freq, duration, 0.5)
	play_audio_on_player(0, main_audio, volume)
	
	# Bass harmony
	var bass_audio = AudioGenerator.generate_sine_wave(bass_freq, duration, 0.3)
	play_audio_on_player(1, bass_audio, volume - 3)

# Combo 4: F4 with perfect fifth harmony
func play_combo_4(multiplier_increased: bool):
	var main_freq = SCALE_FREQUENCIES[4]
	var fifth_freq = main_freq * 1.5  # Perfect fifth
	var duration = 0.35
	var volume = BASE_VOLUME if multiplier_increased else QUIET_VOLUME
	
	# Main note
	var main_audio = AudioGenerator.generate_sine_wave(main_freq, duration, 0.5)
	play_audio_on_player(0, main_audio, volume)
	
	# Fifth harmony
	var fifth_audio = AudioGenerator.generate_sine_wave(fifth_freq, duration, 0.3)
	play_audio_on_player(1, fifth_audio, volume - 4)

# Combo 5: G4 with major triad (C-E-G)
func play_combo_5(multiplier_increased: bool):
	var root_freq = SCALE_FREQUENCIES[1]  # C4
	var third_freq = SCALE_FREQUENCIES[3]  # E4
	var fifth_freq = SCALE_FREQUENCIES[5]  # G4
	var duration = 0.4
	var volume = BASE_VOLUME if multiplier_increased else QUIET_VOLUME
	
	# Play triad
	var root_audio = AudioGenerator.generate_sine_wave(root_freq, duration, 0.3)
	var third_audio = AudioGenerator.generate_sine_wave(third_freq, duration, 0.3)
	var fifth_audio = AudioGenerator.generate_sine_wave(fifth_freq, duration, 0.5)
	
	play_audio_on_player(0, fifth_audio, volume)  # Main note louder
	play_audio_on_player(1, root_audio, volume - 4)
	play_audio_on_player(2, third_audio, volume - 4)

# Combo 6: A4 with ascending arpeggio
func play_combo_6(multiplier_increased: bool):
	var main_freq = SCALE_FREQUENCIES[6]
	var duration = 0.45
	var volume = BASE_VOLUME if multiplier_increased else QUIET_VOLUME
	
	# Main note with arpeggio effect
	var audio_data = AudioGenerator.generate_arpeggio_effect(
		[SCALE_FREQUENCIES[1], SCALE_FREQUENCIES[3], SCALE_FREQUENCIES[5], main_freq],
		duration,
		0.1  # Quick arpeggio
	)
	play_audio_on_player(0, audio_data, volume)

# Combo 7: B4 with tension building
func play_combo_7(multiplier_increased: bool):
	var main_freq = SCALE_FREQUENCIES[7]
	var duration = 0.45
	var volume = BASE_VOLUME if multiplier_increased else QUIET_VOLUME
	
	# Leading tone with slight tremolo for tension
	var audio_data = AudioGenerator.generate_sine_with_tremolo(main_freq, duration, 0.6, 6.0, 0.2)
	play_audio_on_player(0, audio_data, volume)
	
	# Add suspended 4th for more tension
	var sus4_freq = SCALE_FREQUENCIES[1] * 4/3  # F4
	var sus_audio = AudioGenerator.generate_sine_wave(sus4_freq, duration * 0.7, 0.3)
	play_audio_on_player(1, sus_audio, volume - 5)

# Combo 8: C5 OCTAVE - Special celebration!
func play_combo_8(multiplier_increased: bool):
	var octave_freq = SCALE_FREQUENCIES[8]
	var duration = 0.6  # Longer for emphasis
	var volume = BASE_VOLUME + 2  # Slightly louder
	
	# Full C major chord with octave
	var c4 = SCALE_FREQUENCIES[1]
	var e4 = SCALE_FREQUENCIES[3]
	var g4 = SCALE_FREQUENCIES[5]
	var c5 = octave_freq
	
	# Generate rich octave sound with slight chorus effect
	var octave_audio = AudioGenerator.generate_sine_with_chorus(c5, duration, 0.7, 3)
	var root_audio = AudioGenerator.generate_sine_wave(c4, duration, 0.4)
	var third_audio = AudioGenerator.generate_sine_wave(e4, duration, 0.3)
	var fifth_audio = AudioGenerator.generate_sine_wave(g4, duration, 0.3)
	
	# Play all notes for triumphant sound
	play_audio_on_player(0, octave_audio, volume)
	play_audio_on_player(1, root_audio, volume - 3)
	play_audio_on_player(2, third_audio, volume - 4)
	play_audio_on_player(3, fifth_audio, volume - 4)
	
	print("[ComboMusic] OCTAVE ACHIEVED! Playing celebration chord")

# All audio generation now handled by AudioGenerator class

func play_audio_on_player(player_index: int, audio_data: PackedFloat32Array, volume: float):
	if player_index >= audio_players.size():
		return
		
	var player = audio_players[player_index]
	AudioGenerator.play_samples_on_player(player, audio_data, volume)

func reset():
	print("[ComboMusic] Resetting music system")
	current_combo = 0
	for player in audio_players.values():
		if player.playing:
			player.stop()
