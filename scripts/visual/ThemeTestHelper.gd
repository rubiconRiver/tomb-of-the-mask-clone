extends Node

# Theme Test Helper - Utility functions for testing visual themes

# Create a simple test scene to preview themes
static func create_theme_preview() -> Node2D:
	var preview = Node2D.new()
	preview.name = "ThemePreview"
	
	# Background
	var bg = TextureRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.stretch_mode = TextureRect.STRETCH_TILE
	var bg_texture = VisualThemeManager.get_background_texture()
	if bg_texture:
		bg.texture = bg_texture
	else:
		bg.color = Color(0.05, 0.05, 0.1)  # Default dark blue
	preview.add_child(bg)
	
	# Wall example
	var wall = Sprite2D.new()
	wall.position = Vector2(100, 100)
	var wall_texture = VisualThemeManager.get_wall_texture()
	if wall_texture:
		wall.texture = wall_texture
	else:
		wall.texture = create_fallback_texture(Vector2i(64, 64), Color(0.4, 0.4, 0.4))
	preview.add_child(wall)
	
	# Player example
	var player = Sprite2D.new()
	player.position = Vector2(200, 100)
	var player_texture = VisualThemeManager.get_player_texture()
	if player_texture:
		player.texture = player_texture
	else:
		player.texture = create_fallback_texture(Vector2i(48, 48), Color(0.58, 0.98, 0.90))
	preview.add_child(player)
	
	# Coin example
	var coin = Sprite2D.new()
	coin.position = Vector2(300, 100)
	var coin_texture = VisualThemeManager.get_coin_texture()
	if coin_texture:
		coin.texture = coin_texture
	else:
		coin.texture = create_fallback_texture(Vector2i(32, 32), Color(1.0, 1.0, 0.0))
	preview.add_child(coin)
	
	# Goal example
	var goal = Sprite2D.new()
	goal.position = Vector2(400, 100)
	var goal_texture = VisualThemeManager.get_goal_texture()
	if goal_texture:
		goal.texture = goal_texture
	else:
		goal.texture = create_fallback_texture(Vector2i(64, 64), Color(0.2, 0.5, 1.0))
	preview.add_child(goal)
	
	return preview

# Create a fallback colored texture
static func create_fallback_texture(size: Vector2i, color: Color) -> ImageTexture:
	var image = Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	image.fill(color)
	var texture = ImageTexture.new()
	texture.set_image(image)
	return texture

# Print theme information
static func print_theme_info():
	print("\n=== VISUAL THEME SYSTEM INFO ===")
	print("Current theme: ", VisualThemeManager.get_current_theme())
	print("Available themes: ", VisualThemeManager.get_available_themes())
	
	print("\nLoaded textures:")
	var categories = ["environment", "objects", "ui", "effects"]
	var assets = {
		"environment": ["background", "wall"],
		"objects": ["coin", "goal", "player", "player_spawn"],
		"ui": ["button", "panel"],
		"effects": ["particle", "explosion"]
	}
	
	for category in categories:
		print("  " + category + ":")
		for asset in assets[category]:
			var texture = VisualThemeManager.get_texture(category, asset)
			var status = "✓" if texture else "✗"
			print("    ", status, " ", asset)

# Test theme switching
static func test_theme_switching():
	print("\n=== TESTING THEME SWITCHING ===")
	var available_themes = VisualThemeManager.get_available_themes()
	
	for theme in available_themes:
		print("Testing theme: ", theme)
		var success = VisualThemeManager.switch_theme(theme)
		print("  Result: ", "SUCCESS" if success else "FAILED")
		
		if success:
			print("  Current theme: ", VisualThemeManager.get_current_theme())

# Create example theme structure (for demonstration)
static func create_example_theme_structure():
	print("\n=== CREATING EXAMPLE THEME STRUCTURE ===")
	var base_path = "user://example_theme/"
	
	# Create directories
	var dirs = [
		"environment/",
		"objects/",
		"ui/",
		"effects/"
	]
	
	var dir = DirAccess.open("user://")
	for path in dirs:
		var full_path = base_path + path
		dir.make_dir_recursive(full_path)
		print("Created directory: ", full_path)
	
	print("Example theme structure created at: ", base_path)
	print("Add your PNG files to these directories to create a custom theme!")