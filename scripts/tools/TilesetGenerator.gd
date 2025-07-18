@tool
extends EditorScript

# This script generates a simple tileset image for level editing
# Run it in the Godot editor: File -> Run

func _run():
	var image = Image.create(256, 64, false, Image.FORMAT_RGB8)
	
	# Define tile types and their colors/labels
	var tiles = [
		{"color": Color(0.3, 0.3, 0.3), "label": "W"},  # Wall - dark gray
		{"color": Color(1.0, 0.8, 0.0), "label": "C"},  # Coin - gold
		{"color": Color(1.0, 0.0, 0.0), "label": "S"},  # Spike - red
		{"color": Color(0.0, 1.0, 0.0), "label": "P"},  # Player - green
	]
	
	# Fill background with transparency/black
	image.fill(Color(0, 0, 0, 0))
	
	# Draw each tile
	for i in range(tiles.size()):
		var tile = tiles[i]
		var x_offset = i * 64
		
		# Draw colored square
		for y in range(64):
			for x in range(64):
				# Add border
				if x < 2 or x >= 62 or y < 2 or y >= 62:
					image.set_pixel(x_offset + x, y, Color(0, 0, 0))
				else:
					image.set_pixel(x_offset + x, y, tile.color)
		
		# Draw letter in center (simplified - just a block for visibility)
		var letter_size = 20
		var letter_offset = (64 - letter_size) / 2
		for y in range(letter_size):
			for x in range(letter_size):
				if tile.label == "W" and (x < 4 or x >= 16 or (x >= 8 and x < 12)):
					image.set_pixel(x_offset + letter_offset + x, letter_offset + y, Color.WHITE)
				elif tile.label == "C" and ((x < 4 and y > 4 and y < 16) or (y < 4 or y >= 16) and x > 4):
					image.set_pixel(x_offset + letter_offset + x, letter_offset + y, Color.BLACK)
				elif tile.label == "S" and (y < 10 or x < 4 or x >= 16):
					image.set_pixel(x_offset + letter_offset + x, letter_offset + y, Color.WHITE)
				elif tile.label == "P" and (x < 4 or (y < 10 and x >= 16)):
					image.set_pixel(x_offset + letter_offset + x, letter_offset + y, Color.WHITE)
	
	# Save the image
	var error = image.save_png("res://assets/sprites/editor_tiles.png")
	if error == OK:
		print("Tileset image created successfully!")
		print("Now reload the project to use the tiles.")
	else:
		print("Failed to save tileset image: ", error)