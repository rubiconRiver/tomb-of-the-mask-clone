class_name MelodicBank
extends Node

# Melodic sound playback manager
# Handles combo sounds and multiplier notes

var mixer: AudioMixer
var current_multiplier = 1

func _ready():
	# Wait a frame for all nodes to be ready
	await get_tree().process_frame
	# Get mixer from parent AudioManager
	var audio_manager = get_parent()
	if audio_manager and "mixer" in audio_manager:
		mixer = audio_manager.mixer
	if not mixer:
		push_error("[MelodicBank] Could not find AudioMixer")

func play_combo_sound(combo: int, multiplier_increased: bool):
	var combo_sound = SoundBank.get_combo_sound(combo)
	if combo_sound.size() > 0:
		var volume = 0.0 if multiplier_increased else -6.0
		mixer.play_sound(combo_sound, "Melodic", volume)

func play_multiplier_note(multiplier: int):
	# Only play when multiplier increases
	if multiplier <= current_multiplier:
		current_multiplier = multiplier
		return
	
	current_multiplier = multiplier
	var mult_sound = SoundBank.get_multiplier_sound(multiplier)
	if mult_sound.size() > 0:
		mixer.play_sound(mult_sound, "Melodic", 0.0)

func reset():
	current_multiplier = 1