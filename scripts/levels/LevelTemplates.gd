class_name LevelTemplates
extends RefCounted

# Level template format:
# '#' = Wall
# '.' = Empty  
# 'S' = Spike
# 'C' = Coin
# 'P' = Player spawn

static func get_level_1() -> Array:
	# "First Level" - Simple zigzag with proper walls
	# Movement path with coins showing the way
	var template = [
		"###########",  # Row 0 (bottom)
		"#....P...##",  # Row 1 - Start, wall on right
		"#....CCCC##",  # Row 2 - RIGHT: slide to collect coins
		"#........##",  # Row 3 - Can only go up
		"##C......##",  # Row 4 - UP: stop at this platform
		"##CCCCC..##",  # Row 5 - LEFT: slide to collect coins  
		"##.......##",  # Row 6 - Can only go up
		"##......###",  # Row 7 - UP: stop at this platform
		"##.....C###",  # Row 8 - RIGHT: short slide
		"##.....C###",  # Row 9 - Continue up
		"###C...C###",  # Row 10 - UP: stop at center platform
		"###CCCC.###",  # Row 11 - LEFT: slide to collect
		"###.....###",  # Row 12 - Can only go up
		"###....####",  # Row 13 - UP: stop at platform
		"###...C####",  # Row 14 - RIGHT: short slide
		"###...C####",  # Row 15 - Continue up
		"####..C####",  # Row 16 - UP: near the top
		"####CCC####",  # Row 17 - LEFT: final coins
		"####...####",  # Row 18 - Exit area
		"###########"   # Row 19 (top)
	]
	return template

static func parse_template(template: Array) -> Array:
	var level_data = []
	var height = template.size()
	
	# Process from bottom to top (reverse the template array)
	for y in range(height):
		var row = []
		var template_row = template[y]
		
		for x in range(template_row.length()):
			var cell = template_row[x]
			match cell:
				'#':
					row.append(LevelGenerator.CellType.WALL)
				'.':
					row.append(LevelGenerator.CellType.EMPTY)
				'S':
					row.append(LevelGenerator.CellType.SPIKE)
				'C':
					row.append(LevelGenerator.CellType.COIN)
				'P':
					row.append(LevelGenerator.CellType.PLAYER_SPAWN)
				_:
					row.append(LevelGenerator.CellType.EMPTY)
		
		level_data.append(row)
	
	return level_data