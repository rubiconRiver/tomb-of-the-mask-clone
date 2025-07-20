# Tomb of the Mask Clone - Project Instructions

## Project Overview
Building a Tomb of the Mask clone in Godot targeting mobile platforms with ad integration.

## Troubleshooting Tips
- **Class registration errors**: If you see "Could not find type" errors, reload the project in the Godot editor before changing code
- **Asset import errors**: Open the editor once to trigger asset imports

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

## iOS Build Instructions

### First Time Setup
```bash
# Export iOS project (creates Xcode project) - ONLY DO THIS ONCE
godot --path . --export-release "iOS" "../ios exports/TombOfTheMask.ipa"

# The export creates an Xcode project at: ../ios exports/TombOfTheMask/
# Initial setup:
# 1. Open TombOfTheMask.xcodeproj in Xcode
# 2. Select your development team in Signing & Capabilities
# 3. Configure bundle identifier, app icons, etc.
```

### Updating Existing Build
```bash
# For subsequent updates, just export the .pck file:
godot --path . --export-pack "iOS" "../ios exports/TombOfTheMask/TombOfTheMask.pck"

# Then in Xcode:
# 1. Replace the old .pck file with the new one
# 2. Build and run (Cmd+R)
```

### Alternative: Direct PCK Export
```bash
# You can also export just the PCK to update game content:
godot --path . --export-release "iOS" "../ios exports/TombOfTheMask/data.pck" --export-pack-only
```

### For App Store Release
1. Update version/build number in Xcode
2. Archive the project (Product > Archive)
3. Distribute through App Store Connect

## Ad Integration Notes
- Use Godot's AdMob plugin for initial implementation
- Place interstitial ads carefully to not disrupt flow
- Rewarded ads for extra lives/continues