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
	if kick_sound.size() > 0:
		mixer.play_sound(kick_sound, "Drums", 0.0)

func play_snare():
	var snare_sound = SoundBank.get_snare()
	if snare_sound.size() > 0:
		mixer.play_sound(snare_sound, "Drums", 0.0)

func play_hihat():
	var hihat_sound = SoundBank.get_hihat()
	if hihat_sound.size() > 0:
		mixer.play_sound(hihat_sound, "Drums", -6.0)  # Quieter

func play_tom_fill():
	# Play the three toms in sequence
	var sounds = [
		SoundBank.cached_sounds.get("tom_high", PackedFloat32Array()),
		SoundBank.cached_sounds.get("tom_mid", PackedFloat32Array()),
		SoundBank.cached_sounds.get("tom_low", PackedFloat32Array())
	]
	
	# Combine into one sound
	var combined = PackedFloat32Array()
	for sound in sounds:
		combined.append_array(sound)
	
	if combined.size() > 0:
		mixer.play_sound(combined, "Drums", 0.0)