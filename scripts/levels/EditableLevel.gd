@tool
extends Node2D

# Simple level editor using ColorRect nodes
# Build your level by duplicating and positioning the example tiles

@export var export_level: bool = false:
	set(value):
		if value:
			export_to_template()
			export_level = false

func _ready():
	if Engine.is_editor_hint():
		print("Level editor ready! Duplicate ColorRect tiles to build your level.")

func export_to_template():
	var template = []
	
	# Initialize empty 20x11 grid
	for y in range(20):
		var row = ""
		for x in range(11):
			row += "."
		template.append(row)
	
	# Find all ColorRect children and map them to grid
	for child in get_children():
		if child is ColorRect and child.name.begins_with("Example"):
			continue  # Skip template examples
		
		if child is ColorRect:
			var grid_x = int(child.position.x / 64)
			var grid_y = int(child.position.y / 64)
			
			# Skip if out of bounds
			if grid_x < 0 or grid_x >= 11 or grid_y < 0 or grid_y >= 20:
				continue
			
			# Determine tile type by color
			var char = "."
			var color = child.color
			
			if color.is_equal_approx(Color(0.5, 0.5, 0.5, 1)):  # Gray = Wall
				char = "#"
			elif color.is_equal_approx(Color(1, 0.8, 0, 1)):  # Yellow = Coin
				char = "C"
			elif color.is_equal_approx(Color(1, 0, 0, 1)):  # Red = Spike
				char = "S"
			elif color.is_equal_approx(Color(0, 1, 0, 1)):  # Green = Player
				char = "P"
			
			# Set the character in template (flip Y for bottom-up)
			var template_row = template[19 - grid_y]
			template[19 - grid_y] = template_row.substr(0, grid_x) + char + template_row.substr(grid_x + 1)
	
	# Print the template
	print("\n=== LEVEL TEMPLATE ===")
	print("Copy this into LevelTemplates.gd:")
	print("\nstatic func get_level_X() -> Array:")
	print("\tvar template = [")
	
	for i in range(template.size()):
		var row = template[i]
		var comment = "  # Row " + str(i)
		if i == 0:
			comment += " (bottom)"
		elif i == template.size() - 1:
			comment += " (top)"
		
		print('\t\t"' + row + '",' + comment)
	
	print("\t]")
	print("\treturn template")
	print("\n=== END TEMPLATE ===\n")