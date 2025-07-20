extends Node2D
class_name LevelEditor

const GRID_SIZE = 64

# Default sizes
var level_width = 11
var level_height = 20

# Size presets
const SIZE_PRESETS = {
	"Small": Vector2i(11, 20),
	"Medium": Vector2i(20, 40),
	"Large": Vector2i(30, 60),
	"Huge": Vector2i(50, 100)
}

enum TileType {
	EMPTY = -1,
	WALL = 0,
	COIN = 1,
	SPIKE = 2,
	PLAYER_SPAWN = 3,
	GOAL = 4
}

var current_tile_type = TileType.WALL
var tilemap: TileMap
var current_tile_label: Label
var camera: Camera2D
var file_dialog: FileDialog
var current_filename = ""

# Click and drag support
var is_dragging = false
var last_placed_position = Vector2i(-1, -1)

# Musical note guides
var show_beat_guides = true
var guide_origin = Vector2i(-1, -1)  # Where the guide starts
var guide_destination = Vector2i(-1, -1)  # Where it ends
var is_placing_guide = false
const CELLS_PER_BEAT = 8  # At 1024 speed, 120 BPM
const BEAT_GUIDE_COLORS = {
	1: Color(0.3, 0.8, 0.3, 0.3),   # Quarter note - green
	2: Color(0.3, 0.3, 0.8, 0.3),   # Half note - blue
	4: Color(0.8, 0.3, 0.8, 0.3)    # Whole note - magenta
}

@onready var ui_layer = $UI
@onready var instructions_panel = $UI/Instructions
@onready var grid_node = $Grid

func _ready():
	# Override project's mobile viewport settings for level editor
	get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	get_window().content_scale_aspect = Window.CONTENT_SCALE_ASPECT_IGNORE
	
	# MacBook Pro 14" has 3024x1964 resolution
	# 80% would be roughly 2400x1570, but let's leave room for dock/menu bar
	var editor_width = 2200
	var editor_height = 1400
	
	get_window().size = Vector2i(editor_width, editor_height)
	
	# Set a good window size for level editing
	if OS.has_feature("editor"):
		# Running in editor
		pass
	else:
		# Running standalone - set window size and center it
		get_window().size = Vector2i(editor_width, editor_height)
		# Center the window
		var screen_size = DisplayServer.screen_get_size()
		var window_pos = (screen_size - Vector2i(editor_width, editor_height)) / 2
		get_window().position = window_pos
	
	# Add a background to prevent black edges
	var background = ColorRect.new()
	background.color = Color(0.15, 0.15, 0.15)  # Dark gray background
	background.size = Vector2(5000, 5000)  # Large enough to cover camera movement
	background.position = Vector2(-1000, -1000)  # Center it
	add_child(background)
	move_child(background, 0)  # Put it behind everything
	
	setup_tilemap()
	setup_ui()
	setup_camera()
	setup_file_dialog()
	
	# Make sure grid draws on top of tilemap
	if grid_node:
		grid_node.z_index = 10  # Draw on top of everything
	
	# Check if we're returning from testing a level
	print("=== LEVEL EDITOR STARTING ===")
	var backup = LevelEditorData.get_editor_backup()
	if backup:
		print("Found backup - restoring previous work")
		restore_from_backup(backup)
		LevelEditorData.clear_editor_backup()
	else:
		print("No backup found - loading default level")
		# Load the big level by default
		load_big_level()
	
	# Force initial grid draw
	queue_redraw()
	if grid_node:
		grid_node.queue_redraw()
	
	print("Level Editor Ready!")
	print("Keys 1-5: Tile types (6: Eraser) | Click: Place | Right-click: Erase")
	print("Ctrl+S: Save | L: Load into game | C: Clear | N: Change size")
	print("Arrow keys: Move camera")

func setup_camera():
	camera = Camera2D.new()
	camera.position = Vector2(level_width * GRID_SIZE / 2, level_height * GRID_SIZE / 2)
	add_child(camera)
	camera.make_current()

func setup_file_dialog():
	# We won't use FileDialog, just append to a fixed file
	pass

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
	var image = Image.create(320, 64, false, Image.FORMAT_RGB8)
	# Wall (gray)
	image.fill_rect(Rect2i(0, 0, 64, 64), Color(0.5, 0.5, 0.5))
	# Coin (yellow)
	image.fill_rect(Rect2i(64, 0, 64, 64), Color(1.0, 1.0, 0.0))
	# Spike (red)
	image.fill_rect(Rect2i(128, 0, 64, 64), Color(1.0, 0.2, 0.2))
	# Player spawn (green)
	image.fill_rect(Rect2i(192, 0, 64, 64), Color(0.2, 1.0, 0.2))
	# Goal (blue)
	image.fill_rect(Rect2i(256, 0, 64, 64), Color(0.2, 0.2, 1.0))
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	atlas_source.texture = texture
	atlas_source.texture_region_size = Vector2i(64, 64)
	
	# Set up tiles (excluding EMPTY which is -1)
	for i in range(5):  # Wall(0), Coin(1), Spike(2), PlayerSpawn(3), Goal(4)
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
				current_tile_type = TileType.GOAL
				update_current_tile_display()
			KEY_6:
				current_tile_type = TileType.EMPTY
				update_current_tile_display()
			KEY_S:
				if event.ctrl_pressed:
					save_level()
			KEY_L:
				load_into_game()
			KEY_C:
				clear_level()
			KEY_N:
				new_level_dialog()
			# Camera movement with arrow keys
			KEY_UP:
				if camera:
					camera.position.y -= GRID_SIZE
					queue_redraw()
					if grid_node:
						grid_node.queue_redraw()
			KEY_LEFT:
				if camera:
					camera.position.x -= GRID_SIZE
					queue_redraw()
					if grid_node:
						grid_node.queue_redraw()
			KEY_DOWN:
				if camera:
					camera.position.y += GRID_SIZE
					queue_redraw()
					if grid_node:
						grid_node.queue_redraw()
			KEY_RIGHT:
				if camera:
					camera.position.x += GRID_SIZE
					queue_redraw()
					if grid_node:
						grid_node.queue_redraw()
	
	# Handle mouse input for tile placement
	if event is InputEventMouseButton:
		var grid_pos = world_to_grid(get_global_mouse_position())
		
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				# Start dragging or place guide origin
				if event.shift_pressed:
					# Beat guide mode
					guide_origin = grid_pos
					is_placing_guide = true
					queue_redraw()
				else:
					# Normal tile placement with drag support
					is_dragging = true
					last_placed_position = Vector2i(-1, -1)
					if is_valid_grid_position(grid_pos):
						place_tile(grid_pos, current_tile_type)
						last_placed_position = grid_pos
			else:
				# Release - stop dragging or place guide destination
				if is_placing_guide:
					guide_destination = grid_pos
					is_placing_guide = false
					# Optionally place a wall at the destination
					if is_valid_grid_position(grid_pos):
						place_tile(grid_pos, TileType.WALL)
					queue_redraw()
				else:
					is_dragging = false
					
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed:
				# Right click to erase or clear guides
				if event.shift_pressed:
					# Clear beat guides
					guide_origin = Vector2i(-1, -1)
					guide_destination = Vector2i(-1, -1)
					queue_redraw()
				else:
					# Start erase dragging
					is_dragging = true
					last_placed_position = Vector2i(-1, -1)
					if is_valid_grid_position(grid_pos):
						place_tile(grid_pos, TileType.EMPTY)
						last_placed_position = grid_pos
			else:
				is_dragging = false
	
	# Handle mouse motion for dragging
	elif event is InputEventMouseMotion:
		if is_dragging:
			var grid_pos = world_to_grid(get_global_mouse_position())
			if is_valid_grid_position(grid_pos) and grid_pos != last_placed_position:
				if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
					place_tile(grid_pos, current_tile_type)
				elif Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
					place_tile(grid_pos, TileType.EMPTY)
				last_placed_position = grid_pos
		elif is_placing_guide:
			queue_redraw()  # Update the guide line as mouse moves

func world_to_grid(world_pos: Vector2) -> Vector2i:
	return Vector2i(int(world_pos.x / GRID_SIZE), int(world_pos.y / GRID_SIZE))

func is_valid_grid_position(grid_pos: Vector2i) -> bool:
	return grid_pos.x >= 0 and grid_pos.x < level_width and grid_pos.y >= 0 and grid_pos.y < level_height

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
		TileType.GOAL:
			return "Goal"
		TileType.EMPTY:
			return "Empty"
		_:
			return "Unknown"

func update_current_tile_display():
	if current_tile_label:
		current_tile_label.text = "Current: " + get_tile_type_name(current_tile_type)

func _draw():
	# Draw beat guides
	if show_beat_guides and guide_origin != Vector2i(-1, -1):
		var start_pos = Vector2(guide_origin) * GRID_SIZE + Vector2(GRID_SIZE/2, GRID_SIZE/2)
		var end_pos = Vector2(guide_destination) * GRID_SIZE + Vector2(GRID_SIZE/2, GRID_SIZE/2)
		
		if is_placing_guide:
			# While placing, use mouse position
			end_pos = get_global_mouse_position()
		
		# Draw the guide line
		draw_line(start_pos, end_pos, Color(1.0, 1.0, 0.0, 0.8), 3.0)
		
		# Calculate distance and show beat markers
		var distance = start_pos.distance_to(end_pos)
		var cells = int(distance / GRID_SIZE)
		var beats = float(cells) / CELLS_PER_BEAT
		
		# Draw beat markers along the line
		for i in range(1, 5):  # Show up to 4 beats
			var beat_distance = i * CELLS_PER_BEAT * GRID_SIZE
			if beat_distance < distance:
				var t = beat_distance / distance
				var marker_pos = start_pos.lerp(end_pos, t)
				var color = BEAT_GUIDE_COLORS.get(i, Color.WHITE)
				draw_circle(marker_pos, 8, color)
				draw_circle(marker_pos, 6, Color.BLACK)
				
				# Draw beat number
				var font = ThemeDB.fallback_font
				var text = str(i)
				draw_string(font, marker_pos - Vector2(4, -4), text, HORIZONTAL_ALIGNMENT_CENTER, -1, 12, Color.WHITE)
		
		# Show distance info
		var mid_point = start_pos.lerp(end_pos, 0.5)
		var font = ThemeDB.fallback_font
		var info_text = "%d cells (%.1f beats)" % [cells, beats]
		draw_string(font, mid_point + Vector2(10, -10), info_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.YELLOW)

func load_big_level():
	print("Loading big level...")
	# Get the big level template
	var template = LevelTemplates.get_big_level()
	
	# Update level dimensions
	level_height = template.size()
	if level_height > 0:
		level_width = template[0].length()
	
	# Clear existing tiles
	tilemap.clear()
	
	# Populate tilemap from template
	for y in range(level_height):
		var row = template[y]
		for x in range(row.length()):
			var cell = row[x]
			match cell:
				'#':
					tilemap.set_cell(0, Vector2i(x, y), 0, Vector2i(TileType.WALL, 0))
				'C':
					tilemap.set_cell(0, Vector2i(x, y), 0, Vector2i(TileType.COIN, 0))
				'S':
					tilemap.set_cell(0, Vector2i(x, y), 0, Vector2i(TileType.SPIKE, 0))
				'P':
					tilemap.set_cell(0, Vector2i(x, y), 0, Vector2i(TileType.PLAYER_SPAWN, 0))
				'G':
					tilemap.set_cell(0, Vector2i(x, y), 0, Vector2i(TileType.GOAL, 0))
				'.':
					tilemap.set_cell(0, Vector2i(x, y), -1)  # Empty
	
	# Center camera on the loaded level
	camera.position = Vector2(level_width * GRID_SIZE / 2, level_height * GRID_SIZE / 2)
	
	# Redraw to show grid
	queue_redraw()
	if grid_node:
		grid_node.queue_redraw()

func clear_level():
	print("Clearing level...")
	# Clear all tiles
	for y in range(level_height):
		for x in range(level_width):
			tilemap.set_cell(0, Vector2i(x, y), -1)
	
	# Add border walls
	for y in range(level_height):
		for x in range(level_width):
			if x == 0 or x == level_width - 1 or y == 0 or y == level_height - 1:
				tilemap.set_cell(0, Vector2i(x, y), 0, Vector2i(TileType.WALL, 0))
	
	# Redraw to show grid
	queue_redraw()
	if grid_node:
		grid_node.queue_redraw()

func save_level():
	print("Saving level...")
	var level_template = []
	
	# Convert tilemap to template format
	for y in range(level_height):
		var row = ""
		for x in range(level_width):
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
					TileType.GOAL:
						cell_char = "G"
		
			row += cell_char
		level_template.append(row)
	
	# Get current timestamp
	var datetime = Time.get_datetime_dict_from_system()
	var timestamp = "%04d-%02d-%02d %02d:%02d:%02d" % [
		datetime.year, datetime.month, datetime.day,
		datetime.hour, datetime.minute, datetime.second
	]
	
	# Append to test levels file
	var file = FileAccess.open("res://levels/test_levels.txt", FileAccess.WRITE_READ)
	if not file:
		# Create file if it doesn't exist
		file = FileAccess.open("res://levels/test_levels.txt", FileAccess.WRITE)
	else:
		# Move to end of file
		file.seek_end()
	
	if file:
		# Write header comment
		file.store_line("")
		file.store_line("# Level created: " + timestamp)
		file.store_line("# Size: %dx%d" % [level_width, level_height])
		file.store_line("# Description: [Add description here]")
		file.store_line("")
		
		# Write level data
		for row in level_template:
			file.store_line(row)
		
		file.close()
		print("Level appended to res://levels/test_levels.txt")
		print("Timestamp: " + timestamp)
		
		# Also print to console for easy copying
		print("Level template (copy this to LevelTemplates.gd):")
		for i in range(level_template.size()):
			print('		"', level_template[i], '",  # Row ', i)
	else:
		print("Failed to save level!")

func load_into_game():
	print("=== LOADING LEVEL INTO GAME ===")
	print("Current level dimensions: ", level_width, "x", level_height)
	
	# Validate level has player spawn
	var has_player_spawn = false
	for y in range(level_height):
		for x in range(level_width):
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
	
	for y in range(level_height):
		var row = []
		for x in range(level_width):
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
					TileType.GOAL:
						cell_type = LevelGenerator.CellType.GOAL
			
			row.append(cell_type)
		level_data.append(row)
	
	# Create backup of current tilemap state
	var backup = {}
	backup.width = level_width
	backup.height = level_height
	backup.tiles = []
	
	for y in range(level_height):
		var row = []
		for x in range(level_width):
			var atlas_coords = tilemap.get_cell_atlas_coords(0, Vector2i(x, y))
			if atlas_coords == Vector2i(-1, -1):
				row.append(-1)  # Empty
			else:
				row.append(atlas_coords.x)  # Store tile type
		backup.tiles.append(row)
	
	# Store backup and level data in singleton
	print("Storing level backup with ", backup.tiles.size(), " rows")
	LevelEditorData.set_editor_backup(backup)
	LevelEditorData.set_custom_level(level_data)
	LevelEditorData.set_launched_from_editor(true)
	print("Set launched from editor flag = true")
	
	# Restore mobile viewport settings before switching to main game
	get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	get_window().content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	get_window().size = Vector2i(720, 1560)
	
	# Switch to main scene with custom level
	print("Switching to main game scene...")
	var main_scene = preload("res://scenes/main.tscn")
	get_tree().change_scene_to_packed(main_scene)
	print("Scene change initiated - press M in game to return")


func restore_from_backup(backup):
	print("Restoring level from backup...")
	print("Backup dimensions: ", backup.width, "x", backup.height)
	print("Backup has ", backup.tiles.size(), " rows")
	
	# Update level dimensions
	level_width = backup.width
	level_height = backup.height
	
	# Clear existing tiles
	tilemap.clear()
	
	# Restore tiles from backup
	for y in range(backup.tiles.size()):
		var row = backup.tiles[y]
		for x in range(row.size()):
			var tile_type = row[x]
			if tile_type != -1:
				tilemap.set_cell(0, Vector2i(x, y), 0, Vector2i(tile_type, 0))
	
	# Center camera on the restored level
	camera.position = Vector2(level_width * GRID_SIZE / 2, level_height * GRID_SIZE / 2)
	print("Level restored successfully")

func new_level_dialog():
	print("Select level size:")
	print("Current size: %dx%d" % [level_width, level_height])
	
	# Cycle through size presets
	var current_preset = "Small"
	for preset_name in SIZE_PRESETS:
		var size = SIZE_PRESETS[preset_name]
		if size.x == level_width and size.y == level_height:
			current_preset = preset_name
			break
	
	# Get next preset
	var preset_names = SIZE_PRESETS.keys()
	var current_index = preset_names.find(current_preset)
	var next_index = (current_index + 1) % preset_names.size()
	var next_preset = preset_names[next_index]
	var new_size = SIZE_PRESETS[next_preset]
	
	# Update level size
	level_width = new_size.x
	level_height = new_size.y
	
	print("Changed to %s: %dx%d" % [next_preset, level_width, level_height])
	print("Clearing level for new size...")
	
	# Clear and resize
	clear_level()
	
	# Update camera position
	if camera:
		camera.position = Vector2(level_width * GRID_SIZE / 2, level_height * GRID_SIZE / 2)
