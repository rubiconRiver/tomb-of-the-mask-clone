# Level Editing Guide

## Quick Start

1. **Open Godot and load the project**
2. **Open the level template scene**: `scenes/levels/level_template.tscn`
3. **You'll see a TileMap node** - this is where you'll paint your level

## Setting Up the TileSet (One-time setup)

Since we need simple tiles for editing, here's how to create them:

1. In the FileSystem dock, right-click on `assets/sprites/simple_tileset.tres` and select "Open in Editor"
2. Click the "+" button at the bottom to add a new Atlas
3. For the texture, we'll create a simple one:
   - Create a new Image texture (64x256 pixels) with 4 colored squares:
	 - Gray square (Wall)
	 - Yellow square (Coin) 
	 - Red square (Spike)
	 - Green square (Player spawn)
   - OR just use any 64x64 tiles you have
4. Set up the atlas with 4 tiles in a row

## Painting Your Level

1. **Select the TileMap node** in the scene
2. **Open the TileMap panel** at the bottom of the editor
3. **Choose your tile** from the palette
4. **Paint on the grid** (11x20 tiles)
   - Left-click to place tiles
   - Right-click to erase

### Tile Types:
- **Gray/Tile 0**: Wall - Player stops here
- **Yellow/Tile 1**: Coin - Collectible
- **Red/Tile 2**: Spike - Kills player
- **Green/Tile 3**: Player spawn point (only place one!)

## Converting to Game Format

1. **Select the LevelTemplate root node**
2. **In the Inspector, check "Export Level"**
3. **Look at the Output panel** - it will print your level template
4. **Copy the printed code** into `scripts/levels/LevelTemplates.gd`

## Level Design Tips

- Remember: Player slides until hitting a wall!
- Place coins along the intended path
- Start simple - straight paths with turns
- Test mentally: Can the player reach all areas?
- One player spawn point only (usually bottom center)

## Testing Your Level

1. Save your level template code
2. Update `LevelGenerator.gd` to load your new level
3. Run the game to test

Would you like me to help you set up the tileset texture, or do you want to try creating the colored squares yourself in Godot?
