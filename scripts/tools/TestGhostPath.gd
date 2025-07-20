extends Node

func _ready():
	print("Testing Ghost Path Calculator...")
	
	# Get the test_notes level
	var template = LevelTemplates.get_test_notes()
	
	# Load the calculator
	var calculator = load("res://scripts/tools/GhostPathCalculator.gd")
	
	# Calculate the ghost path
	var result = calculator.calculate_ghost_path(template)
	
	print("\nDone! Check the console output above for the ghost move data.")
	print("You can copy the get_test_notes_moves() function into a GhostData.gd file.")
	
	# Quit after running
	get_tree().quit()