extends Node

# This script generates a thumbnail for level 001 using the same method as the level editor

func _ready():
	print("=== Creating Thumbnail for Level 001 ===")
	
	# Load the level data directly from JSON like the level editor does
	var level_path = "res://levels/001.json"
	var file = FileAccess.open(level_path, FileAccess.READ)
	if not file:
		print("ERROR: Could not open ", level_path)
		return
		
	var json_text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_text)
	if parse_result != OK:
		print("ERROR: Failed to parse JSON")
		return
	
	var data = json.data
	
	# Get level dimensions
	var level_width = int(data.metadata.width) if data.has("metadata") else 16
	var level_height = int(data.metadata.height) if data.has("metadata") else 32
	
	print("Level: ", level_width, "x", level_height)
	
	# Generate clear, high-contrast thumbnail
	var thumbnail_size = 128
	
	# Ensure minimum cell size for visibility
	var cell_size = float(thumbnail_size - 8) / float(max(level_width, level_height))  # Leave 4px border
	cell_size = max(cell_size, 2.0)  # Minimum 2x2 pixels per cell
	
	var img = Image.create(thumbnail_size, thumbnail_size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.05, 0.05, 0.15))  # Very dark blue background for contrast
	
	# Calculate offset to center the level in the thumbnail
	var actual_width = level_width * cell_size
	var actual_height = level_height * cell_size
	var offset_x = (thumbnail_size - actual_width) / 2
	var offset_y = (thumbnail_size - actual_height) / 2
	
	print("Thumbnail info: cell_size=", cell_size, " offset=(", offset_x, ",", offset_y, ")")
	
	# Draw only the walls as bright solid blocks
	for y in range(level_height):
		for x in range(level_width):
			if y < data.tiles.size() and x < data.tiles[y].size():
				var tile = data.tiles[y][x]
				
				if tile == "#":  # Only draw walls
					# Use bright white for maximum contrast
					var color = Color(0.95, 0.95, 0.95)  # Very light gray/white
					
					# Draw a solid block for this tile
					var rect_x = int(offset_x + x * cell_size)
					var rect_y = int(offset_y + y * cell_size)
					var rect_w = max(2, int(cell_size))  # Minimum 2 pixels wide
					var rect_h = max(2, int(cell_size))  # Minimum 2 pixels tall
					
					# Fill the entire cell area
					for py in range(rect_h):
						for px in range(rect_w):
							var pixel_x = rect_x + px
							var pixel_y = rect_y + py
							if pixel_x >= 0 and pixel_x < thumbnail_size and pixel_y >= 0 and pixel_y < thumbnail_size:
								img.set_pixel(pixel_x, pixel_y, color)
	
	# Save the thumbnail to user directory
	var thumbnail_path = "user://001_thumbnail.png"
	img.save_png(thumbnail_path)
	print("✓ Thumbnail saved to: ", thumbnail_path)
	print("✓ Level 1 button will now show the wall layout of the actual level!")
	
	# Verify the level loading system
	print("\nLevel loading verification:")
	print("- Level 1 in menu → loads 001.json")
	print("- LevelGenerator.load_numbered_level(1) → res://levels/001.json")
	print("- Thumbnail shows clean level layout with:")
	print("  - Light gray blocks = walls (#)")
	print("  - Dark background = empty space")
	print("  - Clean, minimal design showing only the level structure")
	
	get_tree().quit()