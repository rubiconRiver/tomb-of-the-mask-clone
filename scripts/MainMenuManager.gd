extends Control
class_name MainMenuManager

# ============================================
# SYNTHWAVE MAIN MENU MANAGER
# ============================================

# References to UI elements
@onready var player_level_label = $VBoxContainer/TopBanner/PlayerInfo/PlayerLevel
@onready var score_value = $VBoxContainer/TopBanner/StatsContainer/ScoreContainer/ScoreValue
@onready var coins_value = $VBoxContainer/TopBanner/StatsContainer/CoinsContainer/CoinsValue
@onready var stars_value = $VBoxContainer/TopBanner/StatsContainer/StarsContainer/StarsValue
@onready var level_grid = $VBoxContainer/LevelMapSection/ScrollContainer/LevelGrid
@onready var promo_section = $VBoxContainer/PromoSection
@onready var grid_pattern = $Background/GridPattern

# Button references
@onready var play_now_button = $VBoxContainer/PromoSection/PromoContent/PlayNowButton
@onready var shop_button = $VBoxContainer/TopBanner/TopButtons/ShopButton
@onready var settings_button = $VBoxContainer/TopBanner/TopButtons/SettingsButton
@onready var editor_button = $VBoxContainer/BottomToolbar/EditorButton
@onready var achievements_button = $VBoxContainer/BottomToolbar/AchievementsButton
@onready var stats_button = $VBoxContainer/BottomToolbar/StatsButton
@onready var quit_button = $VBoxContainer/BottomToolbar/QuitButton

# Game data
var total_levels = 20

# Level button scene
var level_button_scene = preload("res://scenes/ui/LevelButton.tscn")

# Visual effects
var neon_glow_tween: Tween
var grid_animation_time = 0.0

func _ready():
	setup_synthwave_styling()
	setup_grid_background()
	connect_signals()
	load_player_data()
	create_level_grid()
	start_background_animations()

func setup_synthwave_styling():
	# Set up the neon color scheme
	var cyan = Color("#94fbe6")  # Your character color
	var magenta = Color("#fb94dc")  # Pink accent
	var yellow = Color("#dcfb94")  # Wall/accent color
	
	# Style the promo section with neon border
	if promo_section:
		var style_box = StyleBoxFlat.new()
		style_box.bg_color = Color(0.05, 0.05, 0.1, 0.8)
		style_box.border_width_left = 2
		style_box.border_width_top = 2
		style_box.border_width_right = 2
		style_box.border_width_bottom = 2
		style_box.border_color = cyan
		style_box.corner_radius_top_left = 8
		style_box.corner_radius_top_right = 8
		style_box.corner_radius_bottom_left = 8
		style_box.corner_radius_bottom_right = 8
		promo_section.add_theme_stylebox_override("panel", style_box)

func setup_grid_background():
	# Create the synthwave grid pattern
	if grid_pattern:
		grid_pattern.draw.connect(_draw_grid_pattern)

func _draw_grid_pattern():
	var size = get_viewport().get_visible_rect().size
	var grid_size = 64
	var line_color = Color("#94fbe6", 0.15)  # Semi-transparent cyan
	
	# Draw vertical lines
	for x in range(0, int(size.x), grid_size):
		grid_pattern.draw_line(Vector2(x, 0), Vector2(x, size.y), line_color, 1)
	
	# Draw horizontal lines
	for y in range(0, int(size.y), grid_size):
		grid_pattern.draw_line(Vector2(0, y), Vector2(size.x, y), line_color, 1)

func connect_signals():
	# Connect button signals
	if play_now_button:
		play_now_button.pressed.connect(_on_play_now_pressed)
	if shop_button:
		shop_button.pressed.connect(_on_shop_pressed)
	if settings_button:
		settings_button.pressed.connect(_on_settings_pressed)
	if editor_button:
		editor_button.pressed.connect(_on_editor_pressed)
	if achievements_button:
		achievements_button.pressed.connect(_on_achievements_pressed)
	if stats_button:
		stats_button.pressed.connect(_on_stats_pressed)
	if quit_button:
		quit_button.pressed.connect(_on_quit_pressed)
	
	# Connect GameData signals
	GameData.player_data_updated.connect(_on_player_data_updated)
	GameData.level_completed.connect(_on_level_completed)

func load_player_data():
	# Data is managed by GameData singleton
	update_ui()

func update_ui():
	# Update all UI elements with GameData
	if player_level_label:
		player_level_label.text = "LVL " + str(GameData.get_player_level())
	
	if score_value:
		score_value.text = str(GameData.get_total_score())
	
	if coins_value:
		coins_value.text = str(GameData.get_total_coins())
	
	if stars_value:
		var max_stars = total_levels * 3  # Assuming 3 stars per level
		stars_value.text = str(GameData.get_total_stars()) + "/" + str(max_stars)

func create_level_grid():
	# Clear existing level buttons
	for child in level_grid.get_children():
		child.queue_free()
	
	# Create level buttons
	for level_num in range(1, total_levels + 1):
		create_level_button(level_num)

func create_level_button(level_num: int):
	var level_button = Button.new()
	level_button.text = str(level_num)
	level_button.custom_minimum_size = Vector2(80, 80)
	
	# Get data from GameData singleton
	var is_unlocked = GameData.is_level_unlocked(level_num)
	var is_completed = GameData.is_level_completed(level_num)
	var stars = GameData.get_level_stars(level_num)
	
	# Create synthwave styling
	var style_box = StyleBoxFlat.new()
	style_box.corner_radius_top_left = 8
	style_box.corner_radius_top_right = 8
	style_box.corner_radius_bottom_left = 8
	style_box.corner_radius_bottom_right = 8
	
	if is_completed:
		# Completed level - cyan with glow
		style_box.bg_color = Color("#94fbe6", 0.3)
		style_box.border_color = Color("#94fbe6")
		level_button.modulate = Color.WHITE
	elif is_unlocked:
		# Unlocked but not completed - yellow
		style_box.bg_color = Color("#dcfb94", 0.2)
		style_box.border_color = Color("#dcfb94")
		level_button.modulate = Color.WHITE
	else:
		# Locked level - dim
		style_box.bg_color = Color(0.1, 0.1, 0.1, 0.5)
		style_box.border_color = Color(0.3, 0.3, 0.3, 0.5)
		level_button.modulate = Color(0.5, 0.5, 0.5, 0.7)
		level_button.disabled = true
	
	style_box.border_width_left = 2
	style_box.border_width_top = 2
	style_box.border_width_right = 2
	style_box.border_width_bottom = 2
	
	level_button.add_theme_stylebox_override("normal", style_box)
	
	# Add star rating if completed
	if is_completed and stars > 0:
		level_button.text = str(level_num) + "\n" + "★".repeat(stars)
	
	# Connect signal
	level_button.pressed.connect(_on_level_selected.bind(level_num))
	
	level_grid.add_child(level_button)

func start_background_animations():
	# Animate grid pattern
	var grid_tween = create_tween()
	grid_tween.set_loops()
	grid_tween.tween_method(_update_grid_animation, 0.0, TAU, 4.0)
	
	# Animate promo section glow
	start_neon_glow_animation()

func _update_grid_animation(value: float):
	grid_animation_time = value
	if grid_pattern:
		grid_pattern.queue_redraw()

func start_neon_glow_animation():
	# Animate the promo section border to pulse
	if neon_glow_tween:
		neon_glow_tween.kill()
	
	neon_glow_tween = create_tween()
	neon_glow_tween.set_loops()
	neon_glow_tween.tween_method(_update_neon_glow, 0.3, 1.0, 1.5)
	neon_glow_tween.tween_method(_update_neon_glow, 1.0, 0.3, 1.5)

func _update_neon_glow(alpha: float):
	# Update glow effect on promo section
	if promo_section:
		promo_section.modulate = Color(1.0, 1.0, 1.0, alpha)

# Button signal handlers
func _on_play_now_pressed():
	HapticFeedback.on_button_press()
	print("[MainMenu] Play Now pressed - starting game")
	# Find the next available level or start level 1
	var next_level = 1
	for level in range(1, GameData.get_unlocked_levels() + 1):
		if not GameData.is_level_completed(level):
			next_level = level
			break
	
	start_level(next_level)

func _on_level_selected(level_num: int):
	HapticFeedback.on_menu_navigation()
	print("[MainMenu] Level ", level_num, " selected")
	if GameData.is_level_unlocked(level_num):
		start_level(level_num)
	else:
		HapticFeedback.on_error()  # Locked level feedback

func _on_shop_pressed():
	HapticFeedback.on_button_press()
	print("[MainMenu] Shop pressed - opening shop")
	# TODO: Implement shop

func _on_settings_pressed():
	HapticFeedback.on_button_press()
	print("[MainMenu] Settings pressed - opening settings")
	# TODO: Implement settings menu

func _on_editor_pressed():
	HapticFeedback.on_button_press()
	print("[MainMenu] Level Editor pressed")
	# Load level editor
	get_tree().change_scene_to_file("res://scenes/level_editor/LevelEditor.tscn")

func _on_achievements_pressed():
	HapticFeedback.on_button_press()
	print("[MainMenu] Achievements pressed")
	# TODO: Implement achievements

func _on_stats_pressed():
	HapticFeedback.on_button_press()
	print("[MainMenu] Stats pressed")
	# TODO: Implement stats screen

func _on_quit_pressed():
	HapticFeedback.on_button_press()
	print("[MainMenu] Quit pressed")
	get_tree().quit()

func start_level(level_num: int):
	print("[MainMenu] Starting level ", level_num)
	
	# Tell GameData which level we're starting
	GameData.start_level(level_num)
	
	# Switch to the main game scene
	get_tree().change_scene_to_file("res://scenes/main.tscn")

# GameData signal handlers
func _on_player_data_updated():
	print("[MainMenu] Player data updated - refreshing UI")
	update_ui()
	create_level_grid()

func _on_level_completed(level_number: int, score: int, stars: int):
	print("[MainMenu] Level ", level_number, " completed with ", stars, " stars!")
	# UI will be updated by _on_player_data_updated

func _process(delta):
	# Update any continuous animations
	# Check if returning from game to potentially show celebration
	if GameData.is_returning_from_game():
		print("[MainMenu] Player returned from game - showing updated progress")
		GameData.returning_from_game = false  # Reset flag

# Mobile-friendly input handling
func _input(event):
	# Handle swipe gestures on level grid for scrolling
	if event is InputEventScreenDrag or (event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)):
		handle_scroll_gesture(event)

func handle_scroll_gesture(event):
	# Enable smooth scrolling on level grid with touch/drag
	var scroll_container = level_grid.get_parent() if level_grid else null
	if scroll_container and scroll_container is ScrollContainer:
		var relative_motion = Vector2.ZERO
		
		if event is InputEventScreenDrag:
			relative_motion = -event.relative * 2.0  # Invert and amplify for natural scrolling
		elif event is InputEventMouseMotion:
			relative_motion = -event.relative * 1.5
		
		# Apply scrolling
		var current_scroll = scroll_container.scroll_vertical
		scroll_container.scroll_vertical = max(0, current_scroll + relative_motion.y)