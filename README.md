# Technobeat - a music game

A fun 2D maze game built with Godot! This guide will help you run the game on your computer.

## Quick Start - Two Ways to Play

### Option 1: Using Godot Editor (Recommended for First Time)

1. **Download Godot**
   - Go to https://godotengine.org/download
   - Download Godot 4.x Standard version for your operating system
   - No installation needed - just extract/open the downloaded file

2. **Get the Game Code**
   - Download this project as a ZIP file from GitHub (green "Code" button → "Download ZIP")
   - Extract the ZIP file to a folder on your computer

3. **Open and Run the Game**
   - Open Godot
   - Click "Import" 
   - Navigate to the extracted folder and select `project.godot`
   - Click "Import & Edit"
   - Once the project opens, press F5 or click the play button (▶️) in the top right

### Option 2: Command Line (If you're using Claude or prefer terminal)

If you have Godot installed and added to your PATH:

```bash
# Clone the repository
git clone https://github.com/rubiconRiver/2dgametest.git
cd 2dgametest

# Run the game directly
godot --path .

# Or open in the editor
godot --path . --editor
```

## Controls

- **Arrow Keys** or **WASD**: Move the player
- The player will slide until hitting a wall
- Avoid obstacles and reach the goal!

## Troubleshooting

**Game won't open?**
- Make sure you downloaded the correct Godot version (4.x)
- Try re-extracting the game files

**Black screen or errors?**
- In Godot editor, go to Project → Project Settings → Rendering
- Try changing the renderer to "Compatibility"

**Performance issues?**
- Lower the window size in Project Settings
- Close other programs while playing

## For Developers

This is a Tomb of the Mask clone built in Godot, targeting mobile platforms with planned ad integration. See CLAUDE.md for development details.

### Building for iOS

**First Time Setup:**
```bash
# Create Xcode project (only do this once!)
godot --path . --export-release "iOS" "../ios exports/TombOfTheMask.ipa"

# Open in Xcode and configure:
# 1. Set your development team
# 2. Configure bundle ID
# 3. Add app icons
```

**Updating Your iOS Build:**
```bash
# Export only the game content (much faster!)
godot --path . --export-pack "iOS" "../ios exports/TombOfTheMask/TombOfTheMask.pck"

# Then in Xcode: Clean (Shift+Cmd+K) and Run (Cmd+R)
```

### Building for Android

```bash
# Make sure you have Android export templates installed
godot --path . --export-release "Android" "TombOfTheMask.apk"
```

---

Have fun playing! If you encounter any issues, feel free to reach out.
