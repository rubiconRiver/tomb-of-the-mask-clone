extends Node2D
class_name LevelEditor

const GRID_SIZE = 64
const LEVEL_WIDTH = 11
const LEVEL_HEIGHT = 20

enum TileType {
	EMPTY = -1,
	WALL = 0,
	COIN = 1,
	SPIKE = 2,
	PLAYER_SPAWN = 3
}

var current_tile_type = TileType.WALL
var tilemap: TileMap
var current_tile_label: Label

@onready var grid_node = $Grid
@onready var ui_layer = $UI
@onready var instructions_panel = $UI/Instructions

func _ready():
	setup_tilemap()
	setup_ui()
	print("Level Editor Ready! Use keys 1-5 to select tools, click to place tiles")

func setup_tilemap():
	# Create TileMap for visual editing
	tilemap = TileMap.new()
	add_child(tilemap)
	
	# Create a simple tileset programmatically
	var tileset = TileSet.new()
	tileset.tile_size = Vector2i(GRID_SIZE, GRID_SIZE)
	
	# Create atlas source with colored tiles
	var atlas_source = TileSetAtlasSource.new()
	
	# Create a simple texture with colored squares
	var image = Image.create(256, 64, false, Image.FORMAT_RGB8)
	# Wall (gray)
	image.fill_rect(Rect2i(0, 0, 64, 64), Color(0.5, 0.5, 0.5))
	# Coin (yellow)
	image.fill_rect(Rect2i(64, 0, 64, 64), Color(1.0, 1.0, 0.0))
	# Spike (red)
	image.fill_rect(Rect2i(128, 0, 64, 64), Color(1.0, 0.2, 0.2))
	# Player spawn (green)
	image.fill_rect(Rect2i(192, 0, 64, 64), Color(0.2, 1.0, 0.2))
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	atlas_source.texture = texture
	atlas_source.texture_region_size = Vector2i(64, 64)
	
	# Set up tiles
	for i in range(4):
		atlas_source.create_tile(Vector2i(i, 0))
		var tile_data = atlas_source.get_tile_data(Vector2i(i, 0), 0)
	
	tileset.add_source(atlas_source, 0)
	tilemap.tile_set = tileset
	
	# Position the tilemap
	tilemap.position = Vector2.ZERO
	
	# Initialize with empty level
	clear_level()

func setup_ui():
	current_tile_label = $UI/CurrentTile
	update_current_tile_display()

func _input(event):
	# Handle tool selection
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1:
				current_tile_type = TileType.WALL
				update_current_tile_display()
			KEY_2:
				current_tile_type = TileType.COIN
				update_current_tile_display()
			KEY_3:
				current_tile_type = TileType.SPIKE
				update_current_tile_display()
			KEY_4:
				current_tile_type = TileType.PLAYER_SPAWN
				update_current_tile_display()
			KEY_5:
				current_tile_type = TileType.EMPTY
				update_current_tile_display()
			KEY_S:
				save_level()
			KEY_L:
				load_into_game()
			KEY_C:
				clear_level()
	
	# Handle mouse input for tile placement
	if event is InputEventMouseButton:
		var grid_pos = world_to_grid(get_global_mouse_position())
		
		if is_valid_grid_position(grid_pos):
			if event.pressed:
				if event.button_index == MOUSE_BUTTON_LEFT:
					place_tile(grid_pos, current_tile_type)
				elif event.button_index == MOUSE_BUTTON_RIGHT:
					place_tile(grid_pos, TileType.EMPTY)

func world_to_grid(world_pos: Vector2) -> Vector2i:
	return Vector2i(int(world_pos.x / GRID_SIZE), int(world_pos.y / GRID_SIZE))

func is_valid_grid_position(grid_pos: Vector2i) -> bool:
	return grid_pos.x >= 0 and grid_pos.x < LEVEL_WIDTH and grid_pos.y >= 0 and grid_pos.y < LEVEL_HEIGHT

func place_tile(grid_pos: Vector2i, tile_type: TileType):
	if tile_type == TileType.EMPTY:
		# Erase tile
		tilemap.set_cell(0, grid_pos, -1)
	else:
		# Place tile
		tilemap.set_cell(0, grid_pos, 0, Vector2i(tile_type, 0))
	
	print("Placed ", get_tile_type_name(tile_type), " at ", grid_pos)

func get_tile_type_name(tile_type: TileType) -> String:
	match tile_type:
		TileType.WALL:
			return "Wall"
		TileType.COIN:
			return "Coin"
		TileType.SPIKE:
			return "Spike"
		TileType.PLAYER_SPAWN:
			return "Player Spawn"
		TileType.EMPTY:
			return "Empty"
		_:
			return "Unknown"

func update_current_tile_display():
	if current_tile_label:
		current_tile_label.text = "Current: " + get_tile_type_name(current_tile_type)

func clear_level():
	print("Clearing level...")
	# Clear all tiles
	for y in range(LEVEL_HEIGHT):
		for x in range(LEVEL_WIDTH):
			tilemap.set_cell(0, Vector2i(x, y), -1)
	
	# Add border walls
	for y in range(LEVEL_HEIGHT):
		for x in range(LEVEL_WIDTH):
			if x == 0 or x == LEVEL_WIDTH - 1 or y == 0 or y == LEVEL_HEIGHT - 1:
				tilemap.set_cell(0, Vector2i(x, y), 0, Vector2i(TileType.WALL, 0))

func save_level():
	print("Saving level...")
	var level_template = []
	
	# Convert tilemap to template format
	for y in range(LEVEL_HEIGHT):
		var row = ""
		for x in range(LEVEL_WIDTH):
			var atlas_coords = tilemap.get_cell_atlas_coords(0, Vector2i(x, y))
			var cell_char = "."
			
			if atlas_coords != Vector2i(-1, -1):
				match atlas_coords.x:
					TileType.WALL:
						cell_char = "#"
					TileType.COIN:
						cell_char = "C"
					TileType.SPIKE:
						cell_char = "S"
					TileType.PLAYER_SPAWN:
						cell_char = "P"
		
			row += cell_char
		level_template.append(row)
	
	# Save to file
	var file = FileAccess.open("user://custom_level.txt", FileAccess.WRITE)
	if file:
		for row in level_template:
			file.store_line(row)
		file.close()
		print("Level saved to user://custom_level.txt")
		
		# Also print to console for easy copying
		print("Level template (copy this to LevelTemplates.gd):")
		for i in range(level_template.size()):
			print('		"', level_template[i], '",  # Row ', i)
	else:
		print("Failed to save level!")

func load_into_game():
	print("Loading level into main game...")
	
	# Validate level has player spawn
	var has_player_spawn = false
	for y in range(LEVEL_HEIGHT):
		for x in range(LEVEL_WIDTH):
			var atlas_coords = tilemap.get_cell_atlas_coords(0, Vector2i(x, y))
			if atlas_coords != Vector2i(-1, -1) and atlas_coords.x == TileType.PLAYER_SPAWN:
				has_player_spawn = true
				break
		if has_player_spawn:
			break
	
	if not has_player_spawn:
		print("ERROR: Level must have at least one Player Spawn (green tile)!")
		return
	
	# Convert current tilemap to level data format that the game can use
	var level_data = []
	
	for y in range(LEVEL_HEIGHT):
		var row = []
		for x in range(LEVEL_WIDTH):
			var atlas_coords = tilemap.get_cell_atlas_coords(0, Vector2i(x, y))
			var cell_type = LevelGenerator.CellType.EMPTY
			
			if atlas_coords != Vector2i(-1, -1):
				match atlas_coords.x:
					TileType.WALL:
						cell_type = LevelGenerator.CellType.WALL
					TileType.COIN:
						cell_type = LevelGenerator.CellType.COIN
					TileType.SPIKE:
						cell_type = LevelGenerator.CellType.SPIKE
					TileType.PLAYER_SPAWN:
						cell_type = LevelGenerator.CellType.PLAYER_SPAWN
			
			row.append(cell_type)
		level_data.append(row)
	
	# Store level data in singleton
	LevelEditorData.set_custom_level(level_data)
	
	# Switch to main scene with custom level
	var main_scene = preload("res://scenes/main.tscn")
	get_tree().change_scene_to_packed(main_scene)

func _draw():
	# Draw grid lines
	var grid_color = Color(0.5, 0.5, 0.5, 0.3)
	
	# Vertical lines
	for x in range(LEVEL_WIDTH + 1):
		var start_pos = Vector2(x * GRID_SIZE, 0)
		var end_pos = Vector2(x * GRID_SIZE, LEVEL_HEIGHT * GRID_SIZE)
		draw_line(start_pos, end_pos, grid_color, 1.0)
	
	# Horizontal lines
	for y in range(LEVEL_HEIGHT + 1):
		var start_pos = Vector2(0, y * GRID_SIZE)
		var end_pos = Vector2(LEVEL_WIDTH * GRID_SIZE, y * GRID_SIZE)
		draw_line(start_pos, end_pos, grid_color, 1.0)

func _process(_delta):
	# Redraw grid every frame
	queue_redraw()