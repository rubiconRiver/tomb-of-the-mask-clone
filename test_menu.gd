extends Node

# Simple test script to validate main menu functionality

func _ready():
	print("=== MAIN MENU TEST ===")
	
	# Test GameData singleton
	if GameData:
		print("✓ GameData singleton loaded")
		print("  Player Level: ", GameData.get_player_level())
		print("  Total Score: ", GameData.get_total_score())
		print("  Unlocked Levels: ", GameData.get_unlocked_levels())
	else:
		print("✗ GameData singleton missing")
	
	# Test HapticFeedback singleton  
	if HapticFeedback:
		print("✓ HapticFeedback singleton loaded")
		HapticFeedback.trigger_haptic(HapticFeedback.HapticType.LIGHT)
	else:
		print("✗ HapticFeedback singleton missing")
	
	# Test AudioManager singleton
	if AudioManager:
		print("✓ AudioManager singleton loaded")
	else:
		print("✗ AudioManager singleton missing")
	
	# Test main menu scene loading
	await get_tree().create_timer(1.0).timeout
	
	print("=== Loading Main Menu Scene ===")
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")