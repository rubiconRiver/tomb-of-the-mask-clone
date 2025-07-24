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
	GOAL = 4,
	WAYPOINT = 5  # For path visualization
}

var current_tile_type = TileType.WALL
var tilemap: TileMap
var current_tile_label: Label
var camera: Camera2D
var file_dialog: FileDialog
var current_filename = ""
var file_browser_scene = preload("res://scenes/level_editor/FileBrowser.tscn")

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
@onready var grid_node = $Grid
@onready var status_label = $UI/StatusBar/StatusLabel
@onready var coordinates_label = $UI/StatusBar/CoordinatesLabel
@onready var file_button = $UI/TopBar/ToolButtons/FileButton
@onready var edit_button = $UI/TopBar/ToolButtons/EditButton
@onready var view_button = $UI/TopBar/ToolButtons/ViewButton
@onready var play_button = $UI/TopBar/ToolButtons/PlayButton
@onready var save_button = $UI/TopBar/ToolButtons/SaveButton
@onready var load_button = $UI/TopBar/ToolButtons/LoadButton
@onready var audio_button = $UI/TopBar/ToolButtons/AudioButton


# Waypoint system
var waypoints = {}  # Dictionary of grid_pos -> letter
var waypoint_order = []  # Array of grid positions in order
var next_waypoint_letter = 'a'  # Start with 'a'

# Audio pattern system
var level_audio_pattern = null  # Stores the audio pattern from AudioEditor

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
	
	# Set up drawing order
	if grid_node:
		grid_node.z_index = 1  # Grid lines behind waypoint labels
	
	# Make sure level editor draws on top for waypoints
	z_index = 10  # Draw waypoints on top of everything
	
	# Check if we're returning from testing a level
	print("=== LEVEL EDITOR STARTING ===")
	var backup = LevelEditorData.get_editor_backup()
	if backup:
		print("Found backup - restoring previous work")
		restore_from_backup(backup)
		LevelEditorData.clear_editor_backup()
	else:
		print("No backup found - loading default level")
		# Load the test notes level by default
		load_test_notes()
	
	# Force initial grid draw
	queue_redraw()
	if grid_node:
		grid_node.queue_redraw()
	
	print("Level Editor Ready!")
	print("Keys 1-5: Tile types (6: Eraser) | Click: Place | Right-click: Erase")
	print("Ctrl+S: Save | L: Load into game | C: Clear | N: Change size")
	print("Arrow keys: Move camera | Scroll wheel: Zoom in/out")

func setup_camera():
	camera = Camera2D.new()
	camera.position = Vector2(level_width * GRID_SIZE / 2, level_height * GRID_SIZE / 2)
	add_child(camera)
	camera.make_current()
	
	# Calculate zoom to fit entire level on screen
	var window_size = get_window().size
	var level_size = Vector2(level_width * GRID_SIZE, level_height * GRID_SIZE)
	
	# Add minimal padding (5% border) to see more of the level
	var padding_factor = 1.05
	var zoom_x = window_size.x / (level_size.x * padding_factor)
	var zoom_y = window_size.y / (level_size.y * padding_factor)
	
	# Use the smaller zoom factor to ensure entire level fits
	var zoom_factor = min(zoom_x, zoom_y)
	# Make it even more zoomed out by default
	zoom_factor *= 0.8
	camera.zoom = Vector2(zoom_factor, zoom_factor)
	
	print("[LevelEditor] Camera zoom set to: ", zoom_factor, " to fit level size: ", level_size)

func update_camera_for_level_size():
	if not camera:
		return
		
	# Center camera on level
	camera.position = Vector2(level_width * GRID_SIZE / 2, level_height * GRID_SIZE / 2)
	
	# Calculate zoom to fit entire level on screen
	var window_size = get_window().size
	var level_size = Vector2(level_width * GRID_SIZE, level_height * GRID_SIZE)
	
	# Add minimal padding (5% border) to see more of the level
	var padding_factor = 1.05
	var zoom_x = window_size.x / (level_size.x * padding_factor)
	var zoom_y = window_size.y / (level_size.y * padding_factor)
	
	# Use the smaller zoom factor to ensure entire level fits
	var zoom_factor = min(zoom_x, zoom_y)
	# Make it even more zoomed out by default
	zoom_factor *= 0.8
	camera.zoom = Vector2(zoom_factor, zoom_factor)
	
	print("[LevelEditor] Updated camera for level size: ", level_size, " with zoom: ", zoom_factor)

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
	var image = Image.create(384, 64, false, Image.FORMAT_RGBA8)  # Added alpha channel and extended width
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
	# Waypoint (brown with transparency for editor visibility)
	image.fill_rect(Rect2i(320, 0, 64, 64), Color(0.6, 0.4, 0.2, 0.7))
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	atlas_source.texture = texture
	atlas_source.texture_region_size = Vector2i(64, 64)
	
	# Set up tiles (excluding EMPTY which is -1)
	for i in range(6):  # Wall(0), Coin(1), Spike(2), PlayerSpawn(3), Goal(4), Waypoint(5)
		atlas_source.create_tile(Vector2i(i, 0))
		var tile_data = atlas_source.get_tile_data(Vector2i(i, 0), 0)
	
	tileset.add_source(atlas_source, 0)
	tilemap.tile_set = tileset
	
	# Position the tilemap
	tilemap.position = Vector2.ZERO
	
	# Initialize with empty level
	clear_level()

func setup_ui():
	current_tile_label = $UI/TopBar/CurrentTilePanel/CurrentTileLabel
	update_current_tile_display()
	
	# Connect button signals
	if file_button:
		file_button.pressed.connect(_on_file_button_pressed)
	if edit_button:
		edit_button.pressed.connect(_on_edit_button_pressed)
	if view_button:
		view_button.pressed.connect(_on_view_button_pressed)
	if play_button:
		play_button.pressed.connect(load_into_game)
	if save_button:
		save_button.pressed.connect(save_level)
	if load_button:
		load_button.pressed.connect(_on_load_button_pressed)
	if audio_button:
		audio_button.pressed.connect(_on_audio_button_pressed)
	
	# Update status
	if status_label:
		status_label.text = "Ready"

func _input(event):
	# Handle mouse wheel zoom
	if event is InputEventMouseButton:
		if event.pressed:
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				# Zoom in
				camera.zoom *= 1.1
				camera.zoom = camera.zoom.clamp(Vector2(0.1, 0.1), Vector2(5.0, 5.0))
				print("[LevelEditor] Zoom in: ", camera.zoom.x)
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				# Zoom out
				camera.zoom *= 0.9
				camera.zoom = camera.zoom.clamp(Vector2(0.1, 0.1), Vector2(5.0, 5.0))
				print("[LevelEditor] Zoom out: ", camera.zoom.x)
	
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
			KEY_9:
				current_tile_type = TileType.WAYPOINT
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
			KEY_G:
				if event.ctrl_pressed:
					calculate_ghost_path()
	
	# Handle mouse input for tile placement
	if event is InputEventMouseButton and event.button_index != MOUSE_BUTTON_WHEEL_UP and event.button_index != MOUSE_BUTTON_WHEEL_DOWN:
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
		# Update coordinates display
		var grid_pos = world_to_grid(get_global_mouse_position())
		if coordinates_label and is_valid_grid_position(grid_pos):
			coordinates_label.text = "%d, %d" % [grid_pos.x, grid_pos.y]
		
		if is_dragging:
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
		# Erase tile - also remove waypoint if present
		tilemap.set_cell(0, grid_pos, -1)
		if grid_pos in waypoints:
			remove_waypoint_at_position(grid_pos)  # Use new function for erasers too
	elif tile_type == TileType.WAYPOINT:
		# Handle waypoint placement
		if grid_pos in waypoints:
			# Already has a waypoint, remove it and allow replacement
			var letter = waypoints[grid_pos]
			remove_waypoint_at_position(grid_pos)  # New function for position-specific removal
			tilemap.set_cell(0, grid_pos, -1)  # Remove the tile
			print("Removed waypoint '", letter, "' at ", grid_pos)
			return
		else:
			# Store the letter before adding (for correct logging)
			var letter_to_place = next_waypoint_letter
			# Add new waypoint with next letter
			add_waypoint(grid_pos)
			tilemap.set_cell(0, grid_pos, 0, Vector2i(TileType.WAYPOINT, 0))  # Place waypoint tile
			print("Placed waypoint '", letter_to_place, "' at ", grid_pos)
			return
	else:
		# Place regular tile - remove waypoint if present
		tilemap.set_cell(0, grid_pos, 0, Vector2i(tile_type, 0))
		if grid_pos in waypoints:
			remove_waypoint(grid_pos)
	
	var tile_name = get_tile_type_name(tile_type)
	print("Placed ", tile_name, " at ", grid_pos)
	if status_label:
		status_label.text = "Placed %s at (%d, %d)" % [tile_name, grid_pos.x, grid_pos.y]

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
		TileType.WAYPOINT:
			return "Waypoint (" + str(next_waypoint_letter) + ")"
		_:
			return "Unknown"

func update_current_tile_display():
	if current_tile_label:
		current_tile_label.text = "Current: " + get_tile_type_name(current_tile_type)

func add_waypoint(grid_pos: Vector2i):
	# Only allow up to 26 waypoints (a-z)
	if waypoint_order.size() >= 26:
		print("Maximum waypoints reached (26)")
		return
		
	# Add waypoint with current letter
	waypoints[grid_pos] = next_waypoint_letter
	waypoint_order.append(grid_pos)
	
	# Advance to next letter
	var next_char_code = next_waypoint_letter.unicode_at(0) + 1
	if next_char_code <= 'z'.unicode_at(0):
		next_waypoint_letter = char(next_char_code)
	
	update_current_tile_display()
	queue_redraw()

func remove_waypoint(grid_pos: Vector2i):
	if not grid_pos in waypoints:
		return
		
	var letter = waypoints[grid_pos]
	var index = waypoint_order.find(grid_pos)
	
	# Only allow removing the most recent waypoint (for keyboard usage)
	if index == waypoint_order.size() - 1:
		remove_waypoint_at_position(grid_pos)
	else:
		print("Can only remove the most recent waypoint (currently '%s')" % [waypoints[waypoint_order[-1]]])

func remove_waypoint_at_position(grid_pos: Vector2i):
	# New function: Remove waypoint at any position and rebuild sequence
	if not grid_pos in waypoints:
		return
		
	var letter = waypoints[grid_pos]
	var index = waypoint_order.find(grid_pos)
	
	# Remove the waypoint
	waypoints.erase(grid_pos)
	waypoint_order.remove_at(index)
	
	# Rebuild the waypoint letter sequence to maintain order
	rebuild_waypoint_sequence()
	
	update_current_tile_display()
	queue_redraw()
	print("Removed waypoint '", letter, "' and rebuilt sequence")

func rebuild_waypoint_sequence():
	# Rebuild waypoint letters to be sequential (a, b, c, etc.)
	var new_waypoints = {}
	var current_letter = 'a'
	
	for pos in waypoint_order:
		new_waypoints[pos] = current_letter
		var next_char_code = current_letter.unicode_at(0) + 1
		if next_char_code <= 'z'.unicode_at(0):
			current_letter = char(next_char_code)
		else:
			current_letter = 'z'  # Cap at 'z'
	
	waypoints = new_waypoints
	next_waypoint_letter = current_letter

func _draw():
	# Draw waypoint path
	if waypoint_order.size() > 0:
		# Draw path lines between waypoints
		for i in range(waypoint_order.size() - 1):
			var start_pos = Vector2(waypoint_order[i]) * GRID_SIZE + Vector2(GRID_SIZE/2, GRID_SIZE/2)
			var end_pos = Vector2(waypoint_order[i + 1]) * GRID_SIZE + Vector2(GRID_SIZE/2, GRID_SIZE/2)
			
			# Draw dotted line in brown to match waypoint color
			draw_dotted_line(start_pos, end_pos, Color(0.6, 0.4, 0.2, 0.8), 3.0, 10.0)
		
		# Draw waypoint markers with letters
		var font = ThemeDB.fallback_font
		for pos in waypoint_order:
			var world_pos = Vector2(pos) * GRID_SIZE + Vector2(GRID_SIZE/2, GRID_SIZE/2)
			var letter = waypoints[pos]
			
			# Draw white background circle for letter visibility
			draw_circle(world_pos, 20, Color(1.0, 1.0, 1.0, 0.9))  # White background
			draw_circle(world_pos, 18, Color(0.0, 0.0, 0.0, 1.0))  # Black border
			
			# Draw letter with larger size in white
			draw_string(font, world_pos - Vector2(8, -8), letter, HORIZONTAL_ALIGNMENT_CENTER, -1, 32, Color.WHITE)
	
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

func draw_dotted_line(start: Vector2, end: Vector2, color: Color, width: float, dash_length: float):
	var direction = (end - start).normalized()
	var distance = start.distance_to(end)
	var current_distance = 0.0
	var draw_dash = true
	
	while current_distance < distance:
		var segment_start = start + direction * current_distance
		var segment_end = start + direction * min(current_distance + dash_length, distance)
		
		if draw_dash:
			draw_line(segment_start, segment_end, color, width)
		
		current_distance += dash_length
		draw_dash = not draw_dash

func load_level_from_json(path: String):
	print("Loading level from: ", path)
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		print("ERROR: Could not open file: ", path)
		return false
		
	var json_text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_text)
	if parse_result != OK:
		print("ERROR: Failed to parse JSON: ", json.get_error_message())
		return false
	
	var data = json.data
	
	# Load metadata
	if data.has("metadata"):
		var meta = data.metadata
		level_width = meta.get("width", 11)
		level_height = meta.get("height", 20)
		print("Level: ", meta.get("name", "Unnamed"), " (", level_width, "x", level_height, ")")
	
	# Clear existing level
	tilemap.clear()
	waypoints.clear()
	waypoint_order.clear()
	next_waypoint_letter = 'a'
	
	# Load tiles
	if data.has("tiles"):
		var tiles = data.tiles
		for y in range(min(tiles.size(), level_height)):
			var row = tiles[y]
			for x in range(min(row.size(), level_width)):
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
					_:
						# Check if it's a lowercase letter (waypoint)
						if typeof(cell) == TYPE_STRING and cell.length() == 1:
							var char_code = cell.unicode_at(0)
							if char_code >= 'a'.unicode_at(0) and char_code <= 'z'.unicode_at(0):
								# It's a waypoint
								var pos = Vector2i(x, y)
								waypoints[pos] = cell
								waypoint_order.append(pos)
								tilemap.set_cell(0, pos, 0, Vector2i(TileType.WAYPOINT, 0))
								# Update next letter
								if char_code >= next_waypoint_letter.unicode_at(0):
									next_waypoint_letter = char(char_code + 1)
									if next_waypoint_letter.unicode_at(0) > 'z'.unicode_at(0):
										next_waypoint_letter = 'z'
	
	# Load waypoint data if available (for proper ordering)
	if data.has("waypoints") and data.waypoints.has("order"):
		var wp_data = data.waypoints
		waypoint_order.clear()
		for pos_array in wp_data.order:
			if pos_array.size() >= 2:
				var pos = Vector2i(pos_array[0], pos_array[1])
				if pos in waypoints:
					waypoint_order.append(pos)
	
	# Update camera and redraw
	update_camera_for_level_size()
	queue_redraw()
	if grid_node:
		grid_node.queue_redraw()
	
	# Load audio pattern if available
	if data.has("audio_pattern") and data.audio_pattern != null:
		level_audio_pattern = data.audio_pattern
		print("[LevelEditor] Loaded audio pattern:")
		print("  BPM: ", level_audio_pattern.bpm)
		print("  Theme: ", level_audio_pattern.theme)
		print("  Pattern tracks: ", level_audio_pattern.patterns.keys())
	else:
		level_audio_pattern = null
		print("[LevelEditor] No audio pattern found in level file")
	
	update_current_tile_display()
	if status_label:
		var status_text = "Loaded: " + path.get_file()
		if level_audio_pattern:
			status_text += " (with audio pattern)"
		status_label.text = status_text
	
	return true

func load_test_notes():
	print("Loading default level from JSON...")
	load_level_from_json("res://levels/default_level.json")

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
	
	# Clear waypoints
	waypoints.clear()
	waypoint_order.clear()
	next_waypoint_letter = 'a'
	
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
				_:
					# Check if it's a lowercase letter (waypoint)
					if cell >= 'a' and cell <= 'z':
						add_waypoint(Vector2i(x, y))
					else:
						tilemap.set_cell(0, Vector2i(x, y), -1)  # Default to empty
	
	# Recalculate camera zoom and position for new level size
	update_camera_for_level_size()
	
	# Redraw to show grid
	queue_redraw()
	if grid_node:
		grid_node.queue_redraw()

func clear_level():
	print("Clearing level...")
	# Clear waypoints
	waypoints.clear()
	waypoint_order.clear()
	next_waypoint_letter = 'a'
	
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
	
	# Debug: Check if we have audio pattern data
	if level_audio_pattern:
		print("[LevelEditor] Audio pattern found for saving:")
		print("  BPM: ", level_audio_pattern.bpm)
		print("  Theme: ", level_audio_pattern.theme)
		print("  Pattern tracks: ", level_audio_pattern.patterns.keys())
	else:
		print("[LevelEditor] No audio pattern to save")
	
	# Build the level data structure
	var level_data = {
		"metadata": {
			"name": current_filename.get_basename() if current_filename != "" else "Untitled",
			"author": "Level Editor",
			"created": Time.get_datetime_string_from_system(),
			"version": 1,
			"width": level_width,
			"height": level_height
		},
		"tiles": [],
		"waypoints": {
			"order": [],
			"positions": {}
		},
		"settings": {
			"beats_per_minute": level_audio_pattern.bpm if level_audio_pattern else 120,
			"cells_per_beat": CELLS_PER_BEAT
		},
		"audio_pattern": level_audio_pattern
	}
	
	# Convert tilemap to JSON format
	for y in range(level_height):
		var row = []
		for x in range(level_width):
			var grid_pos = Vector2i(x, y)
			var cell_char = "."
			
			# Check for waypoint first
			if grid_pos in waypoints:
				cell_char = waypoints[grid_pos]
			else:
				# Check regular tiles
				var atlas_coords = tilemap.get_cell_atlas_coords(0, grid_pos)
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
						TileType.WAYPOINT:
							# This shouldn't happen since we check waypoints first
							cell_char = "."
			
			row.append(cell_char)
		level_data.tiles.append(row)
	
	# Add waypoint data
	for pos in waypoint_order:
		level_data.waypoints.order.append([pos.x, pos.y])
		level_data.waypoints.positions[str(pos.x) + "," + str(pos.y)] = waypoints[pos]
	
	# Save to JSON file
	var json = JSON.new()
	var json_string = json.stringify(level_data, "\t")
	
	# Find next available filename
	var base_name = "level_"
	var number = 1
	var file_path = ""
	
	# Check for existing files and find next number
	while true:
		file_path = "res://levels/custom/%s%03d.json" % [base_name, number]
		if not FileAccess.file_exists(file_path):
			break
		number += 1
	
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		file.store_string(json_string)
		file.close()
		current_filename = "custom/" + file_path.get_file()
		print("Level saved to: ", file_path)
		if status_label:
			status_label.text = "Saved: " + file_path.get_file()
		
		# Also print a summary
		print("Level: ", level_width, "x", level_height)
		if waypoint_order.size() > 0:
			var path_str = ""
			for pos in waypoint_order:
				path_str += waypoints[pos] + "->"
			print("Perfect path: ", path_str.trim_suffix("->"))
	else:
		print("ERROR: Failed to save level!")
		if status_label:
			status_label.text = "Error: Failed to save"

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
					TileType.WAYPOINT:
						# Waypoints are invisible in game
						cell_type = LevelGenerator.CellType.EMPTY
			
			row.append(cell_type)
		level_data.append(row)
	
	# Create backup of current tilemap state
	var backup = {}
	backup.width = level_width
	backup.height = level_height
	backup.tiles = []
	backup.waypoints = waypoints.duplicate()
	backup.waypoint_order = waypoint_order.duplicate()
	backup.next_waypoint_letter = next_waypoint_letter
	
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
	
	# Pass custom audio pattern if available
	if level_audio_pattern:
		LevelEditorData.set_custom_audio_pattern(level_audio_pattern)
		print("Custom audio pattern passed to game")
	else:
		LevelEditorData.clear_custom_audio_pattern()
		print("No custom audio pattern - game will use default beat")
	
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
	
	# Restore waypoints if they exist
	if backup.has("waypoints"):
		waypoints = backup.waypoints.duplicate()
		waypoint_order = backup.waypoint_order.duplicate()
		next_waypoint_letter = backup.get("next_waypoint_letter", 'a')
		print("Restored ", waypoint_order.size(), " waypoints")
	else:
		waypoints.clear()
		waypoint_order.clear()
		next_waypoint_letter = 'a'
	
	# Restore tiles from backup
	for y in range(backup.tiles.size()):
		var row = backup.tiles[y]
		for x in range(row.size()):
			var tile_type = row[x]
			if tile_type != -1:
				tilemap.set_cell(0, Vector2i(x, y), 0, Vector2i(tile_type, 0))
	
	# Update camera for restored level size
	update_camera_for_level_size()
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
	
	# Update camera for new level size
	update_camera_for_level_size()

func calculate_ghost_path():
	print("\n=== CALCULATING GHOST PATH ===")
	
	# Build current level template
	var level_template = []
	for y in range(level_height):
		var row = ""
		for x in range(level_width):
			var grid_pos = Vector2i(x, y)
			var cell_char = "."
			
			# Check for waypoint first
			if grid_pos in waypoints:
				cell_char = waypoints[grid_pos]
			else:
				# Check regular tiles
				var atlas_coords = tilemap.get_cell_atlas_coords(0, grid_pos)
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
	
	# Calculate the path
	var calculator = load("res://scripts/tools/GhostPathCalculator.gd")
	var result = calculator.calculate_ghost_path(level_template)
	
	print("\nPress Ctrl+G to recalculate ghost path")

# Button handlers
func _on_file_button_pressed():
	print("File menu - TODO")
	if status_label:
		status_label.text = "File menu coming soon..."

func _on_edit_button_pressed():
	print("Edit menu - TODO")
	if status_label:
		status_label.text = "Edit menu coming soon..."

func _on_view_button_pressed():
	print("View menu - TODO")
	if status_label:
		status_label.text = "View menu coming soon..."

func _on_load_button_pressed():
	print("Opening file browser...")
	open_file_browser()

func _on_audio_button_pressed():
	print("Opening audio editor...")
	open_audio_editor()

# File browser functions
func open_file_browser():
	var file_browser = file_browser_scene.instantiate()
	ui_layer.add_child(file_browser)
	file_browser.file_selected.connect(_on_file_selected)
	file_browser.closed.connect(_on_file_browser_closed)

func _on_file_selected(path: String):
	print("Loading level: ", path)
	if load_level_from_json(path):
		current_filename = path.get_file()
		if status_label:
			status_label.text = "Loaded: " + current_filename

func _on_file_browser_closed():
	print("File browser closed")

# Audio editor functions
func open_audio_editor():
	var audio_editor_scene = load("res://scenes/level_editor/AudioEditor.tscn")
	var audio_editor = audio_editor_scene.instantiate()
	ui_layer.add_child(audio_editor)
	audio_editor.closed.connect(_on_audio_editor_closed)
	audio_editor.pattern_saved.connect(_on_audio_pattern_saved)
	
	# Set level information
	print("[LevelEditor] Debug - current_filename: '", current_filename, "'")
	var level_name = current_filename.get_basename() if current_filename != "" else "Untitled Level"
	audio_editor.set_level_info(level_name)
	print("[LevelEditor] Opening AudioEditor for level: ", level_name)
	
	# Load existing audio pattern if available (after a frame to ensure UI is ready)
	if level_audio_pattern:
		print("[LevelEditor] Loading existing pattern into AudioEditor...")
		# Wait a frame for AudioEditor UI to be fully initialized
		await get_tree().process_frame
		audio_editor.load_pattern_data(level_audio_pattern)
	else:
		print("[LevelEditor] No existing pattern found for this level")

func _on_audio_editor_closed():
	print("Audio editor closed")

func _on_audio_pattern_saved(pattern_data):
	print("[LevelEditor] Audio pattern received from AudioEditor:")
	print("  Level: ", pattern_data.get("level_name", "Unknown"))
	print("  BPM: ", pattern_data.bpm)
	print("  Theme: ", pattern_data.theme)
	print("  Pattern tracks: ", pattern_data.patterns.keys())
	
	# Store the pattern data for level saving
	level_audio_pattern = pattern_data
	
	# Update status
	if status_label:
		status_label.text = "Audio pattern saved (BPM: %d, Theme: %s)" % [pattern_data.bpm, pattern_data.theme]
	
	print("[LevelEditor] ✓ Audio pattern stored in level data")
