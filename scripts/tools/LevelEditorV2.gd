extends Node2D
class_name LevelEditorV2

const GRID_SIZE = 64

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

# Tile data for UI
const TILE_DATA = {
	TileType.WALL: {"name": "Wall", "color": Color(0.5, 0.5, 0.5), "icon": "▓"},
	TileType.COIN: {"name": "Coin", "color": Color(1.0, 1.0, 0.0), "icon": "◉"},
	TileType.SPIKE: {"name": "Spike", "color": Color(1.0, 0.2, 0.2), "icon": "▲"},
	TileType.PLAYER_SPAWN: {"name": "Player", "color": Color(0.2, 1.0, 0.2), "icon": "P"},
	TileType.GOAL: {"name": "Goal", "color": Color(0.2, 0.2, 1.0), "icon": "★"}
}

# Current state
var level_size = SIZE_PRESETS["Small"]
var current_tile_type = TileType.WALL
var zoom_level = 1.0
var is_panning = false
var pan_start_pos = Vector2.ZERO

# Nodes
var tilemap: TileMap
var cursor_preview: Node2D
var camera: Camera2D
var toolbar: Control
var status_bar: Label
var minimap: Control

func _ready():
	get_window().size = Vector2i(1400, 900)
	get_window().position = Vector2i(100, 100)
	
	setup_tilemap()
	setup_camera()
	setup_cursor_preview()
	setup_ui()
	
	clear_level()

func setup_tilemap():
	tilemap = TileMap.new()
	tilemap.tile_set = create_tileset()
	add_child(tilemap)

func create_tileset() -> TileSet:
	var tileset = TileSet.new()
	tileset.tile_size = Vector2i(GRID_SIZE, GRID_SIZE)
	
	var atlas_source = TileSetAtlasSource.new()
	
	# Create texture with tiles
	var image = Image.create(320, 64, false, Image.FORMAT_RGBA8)
	
	# Draw each tile
	for i in range(5):
		var tile_type = i as TileType
		var color = TILE_DATA[tile_type].color
		var rect = Rect2i(i * 64, 0, 64, 64)
		
		# Fill tile
		image.fill_rect(rect, color)
		
		# Add border
		for x in range(64):
			image.set_pixel(rect.position.x + x, rect.position.y, color * 0.7)
			image.set_pixel(rect.position.x + x, rect.position.y + 63, color * 0.7)
		for y in range(64):
			image.set_pixel(rect.position.x, rect.position.y + y, color * 0.7)
			image.set_pixel(rect.position.x + 63, rect.position.y + y, color * 0.7)
	
	var texture = ImageTexture.create_from_image(image)
	atlas_source.texture = texture
	atlas_source.texture_region_size = Vector2i(64, 64)
	
	for i in range(5):
		atlas_source.create_tile(Vector2i(i, 0))
	
	tileset.add_source(atlas_source, 0)
	return tileset

func setup_camera():
	camera = Camera2D.new()
	camera.position = Vector2(level_size.x * GRID_SIZE / 2, level_size.y * GRID_SIZE / 2)
	add_child(camera)
	camera.make_current()

func setup_cursor_preview():
	cursor_preview = Node2D.new()
	add_child(cursor_preview)
	cursor_preview.z_index = 10
	
	# Create preview sprite
	var preview_rect = ColorRect.new()
	preview_rect.size = Vector2(GRID_SIZE, GRID_SIZE)
	preview_rect.modulate = Color(1, 1, 1, 0.5)
	preview_rect.position = -Vector2(GRID_SIZE/2, GRID_SIZE/2)
	cursor_preview.add_child(preview_rect)
	
	# Store reference
	cursor_preview.set_meta("rect", preview_rect)

func setup_ui():
	# Create UI layer
	var ui_layer = CanvasLayer.new()
	add_child(ui_layer)
	
	# Toolbar at top
	toolbar = PanelContainer.new()
	toolbar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	toolbar.custom_minimum_size = Vector2(0, 80)
	ui_layer.add_child(toolbar)
	
	var toolbar_margin = MarginContainer.new()
	toolbar_margin.add_theme_constant_override("margin_left", 10)
	toolbar_margin.add_theme_constant_override("margin_right", 10)
	toolbar_margin.add_theme_constant_override("margin_top", 10)
	toolbar_margin.add_theme_constant_override("margin_bottom", 10)
	toolbar.add_child(toolbar_margin)
	
	var toolbar_hbox = HBoxContainer.new()
	toolbar_hbox.add_theme_constant_override("separation", 20)
	toolbar_margin.add_child(toolbar_hbox)
	
	# Tile buttons
	var tile_group = HBoxContainer.new()
	tile_group.add_theme_constant_override("separation", 5)
	toolbar_hbox.add_child(tile_group)
	
	var button_group = ButtonGroup.new()
	
	for tile_type in [TileType.WALL, TileType.COIN, TileType.SPIKE, TileType.PLAYER_SPAWN, TileType.GOAL]:
		var btn = create_tile_button(tile_type, button_group)
		tile_group.add_child(btn)
		if tile_type == TileType.WALL:
			btn.button_pressed = true
	
	# Separator
	toolbar_hbox.add_child(VSeparator.new())
	
	# Tools
	var tools_group = HBoxContainer.new()
	tools_group.add_theme_constant_override("separation", 5)
	toolbar_hbox.add_child(tools_group)
	
	# Eraser button
	var eraser_btn = Button.new()
	eraser_btn.text = "🗑️ Eraser"
	eraser_btn.toggle_mode = true
	eraser_btn.button_group = button_group
	eraser_btn.custom_minimum_size = Vector2(100, 60)
	eraser_btn.pressed.connect(func(): current_tile_type = TileType.EMPTY; update_cursor_preview())
	tools_group.add_child(eraser_btn)
	
	# Clear button
	var clear_btn = Button.new()
	clear_btn.text = "🔄 Clear"
	clear_btn.custom_minimum_size = Vector2(80, 60)
	clear_btn.pressed.connect(clear_level)
	tools_group.add_child(clear_btn)
	
	# Size button
	var size_btn = Button.new()
	size_btn.text = "📐 Size"
	size_btn.custom_minimum_size = Vector2(80, 60)
	size_btn.pressed.connect(cycle_size)
	tools_group.add_child(size_btn)
	
	# Status bar at bottom
	status_bar = Label.new()
	status_bar.add_theme_font_size_override("font_size", 16)
	status_bar.anchor_top = 1.0
	status_bar.anchor_bottom = 1.0
	status_bar.anchor_right = 1.0
	status_bar.offset_top = -40
	status_bar.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	status_bar.add_theme_constant_override("margin_left", 10)
	
	var status_bg = ColorRect.new()
	status_bg.color = Color(0, 0, 0, 0.7)
	status_bg.anchor_top = 1.0
	status_bg.anchor_bottom = 1.0
	status_bg.anchor_right = 1.0
	status_bg.offset_top = -40
	ui_layer.add_child(status_bg)
	ui_layer.add_child(status_bar)

func create_tile_button(tile_type: TileType, button_group: ButtonGroup) -> Button:
	var data = TILE_DATA[tile_type]
	var btn = Button.new()
	btn.text = data.icon + " " + data.name
	btn.toggle_mode = true
	btn.button_group = button_group
	btn.custom_minimum_size = Vector2(100, 60)
	btn.add_theme_color_override("font_color", data.color)
	btn.add_theme_color_override("font_pressed_color", data.color)
	btn.add_theme_color_override("font_hover_color", data.color * 1.2)
	btn.pressed.connect(func(): current_tile_type = tile_type; update_cursor_preview())
	return btn

func update_cursor_preview():
	if current_tile_type == TileType.EMPTY:
		cursor_preview.visible = false
	else:
		cursor_preview.visible = true
		var rect = cursor_preview.get_meta("rect") as ColorRect
		if current_tile_type in TILE_DATA:
			rect.color = TILE_DATA[current_tile_type].color
			rect.modulate = Color(1, 1, 1, 0.5)

func _process(_delta):
	# Update cursor preview position
	var mouse_pos = get_global_mouse_position()
	var grid_pos = world_to_grid(mouse_pos)
	cursor_preview.position = Vector2(grid_pos.x * GRID_SIZE + GRID_SIZE/2, grid_pos.y * GRID_SIZE + GRID_SIZE/2)
	
	# Update status bar
	if is_valid_grid_position(grid_pos):
		status_bar.text = " Position: (%d, %d) | Size: %dx%d | Zoom: %.1fx" % [grid_pos.x, grid_pos.y, level_size.x, level_size.y, zoom_level]
	else:
		status_bar.text = " Position: (out of bounds) | Size: %dx%d | Zoom: %.1fx" % [level_size.x, level_size.y, zoom_level]

func _input(event):
	# Mouse wheel zoom
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			zoom_level = clamp(zoom_level * 1.1, 0.25, 4.0)
			camera.zoom = Vector2(zoom_level, zoom_level)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			zoom_level = clamp(zoom_level / 1.1, 0.25, 4.0)
			camera.zoom = Vector2(zoom_level, zoom_level)
	
	# Middle mouse pan
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_MIDDLE:
		is_panning = event.pressed
		pan_start_pos = event.position
	
	if event is InputEventMouseMotion and is_panning:
		var delta = (event.position - pan_start_pos) / zoom_level
		camera.position -= delta
		pan_start_pos = event.position
	
	# Tile placement
	if event is InputEventMouseButton:
		var grid_pos = world_to_grid(get_global_mouse_position())
		
		if is_valid_grid_position(grid_pos) and event.pressed:
			if event.button_index == MOUSE_BUTTON_LEFT:
				place_tile(grid_pos, current_tile_type)
			elif event.button_index == MOUSE_BUTTON_RIGHT:
				place_tile(grid_pos, TileType.EMPTY)
	
	# Keyboard shortcuts
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_W, KEY_UP:
				camera.position.y -= GRID_SIZE / zoom_level
			KEY_S, KEY_DOWN:
				camera.position.y += GRID_SIZE / zoom_level
			KEY_A, KEY_LEFT:
				camera.position.x -= GRID_SIZE / zoom_level
			KEY_D, KEY_RIGHT:
				camera.position.x += GRID_SIZE / zoom_level

func world_to_grid(world_pos: Vector2) -> Vector2i:
	return Vector2i(int(world_pos.x / GRID_SIZE), int(world_pos.y / GRID_SIZE))

func is_valid_grid_position(grid_pos: Vector2i) -> bool:
	return grid_pos.x >= 0 and grid_pos.x < level_size.x and grid_pos.y >= 0 and grid_pos.y < level_size.y

func place_tile(grid_pos: Vector2i, tile_type: TileType):
	if tile_type == TileType.EMPTY:
		tilemap.set_cell(0, grid_pos, -1)
	else:
		tilemap.set_cell(0, grid_pos, 0, Vector2i(tile_type, 0))

func clear_level():
	# Clear all tiles
	for y in range(level_size.y):
		for x in range(level_size.x):
			tilemap.set_cell(0, Vector2i(x, y), -1)
	
	# Add border walls
	for y in range(level_size.y):
		for x in range(level_size.x):
			if x == 0 or x == level_size.x - 1 or y == 0 or y == level_size.y - 1:
				tilemap.set_cell(0, Vector2i(x, y), 0, Vector2i(TileType.WALL, 0))

func cycle_size():
	var preset_names = SIZE_PRESETS.keys()
	var current_preset = "Small"
	
	for preset_name in preset_names:
		var size = SIZE_PRESETS[preset_name]
		if size == level_size:
			current_preset = preset_name
			break
	
	var current_index = preset_names.find(current_preset)
	var next_index = (current_index + 1) % preset_names.size()
	var next_preset = preset_names[next_index]
	
	level_size = SIZE_PRESETS[next_preset]
	clear_level()
	camera.position = Vector2(level_size.x * GRID_SIZE / 2, level_size.y * GRID_SIZE / 2)