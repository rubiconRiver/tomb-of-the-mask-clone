extends Node2D
class_name LevelGenerator

const GRID_SIZE = 64
const LEVEL_WIDTH = 11  # Adjusted for mobile screen
const LEVEL_HEIGHT = 20

var wall_scene = preload("res://scenes/obstacles/Wall.tscn")
var spike_scene = preload("res://scenes/obstacles/Spike.tscn")
var coin_scene = preload("res://scenes/obstacles/Coin.tscn")
var goal_scene = preload("res://scenes/obstacles/Goal.tscn")

var level_data = []
var current_level = 0

enum CellType {
	EMPTY,
	WALL,
	SPIKE,
	COIN,
	PLAYER_SPAWN,
	GOAL
}

func _ready():
	generate_level()

func generate_level():
	# Check if we should use a custom level from the editor
	if LevelEditorData.should_use_custom_level():
		print("Loading custom level from editor...")
		level_data = LevelEditorData.get_custom_level()
		LevelEditorData.clear_custom_level()  # Use it once, then clear
	# Use hand-crafted levels instead of random generation
	elif current_level == 0:
		# Load Level 1
		var template = LevelTemplates.get_level_1()
		level_data = LevelTemplates.parse_template(template)
	else:
		# Fall back to random generation for now
		generate_random_level()
	
	build_level()

func load_from_tilemap(tilemap: TileMap):
	# Clear existing level
	for child in get_children():
		child.queue_free()
	
	level_data = []
	
	# Read tiles from TileMap
	for y in range(LEVEL_HEIGHT):
		var row = []
		for x in range(LEVEL_WIDTH):
			var atlas_coords = tilemap.get_cell_atlas_coords(0, Vector2i(x, y))
			
			# Map atlas coordinates to cell types
			# Based on our tileset layout:
			# (0,0) = Wall, (1,0) = Coin, (2,0) = Spike, (3,0) = Player spawn
			match atlas_coords:
				Vector2i(0, 0):
					row.append(CellType.WALL)
				Vector2i(1, 0):
					row.append(CellType.COIN)
				Vector2i(2, 0):
					row.append(CellType.SPIKE)
				Vector2i(3, 0):
					row.append(CellType.PLAYER_SPAWN)
				_:
					row.append(CellType.EMPTY)
		
		level_data.append(row)
	
	build_level()

func generate_random_level():
	level_data = []
	
	for y in range(LEVEL_HEIGHT):
		var row = []
		for x in range(LEVEL_WIDTH):
			if x == 0 or x == LEVEL_WIDTH - 1 or y == 0 or y == LEVEL_HEIGHT - 1:
				row.append(CellType.WALL)
			else:
				row.append(CellType.EMPTY)
		level_data.append(row)
	
	generate_maze()
	place_hazards()
	place_coins()
	
	level_data[LEVEL_HEIGHT - 2][LEVEL_WIDTH / 2] = CellType.PLAYER_SPAWN

func generate_maze():
	for i in range(current_level + 5):
		var x = randi() % (LEVEL_WIDTH - 2) + 1
		var y = randi() % (LEVEL_HEIGHT - 2) + 1
		
		if randf() > 0.5:
			for dx in range(randi() % 4 + 2):
				if x + dx < LEVEL_WIDTH - 1:
					level_data[y][x + dx] = CellType.WALL
		else:
			for dy in range(randi() % 4 + 2):
				if y + dy < LEVEL_HEIGHT - 1:
					level_data[y + dy][x] = CellType.WALL

func place_hazards():
	var spike_count = mini(current_level * 2 + 3, 15)
	
	for i in range(spike_count):
		var attempts = 0
		while attempts < 50:
			var x = randi() % (LEVEL_WIDTH - 2) + 1
			var y = randi() % (LEVEL_HEIGHT - 2) + 1
			
			if level_data[y][x] == CellType.EMPTY:
				level_data[y][x] = CellType.SPIKE
				break
			attempts += 1

func place_coins():
	var coin_count = 10 + current_level * 2
	
	for i in range(coin_count):
		var attempts = 0
		while attempts < 50:
			var x = randi() % (LEVEL_WIDTH - 2) + 1
			var y = randi() % (LEVEL_HEIGHT - 2) + 1
			
			if level_data[y][x] == CellType.EMPTY:
				level_data[y][x] = CellType.COIN
				break
			attempts += 1

func build_level():
	for child in get_children():
		child.queue_free()
	
	# Get beat visualizer from GameManager
	var game_manager = get_parent()
	var beat_visualizer = null
	if game_manager:
		beat_visualizer = game_manager.get_node_or_null("BeatVisualizer")
		if not beat_visualizer and "beat_visualizer" in game_manager:
			beat_visualizer = game_manager.beat_visualizer
		print("Beat visualizer found: ", beat_visualizer != null)
		if beat_visualizer:
			print("Wall material: ", beat_visualizer.get_material_for_type("wall"))
	
	for y in range(LEVEL_HEIGHT):
		for x in range(LEVEL_WIDTH):
			var world_pos = Vector2(x * GRID_SIZE, y * GRID_SIZE)
			
			match level_data[y][x]:
				CellType.WALL:
					var wall = wall_scene.instantiate()
					wall.position = world_pos
					add_child(wall)
					if beat_visualizer:
						var sprite = wall.get_node_or_null("Sprite2D")
						if sprite:
							sprite.material = beat_visualizer.get_material_for_type("wall")
				CellType.SPIKE:
					var spike = spike_scene.instantiate()
					spike.position = world_pos
					add_child(spike)
					if beat_visualizer:
						var sprite = spike.get_node_or_null("Sprite2D")
						if sprite:
							sprite.material = beat_visualizer.get_material_for_type("spike")
				CellType.COIN:
					var coin = coin_scene.instantiate()
					coin.position = world_pos
					add_child(coin)
					if beat_visualizer:
						var sprite = coin.get_node_or_null("Sprite2D")
						if sprite:
							sprite.material = beat_visualizer.get_material_for_type("coin")
				CellType.GOAL:
					var goal = goal_scene.instantiate()
					goal.position = world_pos
					add_child(goal)
					# Connect goal signal to game manager
					if game_manager and game_manager.has_method("_on_goal_reached"):
						goal.player_reached_goal.connect(game_manager._on_goal_reached)

func get_player_spawn_position() -> Vector2:
	for y in range(LEVEL_HEIGHT):
		for x in range(LEVEL_WIDTH):
			if level_data[y][x] == CellType.PLAYER_SPAWN:
				return Vector2(x * GRID_SIZE, y * GRID_SIZE)
	
	return Vector2(LEVEL_WIDTH / 2 * GRID_SIZE, (LEVEL_HEIGHT - 2) * GRID_SIZE)

func next_level():
	current_level += 1
	generate_level()
