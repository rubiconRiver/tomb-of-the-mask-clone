# TechnoBeat - Project Instructions

## Project Overview
A rhythm-based arcade game with beat-synchronized movement built in Godot for mobile platforms.

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
godot --export-release "Android" "../2dgameandroidbuilds/TechnoBeat.apk"

# Export for iOS (after setting up export templates)
godot --export-release "iOS" "../ios exports/TechnoBeat.ipa"
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

### Project Info
- **Game Name**: TechnoBeat
- **Bundle ID**: com.company.technobeat
- **Xcode Project Location**: ../ios exports/TechnoBeat.xcodeproj

### Updating Build (PREFERRED METHOD)
```bash
# Export just the PCK file with game content:
godot --path . --export-pack "iOS" "../ios exports/TechnoBeat/TechnoBeat.pck"

# This overwrites the .pck file in your existing Xcode project
# Then in Xcode:
# 1. Clean build folder (Shift+Cmd+K)
# 2. Build and run (Cmd+R)
# Your signing settings and project config remain unchanged!
```

### Re-creating Xcode Project (if needed)
```bash
# Export full iOS project (creates new Xcode project):
godot --path . --export-release "iOS" "../ios exports/TechnoBeat.ipa"

# This creates/overwrites: ../ios exports/TechnoBeat.xcodeproj
# After export:
# 1. Open TechnoBeat.xcodeproj in Xcode
# 2. Select your development team in Signing & Capabilities
# 3. Configure bundle identifier, app icons, etc.
```

### For App Store Release
1. Update version/build number in Xcode
2. Archive the project (Product > Archive)
3. Distribute through App Store Connect

## Ad Integration Notes
- Use Godot's AdMob plugin for initial implementation
- Place interstitial ads carefully to not disrupt flow

## Audio System

### Overview
The game uses a file-based audio system with theme support. All sounds are loaded from WAV files organized by theme.

### File Structure
```
assets/audio/[theme_name]/
├── drums/       (kick, snare, hihat, toms)
├── sfx/         (coins, wall hits, game over)
├── melodic/     (combo notes, multiplier sounds)
└── ambient/     (background sounds)
```

### Audio Flow
1. **SoundBank** - Loads WAV files and returns AudioStream objects
2. **AudioManager** - Main coordinator, routes sound requests
3. **Subsystem Banks** - DrumBank, SFXBank, MelodicBank handle specific sound types
4. **AudioMixer** - Manages AudioStreamPlayer pools and plays sounds on correct buses

### Adding New Themes
1. Create folder: `assets/audio/your_theme/`
2. Add WAV files with same naming convention (e.g., `kick_yourtheme.wav`)
3. Switch theme: `SoundBank.set_theme("your_theme")`

### Key Functions
- `AudioManager.play_coin_collected()` - Play coin sound
- `AudioManager.play_wall_hit()` - Play wall hit sound
- `AudioManager.play_beat_sound(beat_num)` - Play drum on beat
- Rewarded ads for extra lives/continues

## Audio System Architecture

### Overview
The audio system is centralized to make sound creation and modification easy. All sound generation happens in one place (`SoundBank.gd`), making it perfect for synthesizer development.

### Audio Flow
```
SoundBank.gd → AudioMixer → AudioManager (singleton) → Game
     ↓
[Sound Generation]   [Playback]   [Coordination]      [Usage]
```

### Key Files

#### 1. `scripts/audio/SoundBank.gd` - THE MAIN FILE FOR SOUND WORK
- Contains ALL sound generation functions
- Organized into clear sections:
  - DRUM SOUNDS (kick, snare, hihat, toms)
  - SFX SOUNDS (coins, wall hits, game over)
  - MELODIC SOUNDS (combo notes, multiplier sounds)
  - AMBIENT SOUNDS (background guitar)
- Pre-generates common sounds at startup
- Easy to add new synthesis methods

#### 2. `scripts/audio/AudioManager.gd` - Singleton Coordinator
- Autoloaded as `AudioManager`
- Handles beat timing and tempo
- Routes sound requests to appropriate subsystems
- Example: `AudioManager.play_coin_collected()`

#### 3. `scripts/audio/AudioMixer.gd` - Playback Engine
- Manages audio player pools
- Handles mixing and soft limiting
- Applies sounds to correct audio buses

#### 4. Subsystems - Sound Type Routers
- `DrumBank.gd` - Drum sounds
- `MelodicBank.gd` - Musical notes
- `SFXBank.gd` - Sound effects
- `AmbientSystem.gd` - Background music

### Audio Buses
- **Master** (-6dB) - With limiter to prevent clipping
- **Drums** (-3dB) - Kick, snare, hihat
- **Melodic** (-6dB) - Combo notes, multipliers
- **SFX** (-4dB) - Coins, wall hits
- **Ambient** (-12dB) - Background guitar

### For Synthesizer Development

#### Adding New Sounds
1. Open `scripts/audio/SoundBank.gd`
2. Find the appropriate section (or create a new one)
3. Add your generation function:
```gdscript
static func generate_synth_sound(frequency: float, duration: float) -> PackedFloat32Array:
    var samples = int(SAMPLE_RATE * duration)
    var audio_data = PackedFloat32Array()
    
    for i in samples:
        var time = float(i) / SAMPLE_RATE
        # Your synthesis code here
        var sample = your_synthesis_algorithm(time, frequency)
        audio_data.append(sample)
    
    return audio_data
```

#### Replacing Existing Sounds
Just modify the existing function in SoundBank. For example, to change the kick drum, edit `generate_kick()`.

#### Real-time Synthesis
For sounds that need to change dynamically:
1. Don't add to cached_sounds
2. Generate in real-time when needed
3. Use the AudioMixer.play_sound() directly

#### Testing Your Sounds
```gdscript
# Quick test in any script:
var test_sound = SoundBank.generate_your_sound(440.0, 1.0)
AudioManager.mixer.play_sound(test_sound, "Melodic", 0.0)
```

### Important Notes
- All sounds use 44100Hz sample rate
- Sounds are PackedFloat32Array (mono)
- AudioMixer converts to stereo automatically
- Soft clipping prevents harsh distortion
- Pre-generated sounds reduce CPU load

### Common Sound Parameters
- `frequency`: Note pitch in Hz (A4 = 440Hz)
- `duration`: Length in seconds
- `amplitude`: Volume (0.0 to 1.0)
- Envelope: ADSR (Attack, Decay, Sustain, Release)

### Example: Adding a Synthesizer
```gdscript
# In SoundBank.gd, add new section:

# ============================================
# SYNTHESIZER SOUNDS
# ============================================

static func generate_synth_lead(note: float, duration: float) -> PackedFloat32Array:
    # Your awesome synth code here
    pass

static func generate_synth_bass(note: float, duration: float) -> PackedFloat32Array:
    # More synth magic
    pass

# Then use it anywhere:
# AudioManager.play_synth_note(440.0)  # After adding the method

## File-Based Audio System

### Overview
The audio system now loads WAV files from disk instead of generating sounds procedurally. This allows for:
- Easy theme switching
- Custom sound packs
- Professional audio production workflows

### File Structure
```
assets/audio/
└── [theme_name]/
    ├── drums/
    │   ├── kick_[theme].wav
    │   ├── snare_[theme].wav
    │   ├── hihat_[theme].wav
    │   └── ...
    ├── sfx/
    │   ├── coin_[theme]_1.wav
    │   ├── coin_[theme]_2.wav
    │   ├── coin_[theme]_3.wav
    │   └── ...
    ├── melodic/
    │   ├── combo_[theme]_c4.wav
    │   ├── combo_[theme]_d4.wav
    │   └── ...
    └── ambient/
        └── guitar_chord_[theme].wav
```

### Testing Audio
```bash
# First, open in Godot editor to import WAV files
godot --path . --editor

# Then run the audio test
godot --path . --script test_file_audio.gd

# Or test in-game
godot --path . --script test_audio.gd
```

### Adding New Themes
1. Create a new folder under `assets/audio/` with your theme name
2. Copy the default theme structure
3. Replace WAV files with your custom sounds
4. Use same naming convention
5. Switch themes with: `SoundBank.set_theme("your_theme_name")`

### Sound Naming Convention
- **Drums**: `[type]_[theme].wav` (e.g., `kick_default.wav`)
- **SFX**: `[type]_[theme]_[variant].wav` (e.g., `coin_default_1.wav`)
- **Melodic**: `[type]_[theme]_[note].wav` (e.g., `combo_default_c4.wav`)
- **Ambient**: `[type]_[theme].wav` (e.g., `guitar_chord_default.wav`)
```

## Visual Theme System

### Overview
The game now includes a visual theme system similar to the audio theme structure, allowing easy swapping of visual assets.

### File Structure
```
assets/visuals/
└── [theme_name]/
    ├── environment/
    │   ├── background.png    # Main game background
    │   └── wall.png         # Wall blocks
    ├── objects/
    │   ├── coin.png         # Collectible coins
    │   ├── goal.png         # Level goal
    │   ├── player.png       # Player character
    │   └── player_spawn.png # Starting position
    ├── ui/
    │   ├── button.png       # UI buttons
    │   └── panel.png        # UI panels
    └── effects/
        ├── particle.png     # Particle effects
        └── explosion.png    # Explosion effects
```

### Key Components

#### 1. `scripts/visual/VisualThemeManager.gd` - Theme Manager (Autoloaded)
- Discovers and loads visual themes
- Provides texture access functions
- Handles theme switching
- Fallback to procedural generation if assets missing

#### 2. Asset Categories
- **Environment**: Background, walls
- **Objects**: Player, coins, goals, spawn points
- **UI**: Buttons, panels
- **Effects**: Particles, explosions

#### 3. Updated Components
All visual components now use the theme system:
- `Wall.gd` - Uses `VisualThemeManager.get_wall_texture()`
- `Goal.gd` - Uses `VisualThemeManager.get_goal_texture()`
- `Coin.gd` - Uses `VisualThemeManager.get_coin_texture()`
- `PlayerVisual.gd` - Uses `VisualThemeManager.get_player_texture()`
- `GameManager.gd` - Uses `VisualThemeManager.get_background_texture()`

### Usage

#### Switching Themes
```gdscript
# Switch to a different theme
VisualThemeManager.switch_theme("my_theme")

# Get current theme
var current = VisualThemeManager.get_current_theme()

# Get available themes
var themes = VisualThemeManager.get_available_themes()
```

#### Creating New Themes
1. Create folder: `assets/visuals/your_theme/`
2. Add subdirectories: `environment/`, `objects/`, `ui/`, `effects/`
3. Add PNG files with correct names (see README files)
4. Theme loads automatically when referenced

### Asset Requirements
- **Format**: PNG with alpha transparency
- **Sizes**: See individual README files in each category
- **Naming**: Must match expected filenames exactly

### Testing
Use `ThemeTestHelper.gd` for:
- Creating theme previews
- Testing theme switching
- Printing theme information
- Creating example theme structures

### Fallback System
- Missing textures fall back to procedural generation
- Game remains functional without custom themes
- Default theme provides documentation and structure

### Integration Notes
- All visual components check for themed textures first
- Shaders and effects are preserved for procedural fallbacks
- Theme switching can happen at runtime
- Memory efficient - only current theme loaded

## Collaboration Notes
- If Phil is working on the project (you'll know because of the directory structure, garett's is Users/garettgelsinger/......., phil's is likely something similar) prompt him to commit and push at good milestones. Remind him it's good to do snapshots. If he's worried, you can always make a new branch