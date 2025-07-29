extends Node

# Script to create default theme placeholder files
# Run this script once to generate the default theme structure

func _ready():
	create_default_theme()
	print("Default theme creation complete!")
	get_tree().quit()

func create_default_theme():
	print("Creating default visual theme...")
	
	# Create the default theme directory structure
	var base_path = "/Users/landphil/Games/2dgametest/assets/visuals/default/"
	
	# Create placeholder files to show the expected structure
	var structure = {
		"environment/": [
			"background.png",  # Main game background
			"wall.png"         # Wall blocks
		],
		"objects/": [
			"coin.png",        # Collectible coins
			"goal.png",        # Level goal/finish
			"player.png",      # Player character
			"player_spawn.png" # Starting position marker
		],
		"ui/": [
			"button.png",      # UI buttons
			"panel.png"        # UI panels
		],
		"effects/": [
			"particle.png",    # Particle effects
			"explosion.png"    # Explosion effects
		]
	}
	
	# Create placeholder README files explaining each asset
	for category in structure:
		var category_path = base_path + category
		var readme_content = generate_readme_content(category, structure[category])
		var readme_file = FileAccess.open(category_path + "README.md", FileAccess.WRITE)
		if readme_file:
			readme_file.store_string(readme_content)
			readme_file.close()
			print("Created: ", category_path + "README.md")

func generate_readme_content(category: String, files: Array) -> String:
	var content = "# " + category.trim_suffix("/").capitalize() + " Assets\n\n"
	content += "This directory contains visual assets for the **" + category.trim_suffix("/") + "** category.\n\n"
	content += "## Required Files\n\n"
	
	for file in files:
		var asset_name = file.get_basename()
		content += "- **" + file + "** - " + get_asset_description(asset_name) + "\n"
	
	content += "\n## Asset Requirements\n\n"
	content += "- **Format**: PNG with transparency support\n"
	content += "- **Color depth**: 32-bit RGBA\n"
	content += "- **Recommended sizes**:\n"
	
	match category:
		"environment/":
			content += "  - background.png: 256x256 or larger (will tile)\n"
			content += "  - wall.png: 64x64 pixels\n"
		"objects/":
			content += "  - coin.png: 32x32 pixels\n"
			content += "  - goal.png: 64x64 pixels\n"
			content += "  - player.png: 48x48 pixels\n"
			content += "  - player_spawn.png: 64x64 pixels\n"
		"ui/":
			content += "  - button.png: 128x64 pixels\n"
			content += "  - panel.png: 256x256 pixels\n"
		"effects/":
			content += "  - particle.png: 16x16 pixels\n"
			content += "  - explosion.png: 64x64 pixels\n"
	
	content += "\n## Usage\n\n"
	content += "Place your custom PNG files in this directory to override the default "
	content += category.trim_suffix("/") + " visuals.\n"
	content += "The game will automatically load these assets when using this theme.\n"
	
	return content

func get_asset_description(asset_name: String) -> String:
	match asset_name:
		"background": return "Main game background (tiles across screen)"
		"wall": return "Solid wall blocks that stop player movement"
		"coin": return "Collectible coins that give points"
		"goal": return "Level goal/finish line"
		"player": return "Player character sprite"
		"player_spawn": return "Starting position indicator"
		"button": return "UI button background"
		"panel": return "UI panel background"
		"particle": return "Small particle effect sprite"
		"explosion": return "Explosion effect sprite"
		_: return "Visual asset"