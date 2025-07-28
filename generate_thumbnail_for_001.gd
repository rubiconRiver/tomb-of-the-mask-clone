extends Node

func _ready():
	print("=== Generating High-Quality Thumbnail for Level 001 ===")
	
	# Load the level data
	var file = FileAccess.open("res://levels/001.json", FileAccess.READ)
	if not file:
		print("ERROR: Could not open level file")
		return
		
	var json_text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_text)
	if parse_result != OK:
		print("ERROR: Failed to parse JSON")
		return
	
	var data = json.data
	
	print("Level info:")
	print("  Width: ", data.metadata.width)
	print("  Height: ", data.metadata.height)
	print("  Total tiles: ", data.tiles.size() * data.tiles[0].size())
	
	# Generate high-quality thumbnail
	var thumbnail_size = 128
	var level_width = int(data.metadata.width)
	var level_height = int(data.metadata.height)
	
	# Calculate cell size to fit the level properly
	var cell_size = float(thumbnail_size - 4) / float(max(level_width, level_height))  # Leave 2px border
	
	var img = Image.create(thumbnail_size, thumbnail_size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.05, 0.05, 0.1))  # Very dark blue background
	
	# Center the level in the thumbnail
	var offset_x = (thumbnail_size - level_width * cell_size) / 2
	var offset_y = (thumbnail_size - level_height * cell_size) / 2
	
	print("Rendering thumbnail:")
	print("  Cell size: ", cell_size)
	print("  Offset: ", Vector2(offset_x, offset_y))
	
	# Count different tile types for debugging
	var wall_count = 0
	var coin_count = 0
	var spawn_count = 0
	var goal_count = 0
	
	# Draw tiles with proper colors matching the game
	for y in range(data.tiles.size()):
		for x in range(data.tiles[y].size()):
			var tile = data.tiles[y][x]
			var color = Color.TRANSPARENT
			
			match tile:
				"#":
					color = Color(0.6, 0.6, 0.6)  # Light gray walls
					wall_count += 1
				"C":
					color = Color(1.0, 0.9, 0.2)  # Bright yellow coins
					coin_count += 1
				"P":
					color = Color(0.3, 1.0, 0.3)  # Bright green spawn
					spawn_count += 1
				"G":
					color = Color(0.3, 0.5, 1.0)  # Bright blue goal
					goal_count += 1
			
			if color != Color.TRANSPARENT:
				# Draw each cell as a filled rectangle
				var rect_x = int(offset_x + x * cell_size)
				var rect_y = int(offset_y + y * cell_size)
				var rect_w = max(1, int(cell_size))
				var rect_h = max(1, int(cell_size))
				
				# Fill the cell
				for py in range(rect_h):
					for px in range(rect_w):
						var pixel_x = rect_x + px
						var pixel_y = rect_y + py
						if pixel_x >= 0 and pixel_x < thumbnail_size and pixel_y >= 0 and pixel_y < thumbnail_size:
							img.set_pixel(pixel_x, pixel_y, color)
	
	print("Tile counts:")
	print("  Walls: ", wall_count)
	print("  Coins: ", coin_count) 
	print("  Player spawn: ", spawn_count)
	print("  Goals: ", goal_count)
	
	# Save to user directory
	var thumbnail_path = "user://001_thumbnail.png"
	img.save_png(thumbnail_path)
	print("✓ Thumbnail saved to: ", thumbnail_path)
	print("✓ Level 1 will now show this miniature level preview in the main menu!")
	
	# Also print some verification info
	await get_tree().create_timer(1.0).timeout
	print("\nTo test:")
	print("1. Run the main menu")
	print("2. Look for level 1 button - it should show the level layout")
	print("3. Click level 1 - it should load 001.json")