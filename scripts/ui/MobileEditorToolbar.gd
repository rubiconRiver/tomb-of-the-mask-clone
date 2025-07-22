extends CanvasLayer
class_name MobileEditorToolbar

# ============================================
# MOBILE-FRIENDLY LEVEL EDITOR TOOLBAR
# ============================================

@onready var current_tile_label = $TopToolbar/CurrentTileLabel
@onready var save_button = $TopToolbar/SaveButton
@onready var load_button = $TopToolbar/LoadButton
@onready var test_button = $TopToolbar/TestButton
@onready var clear_button = $TopToolbar/ClearButton
@onready var menu_button = $TopToolbar/MenuButton

# Tile buttons
@onready var wall_button = $BottomToolbar/TileButtons/WallButton
@onready var coin_button = $BottomToolbar/TileButtons/CoinButton
@onready var spike_button = $BottomToolbar/TileButtons/SpikeButton
@onready var player_button = $BottomToolbar/TileButtons/PlayerButton
@onready var goal_button = $BottomToolbar/TileButtons/GoalButton
@onready var waypoint_button = $BottomToolbar/TileButtons/WaypointButton
@onready var eraser_button = $BottomToolbar/TileButtons/EraserButton

# Zoom controls
@onready var zoom_in_button = $BottomToolbar/ZoomControls/ZoomInButton
@onready var zoom_out_button = $BottomToolbar/ZoomControls/ZoomOutButton
@onready var touch_hint = $TouchHint

var level_editor: LevelEditor
var tile_buttons: Array[Button] = []

# Mobile touch states
var is_painting = false
var paint_start_time = 0.0
var long_press_threshold = 0.5  # Seconds for long press to erase

func _ready():
	setup_mobile_toolbar()
	connect_signals()
	collect_tile_buttons()
	hide_touch_hint_after_delay()

func setup_mobile_toolbar():
	# Find the level editor
	level_editor = get_tree().get_first_node_in_group("level_editor")
	if not level_editor:
		level_editor = get_parent()  # Assume parent is level editor
	
	# Style buttons with synthwave theme
	style_all_buttons()

func style_all_buttons():
	var buttons = [
		save_button, load_button, test_button, clear_button, menu_button,
		wall_button, coin_button, spike_button, player_button, goal_button,
		waypoint_button, eraser_button, zoom_in_button, zoom_out_button
	]
	
	for button in buttons:
		if button:
			style_button(button, false)

func style_button(button: Button, is_selected: bool):
	var style_normal = StyleBoxFlat.new()
	var style_pressed = StyleBoxFlat.new()
	
	# Set corner radius
	for style in [style_normal, style_pressed]:
		style.corner_radius_top_left = 6
		style.corner_radius_top_right = 6
		style.corner_radius_bottom_left = 6
		style.corner_radius_bottom_right = 6
		style.border_width_left = 2
		style.border_width_top = 2
		style.border_width_right = 2
		style.border_width_bottom = 2
	
	if is_selected:
		# Selected tile - cyan glow
		style_normal.bg_color = Color("#94fbe6", 0.4)
		style_normal.border_color = Color("#94fbe6")
		style_pressed.bg_color = Color("#94fbe6", 0.6)
		style_pressed.border_color = Color("#94fbe6")
	else:
		# Normal button - subtle yellow
		style_normal.bg_color = Color("#dcfb94", 0.2)
		style_normal.border_color = Color("#dcfb94", 0.6)
		style_pressed.bg_color = Color("#dcfb94", 0.4)
		style_pressed.border_color = Color("#dcfb94")
	
	button.add_theme_stylebox_override("normal", style_normal)
	button.add_theme_stylebox_override("pressed", style_pressed)

func collect_tile_buttons():
	tile_buttons = [
		wall_button, coin_button, spike_button, player_button,
		goal_button, waypoint_button, eraser_button
	]

func connect_signals():
	# Top toolbar
	if save_button:
		save_button.pressed.connect(_on_save_pressed)
	if load_button:
		load_button.pressed.connect(_on_load_pressed)
	if test_button:
		test_button.pressed.connect(_on_test_pressed)
	if clear_button:
		clear_button.pressed.connect(_on_clear_pressed)
	if menu_button:
		menu_button.pressed.connect(_on_menu_pressed)
	
	# Tile buttons
	if wall_button:
		wall_button.pressed.connect(_on_tile_selected.bind(0))  # WALL
	if coin_button:
		coin_button.pressed.connect(_on_tile_selected.bind(1))  # COIN
	if spike_button:
		spike_button.pressed.connect(_on_tile_selected.bind(2))  # SPIKE
	if player_button:
		player_button.pressed.connect(_on_tile_selected.bind(3))  # PLAYER_SPAWN
	if goal_button:
		goal_button.pressed.connect(_on_tile_selected.bind(4))  # GOAL
	if waypoint_button:
		waypoint_button.pressed.connect(_on_tile_selected.bind(5))  # WAYPOINT
	if eraser_button:
		eraser_button.pressed.connect(_on_tile_selected.bind(-1))  # EMPTY (eraser)
	
	# Zoom controls
	if zoom_in_button:
		zoom_in_button.pressed.connect(_on_zoom_in_pressed)
	if zoom_out_button:
		zoom_out_button.pressed.connect(_on_zoom_out_pressed)

func hide_touch_hint_after_delay():
	await get_tree().create_timer(5.0).timeout
	if touch_hint:
		var tween = create_tween()
		tween.tween_property(touch_hint, "modulate", Color.TRANSPARENT, 1.0)

# Signal handlers
func _on_save_pressed():
	if level_editor and level_editor.has_method("save_level"):
		level_editor.save_level()

func _on_load_pressed():
	if level_editor and level_editor.has_method("load_level"):
		level_editor.load_level()

func _on_test_pressed():
	if level_editor and level_editor.has_method("test_level"):
		level_editor.test_level()

func _on_clear_pressed():
	if level_editor and level_editor.has_method("clear_level"):
		level_editor.clear_level()

func _on_menu_pressed():
	print("[MobileEditorToolbar] Returning to main menu")
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _on_tile_selected(tile_type: int):
	if level_editor:
		level_editor.current_tile_type = tile_type
		update_current_tile_display(tile_type)
		update_button_selection(tile_type)

func _on_zoom_in_pressed():
	if level_editor and level_editor.camera:
		level_editor.camera.zoom *= 1.2
		level_editor.camera.zoom = level_editor.camera.zoom.clamp(Vector2(0.5, 0.5), Vector2(3.0, 3.0))

func _on_zoom_out_pressed():
	if level_editor and level_editor.camera:
		level_editor.camera.zoom *= 0.8
		level_editor.camera.zoom = level_editor.camera.zoom.clamp(Vector2(0.5, 0.5), Vector2(3.0, 3.0))

func update_current_tile_display(tile_type: int):
	if not current_tile_label:
		return
	
	var tile_names = {
		-1: "Eraser",
		0: "Wall",
		1: "Coin",
		2: "Spike", 
		3: "Player Spawn",
		4: "Goal",
		5: "Waypoint"
	}
	
	current_tile_label.text = "Current: " + tile_names.get(tile_type, "Unknown")

func update_button_selection(selected_tile_type: int):
	var type_to_button = {
		0: wall_button,
		1: coin_button,
		2: spike_button,
		3: player_button,
		4: goal_button,
		5: waypoint_button,
		-1: eraser_button
	}
	
	# Reset all buttons to normal style
	for button in tile_buttons:
		if button:
			style_button(button, false)
	
	# Highlight selected button
	var selected_button = type_to_button.get(selected_tile_type)
	if selected_button:
		style_button(selected_button, true)

# Mobile touch handling for tile placement
func _input(event):
	if event is InputEventScreenTouch or event is InputEventMouseButton:
		handle_touch_input(event)
	elif event is InputEventScreenDrag or event is InputEventMouseMotion:
		handle_drag_input(event)

func handle_touch_input(event):
	var is_touch_start = (event is InputEventScreenTouch and event.pressed) or \
						(event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT)
	var is_touch_end = (event is InputEventScreenTouch and not event.pressed) or \
					   (event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT)
	
	if is_touch_start:
		is_painting = true
		paint_start_time = Time.get_ticks_msec() / 1000.0
		place_tile_at_position(event.position)
	elif is_touch_end:
		var paint_duration = (Time.get_ticks_msec() / 1000.0) - paint_start_time
		
		# Check for long press (erase mode)
		if paint_duration >= long_press_threshold and level_editor:
			# Long press - temporarily switch to eraser
			var original_tile = level_editor.current_tile_type
			level_editor.current_tile_type = -1  # EMPTY (eraser)
			place_tile_at_position(event.position)
			level_editor.current_tile_type = original_tile  # Restore
		
		is_painting = false

func handle_drag_input(event):
	if is_painting:
		place_tile_at_position(event.position)

func place_tile_at_position(screen_position: Vector2):
	if not level_editor:
		return
	
	# Convert screen position to world position, then to grid coordinates
	var world_pos = level_editor.camera.get_global_mouse_position() if level_editor.camera else screen_position
	var grid_pos = Vector2i(world_pos / level_editor.GRID_SIZE)
	
	# Call level editor's place tile function
	if level_editor.has_method("place_tile"):
		level_editor.place_tile(grid_pos, level_editor.current_tile_type)