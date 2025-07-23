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
	
	# Calculate timing based on hit count to cap at 1.5 beats max
	# 1.5 beats at 120 BPM = 0.75 seconds
	var max_duration = 0.75
	var max_spacing = max_duration / max(hit_count - 1, 1)  # Space between hits
	
	# Define note timing options but constrain by max duration
	var timing_types = {
		"quarter": 0.5,    # Quarter note at 120 BPM
		"eighth": 0.25,    # 8th note at 120 BPM  
		"sixteenth": 0.125 # 16th note at 120 BPM
	}
	
	# Filter available timings based on hit count and max duration constraint
	var available_timings = []
	for timing_name in timing_types:
		var spacing = timing_types[timing_name]
		var total_duration = spacing * (hit_count - 1)
		if total_duration <= max_duration:
			available_timings.append({"name": timing_name, "spacing": spacing})
	
	# If no standard timing fits, use calculated max spacing
	if available_timings.is_empty():
		available_timings.append({"name": "custom", "spacing": max_spacing})
	
	# Randomly select from available timings
	var selected_timing = available_timings[randi() % available_timings.size()]
	var fill_spacing = selected_timing.spacing
	var timing_name = selected_timing.name
	
	# Shuffle pool and select the number of hits we want
	tom_pool.shuffle()
	var selected_toms = tom_pool.slice(0, hit_count)
	
	# Calculate actual duration for debug output
	var actual_duration = fill_spacing * (hit_count - 1)
	var beats_duration = actual_duration / 0.5  # Convert to beats (0.5s per beat at 120 BPM)
	
	print("[SFXBank] Tom fill: ", hit_count, " hits at ", timing_name, " timing")
	print("  Spacing: ", snapped(fill_spacing, 0.001), "s, Total duration: ", snapped(actual_duration, 0.001), "s (", snapped(beats_duration, 0.1), " beats)")
	
	# Play the tom fill with the selected timing
	var base_delay = 0.0
	
	for i in range(selected_toms.size()):
		var tom_data = selected_toms[i]
		if tom_data.sound:
			# Use a timer to create the fill timing
			await get_tree().create_timer(base_delay + (i * fill_spacing)).timeout
			mixer.play_sound(tom_data.sound, "SFX", tom_volume)
			print("[SFXBank] Hit ", i + 1, ": ", tom_data.name, " tom")

func play_whoosh():
	var whoosh_sound = SoundBank.get_whoosh()
	if whoosh_sound:
		mixer.play_sound(whoosh_sound, "SFX", -3.0)  # Quieter, subtle

func play_game_over():
	var game_over_sound = SoundBank.get_game_over()
	if game_over_sound:
		mixer.play_sound(game_over_sound, "SFX", 2.0)  # Slightly louder