class_name DrumBank
extends Node

# Drum sound playback manager
# Uses sounds from SoundBank

var mixer: AudioMixer

func _ready():
	# Wait a frame for all nodes to be ready
	await get_tree().process_frame
	# Get mixer from parent AudioManager
	var audio_manager = get_parent()
	if audio_manager and "mixer" in audio_manager:
		mixer = audio_manager.mixer
	if not mixer:
		push_error("[DrumBank] Could not find AudioMixer")

func play_kick():
	var kick_sound = SoundBank.get_kick()
	if kick_sound:
		mixer.play_sound(kick_sound, "Drums", 0.0)

func play_snare():
	var snare_sound = SoundBank.get_snare()
	if snare_sound:
		mixer.play_sound(snare_sound, "Drums", 0.0)

func play_hihat():
	var hihat_sound = SoundBank.get_hihat()
	if hihat_sound:
		mixer.play_sound(hihat_sound, "Drums", -6.0)  # Quieter

func play_tom_fill():
	# For file-based audio, we'll play the wall hit sound which is a tom fill
	var tom_fill = SoundBank.get_wall_hit()
	if tom_fill:
		mixer.play_sound(tom_fill, "Drums", 0.0)
