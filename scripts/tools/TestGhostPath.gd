extends Node

func _ready():
	print("Testing Ghost Path Calculator...")
	
	# Get the empty level template
	var template = LevelTemplates.get_empty_level()
	
	# Load the calculator
	var calculator = load("res://scripts/tools/GhostPathCalculator.gd")
	
	# Calculate the ghost path
	var result = calculator.calculate_ghost_path(template)
	
	print("\nDone! Check the console output above for the ghost move data.")
	print("You can copy the get_empty_level_moves() function into a GhostData.gd file.")
	
	# Quit after running
	get_tree().quit()