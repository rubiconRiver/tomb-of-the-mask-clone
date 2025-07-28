extends Node

func _ready():
	print("=== Creating Test Level 001 ===")
	
	# Create a simple test level
	var level_data = {
		"metadata": {
			"name": "001",
			"author": "Test Script",
			"created": Time.get_datetime_string_from_system(),
			"version": 1,
			"width": 16,
			"height": 32
		},
		"tiles": [],
		"settings": {
			"beats_per_minute": 120,
			"cells_per_beat": 8
		}
	}
	
	# Create a simple pattern with walls, coins, player spawn and goal
	for y in range(32):
		var row = []
		for x in range(16):
			# Border walls
			if x == 0 or x == 15 or y == 0 or y == 31:
				row.append("#")
			# Player spawn at top left
			elif x == 1 and y == 1:
				row.append("P")
			# Goal at bottom right
			elif x == 14 and y == 30:
				row.append("G")
			# Some coins
			elif (x == 7 or x == 8) and y % 4 == 2:
				row.append("C")
			# Some walls for obstacles
			elif x == 4 and y > 5 and y < 25:
				row.append("#")
			elif x == 11 and y > 10 and y < 30:
				row.append("#")
			else:
				row.append(".")
		level_data.tiles.append(row)
	
	# Save the level
	var json = JSON.new()
	var json_string = json.stringify(level_data, "\t")
	
	var file = FileAccess.open("res://levels/001.json", FileAccess.WRITE)
	if file:
		file.store_string(json_string)
		file.close()
		print("Level saved to: res://levels/001.json")
		
		# Generate thumbnail
		generate_thumbnail_for_level("res://levels/001.json", level_data)
	else:
		print("ERROR: Could not save level file")
	
	print("\nNow you can:")
	print("1. Open the game normally to see the level in the menu")
	print("2. Play level 1 to test it")
	print("3. Open it in the level editor to modify")

func generate_thumbnail_for_level(level_path: String, data):
	print("Generating thumbnail...")
	
	var thumbnail_size = 128
	var level_width = data.metadata.width
	var level_height = data.metadata.height
	var cell_size = float(thumbnail_size) / float(max(level_width, level_height))
	
	var img = Image.create(thumbnail_size, thumbnail_size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.1, 0.1, 0.1))
	
	var offset_x = (thumbnail_size - level_width * cell_size) / 2
	var offset_y = (thumbnail_size - level_height * cell_size) / 2
	
	# Draw tiles
	for y in range(data.tiles.size()):
		for x in range(data.tiles[y].size()):
			var color = Color.TRANSPARENT
			match data.tiles[y][x]:
				"#":
					color = Color(0.5, 0.5, 0.5)  # Gray walls
				"C":
					color = Color(1.0, 1.0, 0.0)  # Yellow coins
				"P":
					color = Color(0.2, 1.0, 0.2)  # Green spawn
				"G":
					color = Color(0.2, 0.2, 1.0)  # Blue goal
			
			if color != Color.TRANSPARENT:
				var rect_x = int(offset_x + x * cell_size)
				var rect_y = int(offset_y + y * cell_size)
				var rect_w = int(cell_size)
				var rect_h = int(cell_size)
				
				for py in range(rect_h):
					for px in range(rect_w):
						if rect_x + px < thumbnail_size and rect_y + py < thumbnail_size:
							img.set_pixel(rect_x + px, rect_y + py, color)
	
	# Save to user directory
	var thumbnail_path = "user://001_thumbnail.png"
	img.save_png(thumbnail_path)
	print("Thumbnail saved to: ", thumbnail_path)