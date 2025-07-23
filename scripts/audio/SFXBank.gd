class_name SFXBank
extends Node

# Sound effects playback manager
# Handles coins, wall hits, game over, etc.

var mixer: AudioMixer

func _ready():
	# Wait a frame for all nodes to be ready
	await get_tree().process_frame
	# Get mixer from parent AudioManager
	var audio_manager = get_parent()
	if audio_manager and "mixer" in audio_manager:
		mixer = audio_manager.mixer
	if not mixer:
		push_error("[SFXBank] Could not find AudioMixer")

func play_coin_chime():
	var coin_sound = SoundBank.get_coin_chime()
	if coin_sound:
		mixer.play_sound(coin_sound, "SFX", 0.0)

func play_wall_hit():
	# Create randomized tom fill instead of single wall hit sound
	play_random_tom_fill()

func play_random_tom_fill():
	# Create a dynamic randomized tom fill with variable hit counts and timings
	var tom_volume = 3.0  # Increased volume for toms
	
	# Get all tom sounds
	var tom_high = SoundBank.generate_tom_high()
	var tom_mid = SoundBank.generate_tom_mid()
	var tom_low = SoundBank.generate_tom_low()
	
	# Create pool of available toms (can repeat for 4-hit fills)
	var tom_pool = [
		{"sound": tom_high, "name": "high"},
		{"sound": tom_mid, "name": "mid"}, 
		{"sound": tom_low, "name": "low"},
		{"sound": tom_high, "name": "high"},  # Allow repeats for variety
		{"sound": tom_mid, "name": "mid"},
		{"sound": tom_low, "name": "low"}
	]
	
	# Randomly determine number of hits
	# 60% chance of 2 hits, 35% chance of 3 hits, 5% chance of 4 hits
	var hit_count = 2  # Default
	var hit_roll = randf()
	if hit_roll < 0.05:
		hit_count = 4  # 5% chance
	elif hit_roll < 0.40:
		hit_count = 3  # 35% chance (0.05 to 0.40)
	else:
		hit_count = 2  # 60% chance (0.40 to 1.0)
	
	# Randomly select timing
	# 40% quarter notes, 40% 8th notes, 20% 16th notes
	var timing_types = {
		"quarter": 0.5,    # Quarter note at 120 BPM
		"eighth": 0.25,    # 8th note at 120 BPM  
		"sixteenth": 0.125 # 16th note at 120 BPM
	}
	
	var timing_roll = randf()
	var fill_spacing = 0.125  # Default to 16th notes
	var timing_name = "sixteenth"
	
	if timing_roll < 0.20:
		fill_spacing = timing_types["sixteenth"]
		timing_name = "sixteenth"
	elif timing_roll < 0.60:
		fill_spacing = timing_types["eighth"] 
		timing_name = "eighth"
	else:
		fill_spacing = timing_types["quarter"]
		timing_name = "quarter"
	
	# Shuffle pool and select the number of hits we want
	tom_pool.shuffle()
	var selected_toms = tom_pool.slice(0, hit_count)
	
	print("[SFXBank] Tom fill: ", hit_count, " hits at ", timing_name, " note timing (", fill_spacing, "s)")
	
	# Play the tom fill with the selected timing
	var base_delay = 0.0
	
	for i in range(selected_toms.size()):
		var tom_data = selected_toms[i]
		if tom_data.sound:
			# Use a timer to create the fill timing
			await get_tree().create_timer(base_delay + (i * fill_spacing)).timeout
			mixer.play_sound(tom_data.sound, "SFX", tom_volume)
			print("[SFXBank] Hit ", i + 1, ": ", tom_data.name, " tom")

func play_game_over():
	var game_over_sound = SoundBank.get_game_over()
	if game_over_sound:
		mixer.play_sound(game_over_sound, "SFX", 2.0)  # Slightly louder