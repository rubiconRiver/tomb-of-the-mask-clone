# Tomb of the Mask Clone - Project Instructions

## Project Overview
Building a Tomb of the Mask clone in Godot targeting mobile platforms with ad integration.

## Godot Setup Commands
```bash
# Create new Godot project
godot --path . --editor

# Run the game
godot --path .

# Export for Android (after setting up export templates)
godot --export-release "Android" tomb_of_mask.apk

# Export for iOS (after setting up export templates)
godot --export-release "iOS" tomb_of_mask.ipa
```

## Project Structure
```
/
├── scenes/
│   ├── main.tscn
│   ├── player/
│   ├── levels/
│   ├── ui/
│   └── obstacles/
├── scripts/
│   ├── player/
│   ├── levels/
│   ├── ui/
│   └── obstacles/
├── assets/
│   ├── sprites/
│   ├── audio/
│   └── fonts/
└── project.godot
```

## Key Systems
- **Grid Movement**: Player moves in cardinal directions until hitting wall
- **Procedural Generation**: Levels generated using cellular automata or similar
- **Mobile Input**: Touch/swipe detection for movement
- **Ad Integration**: Using Godot Android/iOS plugins for ads

## Development Priorities
1. Core movement mechanics
2. Basic level generation
3. Mobile controls
4. Obstacles and hazards
5. Scoring system
6. UI and menus
7. Ad integration

## Testing Notes
- Test on actual mobile devices early
- Check performance on lower-end devices
- Verify swipe sensitivity feels good

## Ad Integration Notes
- Use Godot's AdMob plugin for initial implementation
- Place interstitial ads carefully to not disrupt flow
- Rewarded ads for extra lives/continues