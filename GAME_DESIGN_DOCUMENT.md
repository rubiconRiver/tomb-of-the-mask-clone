# Tomb of the Mask Clone - Game Design Document

## Game Overview
A fast-paced arcade game where players navigate through procedurally generated mazes by swiping to move in straight lines until hitting a wall. The game features retro pixel art aesthetics and addictive one-touch controls perfect for mobile devices.

## Core Mechanics

### Movement
- **Swipe Controls**: Player swipes in any cardinal direction (up, down, left, right)
- **Continuous Movement**: Character moves in the swiped direction until hitting a wall or obstacle
- **Instant Response**: No acceleration/deceleration - immediate full-speed movement

### Level Design
- **Procedural Generation**: Infinite levels that get progressively harder
- **Grid-Based Layout**: Levels built on a grid system (16x24 for portrait mobile)
- **Rising Water/Lava**: Hazard that rises from bottom, forcing upward progression

### Obstacles & Hazards
- **Spikes**: Static hazards that kill on contact
- **Moving Saws**: Patrol back and forth on set paths
- **Crumbling Blocks**: Disappear shortly after player touches them
- **Rotating Blades**: Spin in place with deadly edges
- **Enemy Creatures**: Simple AI enemies that move in patterns

### Collectibles
- **Coins**: Primary currency for unlocking characters/power-ups
- **Dots**: Small collectibles that increase score
- **Power-ups**:
  - Shield (temporary invincibility)
  - Magnet (attracts nearby coins)
  - Slow Motion (slows hazards temporarily)
  - Score Multiplier

### Progression
- **Level Counter**: Track how many levels completed
- **High Score System**: Best distance/score tracking
- **Character Unlocks**: New masks/characters with cosmetic differences
- **Daily Challenges**: Special levels with unique rewards

## Visual Style
- **Retro Pixel Art**: 16x16 or 32x32 sprites
- **Limited Color Palette**: 4-8 colors per level theme
- **Clean UI**: Minimalist design that doesn't obstruct gameplay
- **Smooth Animations**: Fluid movement despite pixel art style

## Audio Design
- **Chiptune Soundtrack**: Energetic retro music
- **Sound Effects**: 
  - Movement whoosh
  - Coin collection
  - Death sound
  - Power-up activation
  - UI clicks

## Monetization (Mobile)
- **Ads**:
  - Rewarded video ads for extra lives
  - Interstitial ads between runs (limited frequency)
  - Banner ads in menus (not during gameplay)
- **Future IAP Options**:
  - Remove ads
  - Coin packs
  - Character bundles

## Technical Requirements
- **Engine**: Godot 4.x
- **Target Platforms**: iOS, Android
- **Screen Orientation**: Portrait mode
- **Minimum Resolution**: 720x1280
- **Performance Target**: 60 FPS on mid-range devices

## MVP Features
1. Basic swipe movement
2. Procedural level generation
3. Rising hazard mechanic
4. Coins and scoring
5. One character/mask
6. Basic spikes and saws
7. Simple menu system
8. Ad integration framework

## Future Features (Post-Launch)
- Level editor for user-generated content
- Multiplayer racing mode
- More themes (ice, fire, jungle, etc.)
- Boss levels
- Achievement system
- Cloud save sync