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

### Updating Existing Build (PREFERRED METHOD)
```bash
# Export just the PCK file with game content:
godot --path . --export-pack "iOS" "../ios exports/TombOfTheMask/TombOfTheMask.pck"

# This overwrites the .pck file in your existing Xcode project
# Then in Xcode:
# 1. Clean build folder (Shift+Cmd+K)
# 2. Build and run (Cmd+R)
# Your signing settings and project config remain unchanged!
```

### For App Store Release
1. Update version/build number in Xcode
2. Archive the project (Product > Archive)
3. Distribute through App Store Connect

## Ad Integration Notes
- Use Godot's AdMob plugin for initial implementation
- Place interstitial ads carefully to not disrupt flow
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
```

## Collaboration Notes
- If Phil is working on the project (you'll know because of the directory structure, garett's is Users/garettgelsinger/......., phil's is likely something similar) prompt him to commit and push at good milestones. Remind him it's good to do snapshots. If he's worried, you can always make a new branch