extends Node

# Direct start script - loads straight into gameplay with level 001

func _ready():
	print("=== DIRECT START - LOADING LEVEL 001 ===")
	
	# Load the custom level file
	var file = FileAccess.open("res://levels/custom/level_001.json", FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		var parse_result = json.parse(json_string)
		
		if parse_result == OK:
			var level_dict = json.data
			
			# Set custom level in LevelEditorData
			LevelEditorData.set_custom_level(level_dict["tiles"])
			print("Custom level 001 loaded successfully")
		else:
			print("Error parsing level file")
	else:
		print("Could not open level file")
	
	# Set the level we want to play
	GameData.start_level(1)
	
	# Load directly into the game
	get_tree().change_scene_to_file("res://scenes/main.tscn")