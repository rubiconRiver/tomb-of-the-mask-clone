class_name LevelTemplates
extends RefCounted

# Level template format:
# '#' = Wall
# '.' = Empty  
# 'C' = Coin
# 'P' = Player spawn
# 'G' = Goal

# Updated for 18x32 mobile-optimized levels

static func get_empty_level() -> Array:
	# Empty 16x32 level template with walls around edges
	var template = [
		"################",  # Row 0 (top)
		"#P.............#",  # Row 1 - Player spawn top-left
		"#..............#",  # Row 2
		"#..............#",  # Row 3
		"#..............#",  # Row 4
		"#..............#",  # Row 5
		"#..............#",  # Row 6
		"#..............#",  # Row 7
		"#..............#",  # Row 8
		"#..............#",  # Row 9
		"#..............#",  # Row 10
		"#..............#",  # Row 11
		"#..............#",  # Row 12
		"#..............#",  # Row 13
		"#..............#",  # Row 14
		"#..............#",  # Row 15
		"#..............#",  # Row 16
		"#..............#",  # Row 17
		"#..............#",  # Row 18
		"#..............#",  # Row 19
		"#..............#",  # Row 20
		"#..............#",  # Row 21
		"#..............#",  # Row 22
		"#..............#",  # Row 23
		"#..............#",  # Row 24
		"#..............#",  # Row 25
		"#..............#",  # Row 26
		"#..............#",  # Row 27
		"#..............#",  # Row 28
		"#..............#",  # Row 29
		"#.............G#",  # Row 30 - Goal bottom-right
		"################"   # Row 31 (bottom)
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
			var char = template_row[x]
			match char:
				'#':
					row.append(LevelGenerator.CellType.WALL)
				'C':
					row.append(LevelGenerator.CellType.COIN)
				'P':
					row.append(LevelGenerator.CellType.PLAYER_SPAWN)
				'G':
					row.append(LevelGenerator.CellType.GOAL)
				'.', ' ':
					row.append(LevelGenerator.CellType.EMPTY)
				_:
					row.append(LevelGenerator.CellType.EMPTY)
		
		level_data.append(row)
	
	# Reverse the array so index 0 is at the bottom
	level_data.reverse()
	
	return level_data