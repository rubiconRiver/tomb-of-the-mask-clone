extends Node

# Default Asset Generator - Creates fallback visual assets programmatically
# This ensures the game works even without custom theme images

# Generate default visual assets for a theme
static func generate_default_assets(theme_name: String = "default"):
	print("[DefaultAssetGenerator] Generating default assets for theme: ", theme_name)
	
	var theme_path = "user://visuals/" + theme_name + "/"
	
	# Create directory structure
	_create_directories(theme_path)
	
	# Generate assets
	_generate_environment_assets(theme_path)
	_generate_object_assets(theme_path)
	_generate_ui_assets(theme_path)
	_generate_effect_assets(theme_path)
	
	print("[DefaultAssetGenerator] Default assets generated successfully")

static func _create_directories(base_path: String):
	var dir = DirAccess.open("user://")
	if not dir:
		print("[DefaultAssetGenerator] ERROR: Cannot access user directory")
		return
	
	# Create nested directories
	var paths = [
		"visuals/",
		base_path,
		base_path + "environment/",
		base_path + "objects/",
		base_path + "ui/",
		base_path + "effects/"
	]
	
	for path in paths:
		if not dir.dir_exists(path):
			dir.make_dir_recursive(path)

static func _generate_environment_assets(theme_path: String):
	# Background - dark blue gradient
	var bg_image = Image.create(256, 256, false, Image.FORMAT_RGBA8)
	for y in range(256):
		var alpha = float(y) / 255.0
		var color = Color(0.05, 0.05, 0.1 + alpha * 0.05, 1.0)
		for x in range(256):
			bg_image.set_pixel(x, y, color)
	bg_image.save_png(theme_path + "environment/background.png")
	
	# Wall - gray block with border
	var wall_image = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	wall_image.fill(Color(0.4, 0.4, 0.4, 1.0))
	# Add border
	for i in range(64):
		wall_image.set_pixel(i, 0, Color(0.6, 0.6, 0.6, 1.0))
		wall_image.set_pixel(i, 63, Color(0.2, 0.2, 0.2, 1.0))
		wall_image.set_pixel(0, i, Color(0.6, 0.6, 0.6, 1.0))
		wall_image.set_pixel(63, i, Color(0.2, 0.2, 0.2, 1.0))
	wall_image.save_png(theme_path + "environment/wall.png")

static func _generate_object_assets(theme_path: String):
	# Coin - yellow circle
	var coin_image = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	coin_image.fill(Color(0, 0, 0, 0))  # Transparent
	var center = Vector2(16, 16)
	for y in range(32):
		for x in range(32):
			var dist = Vector2(x, y).distance_to(center)
			if dist <= 12:
				var brightness = 1.0 - (dist / 12.0) * 0.3
				coin_image.set_pixel(x, y, Color(1.0 * brightness, 0.8 * brightness, 0.0, 1.0))
	coin_image.save_png(theme_path + "objects/coin.png")
	
	# Goal - blue square with glow
	var goal_image = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	goal_image.fill(Color(0, 0, 0, 0))  # Transparent
	# Inner blue square
	for y in range(8, 56):
		for x in range(8, 56):
			goal_image.set_pixel(x, y, Color(0.2, 0.5, 1.0, 1.0))
	# Outer glow
	for y in range(64):
		for x in range(64):
			var dist_to_edge = min(min(x, 63-x), min(y, 63-y))
			if dist_to_edge < 8:
				var alpha = (8.0 - dist_to_edge) / 8.0 * 0.5
				var current_color = goal_image.get_pixel(x, y)
				if current_color.a == 0:
					goal_image.set_pixel(x, y, Color(0.3, 0.7, 1.0, alpha))
	goal_image.save_png(theme_path + "objects/goal.png")
	
	# Player - teal square
	var player_image = Image.create(48, 48, false, Image.FORMAT_RGBA8)
	player_image.fill(Color(0.58, 0.98, 0.90, 1.0))
	# Add simple shading
	for y in range(48):
		for x in range(48):
			var shade = 1.0 - (float(x + y) / 96.0) * 0.2
			var color = Color(0.58 * shade, 0.98 * shade, 0.90 * shade, 1.0)
			player_image.set_pixel(x, y, color)
	player_image.save_png(theme_path + "objects/player.png")
	
	# Player spawn - green square with cross
	var spawn_image = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	spawn_image.fill(Color(0.2, 1.0, 0.2, 0.7))
	# Add cross pattern
	for i in range(64):
		spawn_image.set_pixel(i, 31, Color(0.9, 0.9, 0.9, 1.0))
		spawn_image.set_pixel(i, 32, Color(0.9, 0.9, 0.9, 1.0))
		spawn_image.set_pixel(31, i, Color(0.9, 0.9, 0.9, 1.0))
		spawn_image.set_pixel(32, i, Color(0.9, 0.9, 0.9, 1.0))
	spawn_image.save_png(theme_path + "objects/player_spawn.png")

static func _generate_ui_assets(theme_path: String):
	# Button - simple gradient
	var button_image = Image.create(128, 64, false, Image.FORMAT_RGBA8)
	for y in range(64):
		var gradient = 1.0 - float(y) / 64.0
		var color = Color(0.3 + gradient * 0.2, 0.3 + gradient * 0.2, 0.4 + gradient * 0.2, 1.0)
		for x in range(128):
			button_image.set_pixel(x, y, color)
	button_image.save_png(theme_path + "ui/button.png")
	
	# Panel - dark with border
	var panel_image = Image.create(256, 256, false, Image.FORMAT_RGBA8)
	panel_image.fill(Color(0.15, 0.15, 0.2, 0.9))
	# Border
	for i in range(256):
		panel_image.set_pixel(i, 0, Color(0.5, 0.5, 0.6, 1.0))
		panel_image.set_pixel(i, 255, Color(0.5, 0.5, 0.6, 1.0))
		panel_image.set_pixel(0, i, Color(0.5, 0.5, 0.6, 1.0))
		panel_image.set_pixel(255, i, Color(0.5, 0.5, 0.6, 1.0))
	panel_image.save_png(theme_path + "ui/panel.png")

static func _generate_effect_assets(theme_path: String):
	# Particle - small white circle
	var particle_image = Image.create(16, 16, false, Image.FORMAT_RGBA8)
	particle_image.fill(Color(0, 0, 0, 0))  # Transparent
	var center = Vector2(8, 8)
	for y in range(16):
		for x in range(16):
			var dist = Vector2(x, y).distance_to(center)
			if dist <= 6:
				var alpha = 1.0 - (dist / 6.0)
				particle_image.set_pixel(x, y, Color(1.0, 1.0, 1.0, alpha))
	particle_image.save_png(theme_path + "effects/particle.png")
	
	# Explosion - orange circle with rays
	var explosion_image = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	explosion_image.fill(Color(0, 0, 0, 0))  # Transparent
	var exp_center = Vector2(32, 32)
	for y in range(64):
		for x in range(64):
			var dist = Vector2(x, y).distance_to(exp_center)
			if dist <= 28:
				var alpha = 1.0 - (dist / 28.0)
				var color = Color(1.0, 0.5 + alpha * 0.5, 0.0, alpha)
				explosion_image.set_pixel(x, y, color)
	explosion_image.save_png(theme_path + "effects/explosion.png")