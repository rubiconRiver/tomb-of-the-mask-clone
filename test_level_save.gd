extends Node

func _ready():
	print("=== Testing Level Save Features ===")
	print("")
	print("1. The level editor now shows the current level name at the top")
	print("2. There's a 'Save As' button that lets you:")
	print("   - Save with a custom name (e.g., '001' for level 1)")
	print("   - Choose between main levels and custom levels")
	print("   - Overwrite existing levels with confirmation")
	print("3. Thumbnails are automatically generated when saving")
	print("4. The main menu will show level thumbnails for numbered levels (001, 002, etc.)")
	print("")
	print("To test:")
	print("1. Open the level editor")
	print("2. Create or modify a level")
	print("3. Click 'Save As' and save as '001'")
	print("4. Return to main menu to see the thumbnail")
	print("")
	print("Starting level editor...")
	
	await get_tree().create_timer(1.0).timeout
	get_tree().change_scene_to_file("res://scenes/level_editor/LevelEditor.tscn")