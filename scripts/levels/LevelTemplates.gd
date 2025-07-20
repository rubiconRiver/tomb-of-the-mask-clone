class_name LevelTemplates
extends RefCounted

# Level template format:
# '#' = Wall
# '.' = Empty  
# 'S' = Spike
# 'C' = Coin
# 'P' = Player spawn
# 'G' = Goal

static func get_big_level() -> Array:
	# Big room-based level - 20x100 with custom layout
	var template = [
		"####################################################################################################",
		"#P..#.CCCC.....#...........CCC.........#.........CCC.......#.......CCC.........#.........CCCC.....#",
		"#......#.....#.....#...................#...................#...................#...................#",
		"#..#.....#.........#...................#...................#...................#...................#",
		"####################........#..........#...........C.......#.........C.........#...........C.......#",
		"#..................#.......................................#...................#...................#",
		"#..................#...................#..#................#...................#...................#",
		"#....CCCCC.........#.......CCCCC...............CCCCC.......#.......CCCCC.......#.......CCCCC.......#",
		"#..................#...................#...................#...................#...................#",
		"#......................................#...................#...................#...................#",
		"####################.########.######################################################.###############",
		"#..........................................................#...................#...................#",
		"#....CCCCC.........#.......CCCCC.......#.......CCCCC.......#.......CCCCC.......#.......CCCCC.......#",
		"#..................#...................#...................#...................#...................#",
		"#..................#...................#...................#...................#...................#",
		"#......C...........#.......#.C.........#...#.......C.......#.........C.........#...........C.......#",
		"#..................#...................#...................#...................#...................#",
		"#..................#...................#...................#...................#...................#",
		"#....CCCC..........#.......CCC.........#.........CCC.......#.......CCC.........#.........CCCC....G#",
		"####################################################################################################"
	]
	return template

static func get_tutorial_level() -> Array:
	# Tutorial Level - 20x20 grid teaching basic movement
	# Path: Start top-left, go right, down, left, down to goal
	var template = [
		"####################",  # Row 0 (bottom)
		"#G..................#",  # Row 1 - Goal at bottom-left
		"#...................#",  # Row 2
		"##########.#########",  # Row 3 - Wall forcing left turn
		"#........#.#........#",  # Row 4
		"#........#.#........#",  # Row 5
		"#........#.#........#",  # Row 6
		"#........#.#........#",  # Row 7
		"#CCCCCCCC#.#........#",  # Row 8 - Coin path left
		"#........#.#........#",  # Row 9
		"#.#########.#######.#",  # Row 10 - Wall forcing up turn
		"#.#.......C.......#.#",  # Row 11
		"#.#.......C.......#.#",  # Row 12
		"#.#.......C.......#.#",  # Row 13 - Coin path up
		"#.#.......C.......#.#",  # Row 14
		"#.#.......C.......#.#",  # Row 15
		"#.........C.........#",  # Row 16
		"#.CCCCCCCCCCCCCCCC..#",  # Row 17 - Coin path right
		"#P..................#",  # Row 18 - Player spawn top-left
		"####################"   # Row 19 (top)
	]
	return template

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
		"####.G.####",  # Row 18 - Goal!
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
				'G':
					row.append(LevelGenerator.CellType.GOAL)
				_:
					row.append(LevelGenerator.CellType.EMPTY)
		
		level_data.append(row)
	
	return level_data