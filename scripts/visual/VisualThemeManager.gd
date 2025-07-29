extends Node

# Visual Theme Manager - Handles loading and switching visual themes
# Similar to the audio theme system but for visual assets

# Current active theme
var current_theme = "default"

# Available themes (discovered dynamically)
var available_themes: Array[String] = []

# Cached textures for current theme
var cached_textures = {}

# Base path for visual themes
const VISUAL_THEMES_PATH = "res://assets/visuals/"

# Asset categories and their file mappings
const ASSET_CATEGORIES = {
	"environment": {
		"background": "background.png",
		"wall": "wall.png"
	},
	"objects": {
		"coin": "coin.png",
		"goal": "goal.png",
		"player": "player.png",
		"player_spawn": "player_spawn.png"
	},
	"ui": {
		"button": "button.png",
		"panel": "panel.png"
	},
	"effects": {
		"particle": "particle.png",
		"explosion": "explosion.png"
	}
}

signal theme_changed(new_theme: String)

func _ready():
	print("[VisualThemeManager] Initializing visual theme system")
	discover_themes()
	load_theme(current_theme)

# Discover available themes by scanning directories
func discover_themes():
	available_themes.clear()
	var dir = DirAccess.open(VISUAL_THEMES_PATH)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir() and not file_name.begins_with("."):
				available_themes.append(file_name)
				print("[VisualThemeManager] Found theme: ", file_name)
			file_name = dir.get_next()
		dir.list_dir_end()
	else:
		print("[VisualThemeManager] WARNING: Could not access visual themes directory")
		available_themes.append("default")  # Fallback

# Load a specific theme
func load_theme(theme_name: String) -> bool:
	if theme_name == current_theme and not cached_textures.is_empty():
		print("[VisualThemeManager] Theme '", theme_name, "' already loaded")
		return true
	
	print("[VisualThemeManager] Loading theme: ", theme_name)
	
	# Clear current cache
	cached_textures.clear()
	
	# Load textures for each category
	var theme_path = VISUAL_THEMES_PATH + theme_name + "/"
	var success = true
	
	for category in ASSET_CATEGORIES:
		var category_path = theme_path + category + "/"
		for asset_name in ASSET_CATEGORIES[category]:
			var file_path = category_path + ASSET_CATEGORIES[category][asset_name]
			var texture = load_texture(file_path)
			
			if texture:
				var cache_key = category + "." + asset_name
				cached_textures[cache_key] = texture
				print("[VisualThemeManager] ✓ Loaded: ", cache_key)
			else:
				print("[VisualThemeManager] ⚠ Failed to load: ", file_path)
				# Try fallback to default theme
				if theme_name != "default":
					var fallback_path = VISUAL_THEMES_PATH + "default/" + category + "/" + ASSET_CATEGORIES[category][asset_name]
					texture = load_texture(fallback_path)
					if texture:
						var cache_key = category + "." + asset_name
						cached_textures[cache_key] = texture
						print("[VisualThemeManager] ✓ Loaded fallback: ", cache_key)
					else:
						success = false
				else:
					success = false
	
	if success:
		current_theme = theme_name
		emit_signal("theme_changed", current_theme)
		print("[VisualThemeManager] Theme '", theme_name, "' loaded successfully")
	else:
		print("[VisualThemeManager] ERROR: Failed to load theme '", theme_name, "'")
	
	return success

# Load a texture from file path
func load_texture(file_path: String) -> Texture2D:
	if not FileAccess.file_exists(file_path):
		return null
	
	var texture = load(file_path) as Texture2D
	return texture

# Get texture for a specific asset
func get_texture(category: String, asset_name: String) -> Texture2D:
	var cache_key = category + "." + asset_name
	if cache_key in cached_textures:
		return cached_textures[cache_key]
	
	print("[VisualThemeManager] WARNING: Texture not found: ", cache_key)
	return null

# Convenience functions for common assets
func get_background_texture() -> Texture2D:
	return get_texture("environment", "background")

func get_wall_texture() -> Texture2D:
	return get_texture("environment", "wall")

func get_coin_texture() -> Texture2D:
	return get_texture("objects", "coin")

func get_goal_texture() -> Texture2D:
	return get_texture("objects", "goal")

func get_player_texture() -> Texture2D:
	return get_texture("objects", "player")

func get_player_spawn_texture() -> Texture2D:
	return get_texture("objects", "player_spawn")

# Switch to a different theme
func switch_theme(theme_name: String) -> bool:
	if theme_name == current_theme:
		return true
	
	if theme_name not in available_themes:
		print("[VisualThemeManager] ERROR: Theme '", theme_name, "' not found")
		return false
	
	return load_theme(theme_name)

# Get list of available themes
func get_available_themes() -> Array[String]:
	return available_themes.duplicate()

# Get current theme name
func get_current_theme() -> String:
	return current_theme

# Create a colored rectangle texture (fallback for missing textures)
func create_colored_texture(color: Color, size: Vector2i = Vector2i(64, 64)) -> ImageTexture:
	var image = Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	image.fill(color)
	var texture = ImageTexture.new()
	texture.set_image(image)
	return texture