extends Node

func _ready():
	print("=== AUDIO SYSTEM TEST ===")
	print("AudioManager exists: ", AudioManager != null)
	print("SoundBank initialized: ", SoundBank._initialized)
	print("Cached sounds: ", SoundBank.cached_sounds.size())
	
	# Test playing a sound
	if AudioManager:
		print("Testing kick drum...")
		AudioManager.play_beat_sound(1)
		
	get_tree().quit()