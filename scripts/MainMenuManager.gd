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
	print("[MainMenu] MainMenuManager starting initialization...")
	setup_synthwave_styling()
	setup_grid_background()
	connect_signals()
	load_player_data()
	create_level_grid()
	start_background_animations()
	print("[MainMenu] MainMenuManager initialization complete!")

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
	# Simplified background for testing - just set a subtle pattern later
	print("[MainMenu] Grid background setup complete")

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
	print("[MainMenu] Creating level grid with ", total_levels, " levels")
	
	if not level_grid:
		print("[MainMenu] ERROR: level_grid node not found!")
		return
	
	# Clear existing level buttons
	for child in level_grid.get_children():
		child.queue_free()
	
	# Create level buttons
	for level_num in range(1, total_levels + 1):
		create_level_button(level_num)
	
	print("[MainMenu] Level grid created successfully")

func create_level_button(level_num: int):
	var level_button = TextureButton.new()  # Use TextureButton for better thumbnail display
	level_button.custom_minimum_size = Vector2(120, 120)  # Larger for better visibility
	level_button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	level_button.ignore_texture_size = true
	
	# Get data from GameData singleton
	var is_unlocked = GameData.is_level_unlocked(level_num)
	var is_completed = GameData.is_level_completed(level_num)
	var stars = GameData.get_level_stars(level_num)
	
	# Check for level thumbnail
	var level_name = "%03d" % level_num  # Format as 001, 002, etc.
	# First check user:// directory (for runtime-generated thumbnails)
	var user_thumbnail_path = "user://%s_thumbnail.png" % level_name
	var res_thumbnail_path = "res://levels/%s_thumbnail.png" % level_name
	
	# Create button content with thumbnail
	var thumbnail_texture = null
	
	# Try user directory first (for editor-generated thumbnails)
	print("[MainMenu] Checking for thumbnail: ", user_thumbnail_path)
	if FileAccess.file_exists(user_thumbnail_path):
		print("[MainMenu] Found user thumbnail, loading...")
		var img = Image.new()
		if img.load(user_thumbnail_path) == OK:
			thumbnail_texture = ImageTexture.create_from_image(img)
			print("[MainMenu] ✓ User thumbnail loaded successfully")
		else:
			print("[MainMenu] ✗ Failed to load user thumbnail")
	# Then try res directory (for pre-packaged thumbnails)
	elif FileAccess.file_exists(res_thumbnail_path):
		print("[MainMenu] Found res thumbnail, loading...")
		thumbnail_texture = load(res_thumbnail_path)
		if thumbnail_texture:
			print("[MainMenu] ✓ Res thumbnail loaded successfully")
		else:
			print("[MainMenu] ✗ Failed to load res thumbnail")
	else:
		print("[MainMenu] No thumbnail found at:")
		print("  User: ", user_thumbnail_path)
		print("  Res: ", res_thumbnail_path)
	
	# If no thumbnail, create a simple placeholder
	if not thumbnail_texture:
		print("[MainMenu] Creating placeholder for level ", level_num)
		var img = Image.create(128, 128, false, Image.FORMAT_RGBA8)
		img.fill(Color(0.1, 0.1, 0.2))  # Dark blue background
		
		# Draw a simple border
		for i in range(128):
			img.set_pixel(i, 0, Color(0.5, 0.5, 0.5))  # Top border
			img.set_pixel(i, 127, Color(0.5, 0.5, 0.5))  # Bottom border
			img.set_pixel(0, i, Color(0.5, 0.5, 0.5))  # Left border
			img.set_pixel(127, i, Color(0.5, 0.5, 0.5))  # Right border
		
		# Draw level number text area
		for y in range(50, 78):
			for x in range(50, 78):
				img.set_pixel(x, y, Color(0.3, 0.3, 0.3))
		
		thumbnail_texture = ImageTexture.create_from_image(img)
	
	# Apply thumbnail
	level_button.texture_normal = thumbnail_texture
	
	# Create overlay for level number and state
	var overlay_container = Control.new()
	overlay_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	level_button.add_child(overlay_container)
	
	# Level number label with background
	var number_bg = Panel.new()
	number_bg.custom_minimum_size = Vector2(40, 30)
	number_bg.position = Vector2(5, 5)
	var number_style = StyleBoxFlat.new()
	number_style.bg_color = Color(0, 0, 0, 0.7)
	number_style.corner_radius_top_left = 4
	number_style.corner_radius_top_right = 4
	number_style.corner_radius_bottom_left = 4
	number_style.corner_radius_bottom_right = 4
	number_bg.add_theme_stylebox_override("panel", number_style)
	overlay_container.add_child(number_bg)
	
	var number_label = Label.new()
	number_label.text = str(level_num)
	number_label.add_theme_font_size_override("font_size", 18)
	number_label.add_theme_color_override("font_color", Color.WHITE)
	number_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	number_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	number_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	number_bg.add_child(number_label)
	
	# Stars display if completed
	if is_completed and stars > 0:
		var stars_label = Label.new()
		stars_label.text = "★".repeat(stars)
		stars_label.add_theme_font_size_override("font_size", 16)
		stars_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.0))
		stars_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
		stars_label.position = Vector2(-35, -25)
		overlay_container.add_child(stars_label)
	
	# Apply state-based styling
	if is_completed:
		# Completed level - cyan border glow
		level_button.modulate = Color(0.9, 1.0, 1.0)
	elif is_unlocked:
		# Unlocked but not completed - normal
		level_button.modulate = Color.WHITE
	else:
		# Locked level - dim
		level_button.modulate = Color(0.4, 0.4, 0.4)
		level_button.disabled = true
		
		# Add lock icon
		var lock_label = Label.new()
		lock_label.text = "🔒"
		lock_label.add_theme_font_size_override("font_size", 32)
		lock_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		overlay_container.add_child(lock_label)
	
	# Connect signal
	level_button.pressed.connect(_on_level_selected.bind(level_num))
	
	level_grid.add_child(level_button)

func start_background_animations():
	# Animate promo section glow
	start_neon_glow_animation()

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