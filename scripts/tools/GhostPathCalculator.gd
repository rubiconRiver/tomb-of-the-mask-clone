extends Node
class_name GhostPathCalculator

# Directions
enum Direction {
	UP,
	DOWN,
	LEFT,
	RIGHT
}

const DIRECTION_NAMES = {
	Direction.UP: "UP",
	Direction.DOWN: "DOWN",
	Direction.LEFT: "LEFT",
	Direction.RIGHT: "RIGHT"
}

const DIRECTION_VECTORS = {
	Direction.UP: Vector2i(0, -1),
	Direction.DOWN: Vector2i(0, 1),
	Direction.LEFT: Vector2i(-1, 0),
	Direction.RIGHT: Vector2i(1, 0)
}

static func calculate_ghost_path(level_template: Array) -> Dictionary:
	var result = {}
	
	# First, find all waypoints, player spawn, and goal
	var waypoints = {}  # letter -> position
	var player_spawn = Vector2i()
	var goal_pos = Vector2i()
	
	for y in range(level_template.size()):
		var row = level_template[y]
		for x in range(row.length()):
			var cell = row[x]
			if cell == 'P':
				player_spawn = Vector2i(x, y)
			elif cell == 'G':
				goal_pos = Vector2i(x, y)
			elif cell >= 'a' and cell <= 'z':
				waypoints[cell] = Vector2i(x, y)
	
	print("=== GHOST PATH CALCULATOR ===")
	print("Player spawn: ", player_spawn)
	print("Goal: ", goal_pos)
	print("Waypoints found: ", waypoints.size())
	
	# Build the path: P -> a -> b -> ... -> z -> G
	var path_positions = [player_spawn]
	
	# Add waypoints in alphabetical order
	var sorted_letters = waypoints.keys()
	sorted_letters.sort()
	for letter in sorted_letters:
		path_positions.append(waypoints[letter])
		print("  ", letter, ": ", waypoints[letter])
	
	# Add goal at the end
	path_positions.append(goal_pos)
	
	print("\nPath order: P -> ", " -> ".join(sorted_letters), " -> G")
	print("Total positions: ", path_positions.size())
	
	# Now calculate moves between each position
	var moves = []
	var total_cells = 0
	
	for i in range(path_positions.size() - 1):
		var from_pos = path_positions[i]
		var to_pos = path_positions[i + 1]
		
		var segment_moves = calculate_moves_between(from_pos, to_pos, level_template)
		moves.append_array(segment_moves)
		
		var segment_cells = segment_moves.size()
		total_cells += segment_cells
		
		if i == 0:
			print("\nP -> ", sorted_letters[0] if sorted_letters.size() > 0 else "G", ": ", segment_cells, " cells")
		elif i < sorted_letters.size():
			var next_label = sorted_letters[i] if i < sorted_letters.size() else "G"
			print(sorted_letters[i-1], " -> ", next_label, ": ", segment_cells, " cells")
		else:
			print(sorted_letters[-1] if sorted_letters.size() > 0 else "P", " -> G: ", segment_cells, " cells")
	
	print("\nTotal cells: ", total_cells)
	print("Total beats (at 8 cells/beat): ", float(total_cells) / 8.0)
	
	# Generate the output
	result.path_positions = path_positions
	result.moves = moves
	result.total_cells = total_cells
	result.total_beats = float(total_cells) / 8.0
	
	# Print the move sequence for copying
	print("\n=== GHOST MOVE DATA ===")
	print("# Copy this into GhostData.gd:")
	print("static func get_test_notes_moves() -> Array:")
	print("\treturn [")
	
	var beat_counter = 0.0
	for i in range(moves.size()):
		var dir_name = DIRECTION_NAMES[moves[i]]
		var beat_time = beat_counter / 8.0
		print("\t\t{move: Direction.", dir_name, ", beat: ", beat_time, "},  # Move ", i+1)
		beat_counter += 1.0
	
	print("\t]")
	print("\n# Total moves: ", moves.size())
	print("# Total beats: ", float(moves.size()) / 8.0)
	
	return result

static func calculate_moves_between(from: Vector2i, to: Vector2i, level_template: Array) -> Array:
	# Simple pathfinding - prefer straight lines, then turn
	var moves = []
	var current = from
	
	# First move horizontally
	while current.x != to.x:
		if current.x < to.x:
			moves.append(Direction.RIGHT)
			current.x += 1
		else:
			moves.append(Direction.LEFT)
			current.x -= 1
	
	# Then move vertically
	while current.y != to.y:
		if current.y < to.y:
			moves.append(Direction.DOWN)
			current.y += 1
		else:
			moves.append(Direction.UP)
			current.y -= 1
	
	return moves