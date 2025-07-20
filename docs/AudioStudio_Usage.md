# AudioStudio - Sound Design Tool

## Overview
AudioStudio is a comprehensive tool for shaping the procedural sounds in your Tomb of the Mask clone. It provides real-time parameter control and visual feedback for all synthesized audio elements.

## Features

### Real-time Sound Shaping
- **6 Sound Types**: Kick Drum, Snare Drum, Hi-Hat, Coin Chime, Wall Hit Tom Fill, Guitar Chord
- **Parameter Controls**: Sliders for frequency, envelope, timing, and amplitude adjustments
- **Live Preview**: Instant audio feedback when adjusting parameters
- **Waveform Visualization**: Real-time visual representation of your sound

### Sound Types and Parameters

#### Kick Drum (Beats 1 & 3)
- Base Frequency (40-100 Hz)
- Pitch Sweep Amount & Speed
- Envelope Decay
- Duration (0.05-0.3 seconds)
- Volume

#### Snare Drum (Beats 2 & 4)
- Tone Frequency (100-400 Hz)
- Noise Ratio (balance between noise and tone)
- Tone Amplitude
- Envelope Decay
- Duration & Volume

#### Hi-Hat (8th Notes)
- Metallic Frequencies (6-15 kHz range)
- Metallic Component Amplitudes
- Noise Amplitude
- Envelope Decay (crisp, fast decay)
- Duration & Volume

#### Coin Chime (Collection Sound)
- Chord Type (Major, Sus2, Color tone)
- Base Octave (C4-C7 range)
- Harmonic Richness
- Envelope Decay
- Duration & Volume

#### Wall Hit Tom Fill (Impact Sound)
- Tom Frequencies (3 toms: high, mid, low)
- Individual Tom Decay Rates
- Noise Amount (texture)
- Total Duration
- Volume

#### Guitar Chord (Movement Ambient)
- Chord Type (Cmaj7, Cmin7, Csus2)
- Attack Time (fade-in speed)
- Sustain Decay
- Harmonic Content
- Fundamental Amplitude & Ambient Level

## How to Use

### Launch AudioStudio
1. Open the AudioStudioTest scene: `scenes/tools/AudioStudioTest.tscn`
2. Or create an AudioStudio instance in your own scene

### Interface Layout
- **Left Panel**: Sound type selection with color-coded list
- **Center Panel**: Parameter controls with sliders and real-time values
- **Right Panel**: Waveform visualization with envelope overlay

### Workflow
1. **Select Sound Type**: Click on any sound type from the left panel
2. **Adjust Parameters**: Use sliders in the center panel to modify sound characteristics
3. **Preview**: Click "Preview" button to hear your changes instantly
4. **Visualize**: Watch the waveform update in real-time on the right panel
5. **Apply**: Use "Apply to Game" when satisfied with your sound design

### Parameter Formats
- **Frequency**: Displayed in Hz (e.g., "440 Hz")
- **Time**: Displayed in seconds (e.g., "0.150 s")  
- **Percent**: Displayed as percentage (e.g., "75%")
- **dB**: Displayed in decibels for volume controls
- **Int**: Integer values for discrete choices (chord types, etc.)

## Advanced Features

### Waveform Display
- Shows actual generated waveform
- Envelope overlay for visual decay representation
- Grid lines for amplitude and time reference
- Real-time updates as parameters change

### Parameter Descriptions
- Hover or read parameter descriptions to understand each control
- Value ranges are automatically constrained to musically useful values
- Step sizes optimized for precise control

### Integration Ready
- Built-in hooks for applying parameters to main game audio system
- Preset system foundation for saving/loading sound configurations
- Non-destructive workflow preserves original game sounds

## Technical Notes

### Audio Generation
- Uses Godot's AudioStreamGenerator for real-time synthesis
- 44.1kHz sample rate for high quality
- Mathematical synthesis (no external audio files required)
- Optimized for real-time parameter changes

### Performance
- Lightweight parameter system
- Efficient waveform visualization
- Minimal memory footprint
- Responsive UI even with rapid parameter changes

## Future Enhancements
- Preset save/load system
- A/B comparison tools  
- Randomization features
- Export capabilities
- Enhanced integration with main game audio

## Keyboard Shortcuts
- **ESC**: Quit AudioStudio (when launched standalone)
- Mouse controls for all parameter adjustments
- Real-time parameter updates (no need to press Enter/Apply after each change)