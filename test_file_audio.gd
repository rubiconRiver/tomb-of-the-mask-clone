extends Node

func _ready():
	print("=== FILE-BASED AUDIO SYSTEM TEST ===")
	
	# Initialize the sound bank
	SoundBank.initialize()
	
	# Test if sounds are loaded
	print("\nTesting sound loading:")
	var kick_sound = SoundBank.get_kick()
	print("Kick sound loaded: ", kick_sound != null)
	
	if not kick_sound:
		print("\n!!! IMPORTANT !!!")
		print("No audio loaded. This likely means the WAV files haven't been imported by Godot yet.")
		print("Please open the project in the Godot editor first to trigger the import process.")
		print("After importing, run this test again.")
		get_tree().quit()
		return
	
	print("Snare sound loaded: ", SoundBank.get_snare() != null)
	print("Coin sound loaded: ", SoundBank.get_coin_chime() != null)
	print("Combo 1 sound loaded: ", SoundBank.get_combo_sound(1) != null)
	print("Combo 8 sound loaded: ", SoundBank.get_combo_sound(8) != null)
	
	# Test theme switching
	print("\nCurrent theme: ", SoundBank.current_theme)
	print("Available themes: ", SoundBank.get_available_themes())
	
	# Test playing a sound through AudioManager
	if AudioManager:
		print("\nTesting sound playback...")
		print("Playing kick drum...")
		AudioManager.play_beat_sound(1)
		
		await get_tree().create_timer(0.5).timeout
		
		print("Playing coin sound...")
		AudioManager.play_coin_collected()
		
		await get_tree().create_timer(0.5).timeout
		
		print("Playing combo sound...")
		AudioManager.play_combo_sound(4, false)
		
		await get_tree().create_timer(1.0).timeout
	
	print("\nFile-based audio test complete!")
	get_tree().quit()