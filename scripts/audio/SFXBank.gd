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
	# Create a quick randomized tom fill using all 3 toms
	# Tom volume is increased for better impact
	var tom_volume = 3.0  # Increased volume for toms
	
	# Get all tom sounds
	var tom_high = SoundBank.generate_tom_high()
	var tom_mid = SoundBank.generate_tom_mid()
	var tom_low = SoundBank.generate_tom_low()
	
	# Create array of toms and shuffle for random order
	var toms = [
		{"sound": tom_high, "name": "high"},
		{"sound": tom_mid, "name": "mid"}, 
		{"sound": tom_low, "name": "low"}
	]
	
	# Shuffle the array for random order
	toms.shuffle()
	
	# Play the tom fill in quick succession (16th note timing)
	var base_delay = 0.0
	var fill_spacing = 0.08  # 16th note at 120 BPM ≈ 0.125s, slightly faster for impact
	
	for i in range(toms.size()):
		var tom_data = toms[i]
		if tom_data.sound:
			# Use a timer to create the fill timing
			await get_tree().create_timer(base_delay + (i * fill_spacing)).timeout
			mixer.play_sound(tom_data.sound, "SFX", tom_volume)
			print("[SFXBank] Tom fill: ", tom_data.name, " tom at position ", i)

func play_game_over():
	var game_over_sound = SoundBank.get_game_over()
	if game_over_sound:
		mixer.play_sound(game_over_sound, "SFX", 2.0)  # Slightly louder