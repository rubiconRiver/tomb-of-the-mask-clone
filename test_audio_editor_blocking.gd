extends Node

func _ready():
	print("=== Testing Audio Editor Input Blocking ===")
	print("1. Open the level editor")
	print("2. Click on some tiles to verify they can be placed")
	print("3. Open the audio editor (Audio button)")
	print("4. Try clicking on level tiles - they should NOT change")
	print("5. Close the audio editor")
	print("6. Verify you can place tiles again")
	print("")
	print("Starting level editor...")
	
	# Load the level editor scene
	var level_editor_scene = load("res://scenes/level_editor/LevelEditor.tscn")
	var level_editor = level_editor_scene.instantiate()
	get_tree().root.add_child(level_editor)
	
	await get_tree().create_timer(1.0).timeout
	print("Level editor loaded. Test the input blocking manually.")