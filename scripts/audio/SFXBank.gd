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
	if coin_sound.size() > 0:
		mixer.play_sound(coin_sound, "SFX", 0.0)

func play_wall_hit():
	var wall_sound = SoundBank.get_wall_hit()
	if wall_sound.size() > 0:
		mixer.play_sound(wall_sound, "SFX", 0.0)

func play_game_over():
	var game_over_sound = SoundBank.get_game_over()
	if game_over_sound.size() > 0:
		mixer.play_sound(game_over_sound, "SFX", 2.0)  # Slightly louder