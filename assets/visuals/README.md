# Visual Theme System

This directory contains visual themes for TechnoBeat. Each theme is a collection of PNG images that replace the game's default visuals.

## Theme Structure

Each theme should be organized in a folder with this structure:

```
assets/visuals/[theme_name]/
├── environment/
│   ├── background.png      # Main game background
│   └── wall.png           # Wall blocks
├── objects/
│   ├── coin.png           # Collectible coins
│   ├── goal.png           # Level goal
│   ├── player.png         # Player character
│   └── player_spawn.png   # Starting position
├── ui/
│   ├── button.png         # UI buttons
│   └── panel.png          # UI panels
└── effects/
    ├── particle.png       # Particle effects
    └── explosion.png      # Explosion effects
```

## Available Themes

- **default** - Default theme with README files and asset specifications

## Creating a New Theme

1. Create a new folder with your theme name (e.g., `assets/visuals/my_theme/`)
2. Copy the folder structure from the `default` theme
3. Replace the PNG files with your custom artwork
4. Follow the size recommendations in each category's README

## Switching Themes

The game uses the theme system automatically. To switch themes programmatically:

```gdscript
# Switch to a different theme
VisualThemeManager.switch_theme("my_theme")

# Get current theme
var current = VisualThemeManager.get_current_theme()

# Get available themes
var themes = VisualThemeManager.get_available_themes()
```

## Asset Guidelines

### General Requirements
- **Format**: PNG with alpha transparency
- **Color depth**: 32-bit RGBA
- **Style**: Keep consistent art style within your theme

### Size Recommendations
- **Background**: 256x256+ (tiles across screen)
- **Wall**: 64x64 pixels (game grid size)
- **Player**: 48x48 pixels
- **Goal**: 64x64 pixels
- **Coin**: 32x32 pixels
- **Player Spawn**: 64x64 pixels
- **UI Button**: 128x64 pixels
- **UI Panel**: 256x256 pixels
- **Particle**: 16x16 pixels
- **Explosion**: 64x64 pixels

### Tips for Good Themes
1. **Contrast**: Ensure good contrast between player, walls, and background
2. **Readability**: Make coins and goals clearly distinguishable
3. **Performance**: Keep file sizes reasonable (under 1MB per asset)
4. **Consistency**: Use similar lighting and color palettes across assets

## Current System Features

- **Automatic fallback**: Missing assets fall back to default theme or procedural generation
- **Hot-swapping**: Themes can be changed at runtime
- **Memory efficient**: Only current theme assets are loaded
- **Backwards compatible**: Game works without any custom themes

## Adding Theme Selection to Game

To add theme selection to your game's settings:

```gdscript
# Get available themes for settings menu
var theme_options = VisualThemeManager.get_available_themes()

# Create option button
for theme in theme_options:
    option_button.add_item(theme)

# Handle selection
func _on_theme_selected(theme_name: String):
    VisualThemeManager.switch_theme(theme_name)
```