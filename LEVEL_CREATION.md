# Level Creation Guide

## Method 1: Visual Level Editor (Recommended)

### Opening the Level Editor
1. Open Godot
2. In the FileSystem dock, navigate to `scenes/level_editor/`
3. Double-click `LevelEditor.tscn`
4. Click the Play Scene button (or press F6)

### Controls
- **Number Keys 1-5**: Select tile type
  - 1: Wall (gray blocks)
  - 2: Coin (yellow collectibles)
  - 3: Spike (red hazards)
  - 4: Player Spawn (green start position)
  - 5: Empty (eraser)
- **Left Click**: Place selected tile
- **Right Click**: Erase tile
- **S**: Save level (exports to console)
- **L**: Load level into game for testing
- **C**: Clear all tiles

### Level Requirements
- Size: 11×20 grid
- Must have exactly ONE player spawn (P)
- Must have at least ONE goal (G)
- Walls around edges recommended
- Test path from spawn to goal!

### Testing Your Level
1. Press 'S' to save (copies level code to console)
2. Press 'L' to load into game
3. The game will start with your custom level

## Method 2: Code Template (Quick Method)

### Adding Levels to LevelTemplates.gd

1. Open `scripts/levels/LevelTemplates.gd`
2. Add a new function following this pattern:

```gdscript
static func get_level_2() -> Array:
	var template = [
		"###########",  # Top wall
		"#.........#",  # Empty row
		"#...CCC...#",  # Row with coins
		"#.........#",
		"#....P....#",  # Player spawn
		"#.........#",
		"#...###...#",  # Wall obstacle
		"#.........#",
		"#....G....#",  # Goal
		"###########"   # Bottom wall
	]
	return template
```

### Template Characters
- `#` = Wall (blocks movement)
- `.` = Empty space
- `C` = Coin (collectible)
- `S` = Spike (kills player)
- `P` = Player spawn (start position)
- `G` = Goal (level exit)

### Making Levels Load
Currently only level 0 (get_level_1) loads. To add level progression:
1. Update `LevelGenerator.gd` to check for more levels
2. Or rename your function to `get_level_1()` to replace the default

## Level Design Tips

### Good Practices
- Start simple, increase difficulty gradually
- Use coins to guide the player's path
- Place walls to create interesting movement puzzles
- Remember: players slide until they hit a wall!
- Test your level multiple times

### Example Patterns
```
"##...##"  # Narrow passage
"#CCCCC#"  # Coin line (encourages specific direction)
"#..S..#"  # Spike in center (forces wall hugging)
"##.#.##"  # Alternating walls (zigzag movement)
```

### Common Mistakes
- Unreachable areas (blocked by walls)
- No clear path to goal
- Too many spikes early on
- Forgetting the goal marker