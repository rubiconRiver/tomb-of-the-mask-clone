extends Node

func _ready():
	print("=== Testing Thumbnail Generation ===")
	
	# Check if level file exists
	var level_path = "res://levels/001.json"
	if not FileAccess.file_exists(level_path):
		print("ERROR: Level file not found: ", level_path)
		return
	
	# Load level data
	var file = FileAccess.open(level_path, FileAccess.READ)
	if not file:
		print("ERROR: Could not open level file")
		return
		
	var json_text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	if json.parse(json_text) != OK:
		print("ERROR: Invalid JSON")
		return
	
	var data = json.data
	var level_width = int(data.metadata.width)
	var level_height = int(data.metadata.height)
	
	print("Level info: ", level_width, "x", level_height)
	print("Tiles array size: ", data.tiles.size())
	if data.tiles.size() > 0:
		print("First row length: ", data.tiles[0].size())
	
	# Generate thumbnail exactly like the level editor does
	var thumbnail_size = 128
	var cell_size = float(thumbnail_size - 8) / float(max(level_width, level_height))
	cell_size = max(cell_size, 2.0)
	
	var img = Image.create(thumbnail_size, thumbnail_size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.05, 0.05, 0.15))  # Dark blue background
	
	var actual_width = level_width * cell_size
	var actual_height = level_height * cell_size
	var offset_x = (thumbnail_size - actual_width) / 2
	var offset_y = (thumbnail_size - actual_height) / 2
	
	print("Thumbnail generation:")
	print("  Cell size: ", cell_size)
	print("  Offset: (", offset_x, ", ", offset_y, ")")
	
	var wall_count = 0
	
	# Draw walls
	for y in range(level_height):
		for x in range(level_width):
			if y < data.tiles.size() and x < data.tiles[y].size():
				var tile = data.tiles[y][x]
				if tile == "#":
					wall_count += 1
					var color = Color(0.95, 0.95, 0.95)  # Bright white
					
					var rect_x = int(offset_x + x * cell_size)
					var rect_y = int(offset_y + y * cell_size)
					var rect_w = max(2, int(cell_size))
					var rect_h = max(2, int(cell_size))
					
					for py in range(rect_h):
						for px in range(rect_w):
							var pixel_x = rect_x + px
							var pixel_y = rect_y + py
							if pixel_x >= 0 and pixel_x < thumbnail_size and pixel_y >= 0 and pixel_y < thumbnail_size:
								img.set_pixel(pixel_x, pixel_y, color)
	
	print("Drew ", wall_count, " wall blocks")
	
	# Save thumbnail
	var thumbnail_path = "user://001_thumbnail.png"
	if img.save_png(thumbnail_path) == OK:
		print("✓ Thumbnail saved to: ", thumbnail_path)
		print("✓ The main menu should now show the level layout!")
	else:
		print("✗ Failed to save thumbnail")
	
	get_tree().quit()