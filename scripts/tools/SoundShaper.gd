extends Node
class_name SoundShaper

# SoundShaper handles parameter management and sound generation for the AudioStudio
# It provides a unified interface for controlling all procedural sound parameters

signal parameter_changed(param_name: String, value: float)

var current_sound_type: AudioStudio.SoundType
var sound_parameters = {}

# Audio system for preview
var preview_player: AudioStreamPlayer
var preview_generator: AudioStreamGenerator

# Parameter definitions for each sound type
var parameter_definitions = {
	AudioStudio.SoundType.KICK_DRUM: {
		"base_frequency": {
			"display_name": "Base Frequency",
			"description": "Fundamental frequency of the kick drum",
			"min": 40.0, "max": 100.0, "value": 60.0, "step": 1.0,
			"format": "frequency"
		},
		"pitch_sweep_amount": {
			"display_name": "Pitch Sweep Amount", 
			"description": "How much the pitch drops during the hit",
			"min": 10.0, "max": 60.0, "value": 40.0, "step": 1.0,
			"format": "frequency"
		},
		"pitch_sweep_speed": {
			"display_name": "Pitch Sweep Speed",
			"description": "How quickly the pitch drops",
			"min": 10.0, "max": 30.0, "value": 20.0, "step": 0.5,
			"format": "float"
		},
		"envelope_decay": {
			"display_name": "Envelope Decay",
			"description": "How quickly the volume fades",
			"min": 5.0, "max": 25.0, "value": 15.0, "step": 0.5,
			"format": "float"
		},
		"duration": {
			"display_name": "Duration",
			"description": "Length of the kick drum hit",
			"min": 0.05, "max": 0.3, "value": 0.15, "step": 0.01,
			"format": "time"
		},
		"volume": {
			"display_name": "Volume",
			"description": "Output volume level",
			"min": 0.1, "max": 1.0, "value": 0.8, "step": 0.01,
			"format": "percent"
		}
	},
	
	AudioStudio.SoundType.SNARE_DRUM: {
		"tone_frequency": {
			"display_name": "Tone Frequency",
			"description": "Frequency of the tonal component",
			"min": 100.0, "max": 400.0, "value": 200.0, "step": 5.0,
			"format": "frequency"
		},
		"noise_ratio": {
			"display_name": "Noise Ratio",
			"description": "Balance between noise and tone (0=pure tone, 1=pure noise)",
			"min": 0.0, "max": 1.0, "value": 0.7, "step": 0.01,
			"format": "percent"
		},
		"tone_amplitude": {
			"display_name": "Tone Amplitude",
			"description": "Volume of the tonal component",
			"min": 0.1, "max": 0.5, "value": 0.3, "step": 0.01,
			"format": "percent"
		},
		"envelope_decay": {
			"display_name": "Envelope Decay",
			"description": "How quickly the volume fades",
			"min": 15.0, "max": 35.0, "value": 25.0, "step": 0.5,
			"format": "float"
		},
		"duration": {
			"display_name": "Duration",
			"description": "Length of the snare hit",
			"min": 0.05, "max": 0.2, "value": 0.1, "step": 0.01,
			"format": "time"
		},
		"volume": {
			"display_name": "Volume",
			"description": "Output volume level",
			"min": 0.1, "max": 1.0, "value": 0.6, "step": 0.01,
			"format": "percent"
		}
	},
	
	AudioStudio.SoundType.HI_HAT: {
		"metallic_freq_1": {
			"display_name": "Metallic Frequency 1",
			"description": "First metallic shimmer frequency",
			"min": 6000.0, "max": 12000.0, "value": 8000.0, "step": 100.0,
			"format": "frequency"
		},
		"metallic_freq_2": {
			"display_name": "Metallic Frequency 2", 
			"description": "Second metallic shimmer frequency",
			"min": 8000.0, "max": 15000.0, "value": 12000.0, "step": 100.0,
			"format": "frequency"
		},
		"metallic_1_amplitude": {
			"display_name": "Metallic 1 Amplitude",
			"description": "Volume of first metallic component",
			"min": 0.1, "max": 0.5, "value": 0.3, "step": 0.01,
			"format": "percent"
		},
		"metallic_2_amplitude": {
			"display_name": "Metallic 2 Amplitude",
			"description": "Volume of second metallic component", 
			"min": 0.1, "max": 0.4, "value": 0.2, "step": 0.01,
			"format": "percent"
		},
		"noise_amplitude": {
			"display_name": "Noise Amplitude",
			"description": "Volume of the noise component",
			"min": 0.5, "max": 1.0, "value": 0.8, "step": 0.01,
			"format": "percent"
		},
		"envelope_decay": {
			"display_name": "Envelope Decay",
			"description": "How quickly the volume fades",
			"min": 20.0, "max": 60.0, "value": 40.0, "step": 1.0,
			"format": "float"
		},
		"duration": {
			"display_name": "Duration",
			"description": "Length of the hi-hat hit",
			"min": 0.02, "max": 0.1, "value": 0.05, "step": 0.005,
			"format": "time"
		},
		"volume": {
			"display_name": "Volume",
			"description": "Output volume level",
			"min": 0.1, "max": 1.0, "value": 0.4, "step": 0.01,
			"format": "percent"
		}
	},
	
	AudioStudio.SoundType.COIN_CHIME: {
		"chord_type": {
			"display_name": "Chord Type",
			"description": "Musical chord variation (0=major, 1=sus2, 2=color)",
			"min": 0, "max": 2, "value": 0, "step": 1,
			"format": "int"
		},
		"base_octave": {
			"display_name": "Base Octave",
			"description": "Base octave for the chime (4=C4, 5=C5, 6=C6)",
			"min": 4, "max": 7, "value": 6, "step": 1,
			"format": "int"
		},
		"harmonic_richness": {
			"display_name": "Harmonic Richness",
			"description": "Amount of harmonic content (overtones)",
			"min": 0.1, "max": 0.5, "value": 0.3, "step": 0.01,
			"format": "percent"
		},
		"envelope_decay": {
			"display_name": "Envelope Decay",
			"description": "How quickly the chime fades",
			"min": 8.0, "max": 20.0, "value": 12.0, "step": 0.5,
			"format": "float"
		},
		"duration": {
			"display_name": "Duration",
			"description": "Length of the chime",
			"min": 0.1, "max": 0.4, "value": 0.2, "step": 0.01,
			"format": "time"
		},
		"volume": {
			"display_name": "Volume",
			"description": "Output volume level",
			"min": 0.1, "max": 1.0, "value": 0.35, "step": 0.01,
			"format": "percent"
		}
	},
	
	AudioStudio.SoundType.WALL_HIT_TOM_FILL: {
		"tom1_frequency": {
			"display_name": "Tom 1 Frequency",
			"description": "Frequency of first tom (highest)",
			"min": 150.0, "max": 220.0, "value": 180.0, "step": 5.0,
			"format": "frequency"
		},
		"tom2_frequency": {
			"display_name": "Tom 2 Frequency", 
			"description": "Frequency of second tom (mid)",
			"min": 130.0, "max": 190.0, "value": 160.0, "step": 5.0,
			"format": "frequency"
		},
		"tom3_frequency": {
			"display_name": "Tom 3 Frequency",
			"description": "Frequency of third tom (lowest)",
			"min": 60.0, "max": 120.0, "value": 80.0, "step": 5.0,
			"format": "frequency"
		},
		"tom1_decay": {
			"display_name": "Tom 1 Decay",
			"description": "Decay speed of first tom",
			"min": 20.0, "max": 40.0, "value": 30.0, "step": 1.0,
			"format": "float"
		},
		"tom2_decay": {
			"display_name": "Tom 2 Decay",
			"description": "Decay speed of second tom", 
			"min": 20.0, "max": 40.0, "value": 30.0, "step": 1.0,
			"format": "float"
		},
		"tom3_decay": {
			"display_name": "Tom 3 Decay",
			"description": "Decay speed of third tom",
			"min": 15.0, "max": 25.0, "value": 20.0, "step": 1.0,
			"format": "float"
		},
		"noise_amount": {
			"display_name": "Noise Amount",
			"description": "Amount of noise texture in toms",
			"min": 0.1, "max": 0.4, "value": 0.25, "step": 0.01,
			"format": "percent"
		},
		"duration": {
			"display_name": "Duration",
			"description": "Total length of the tom fill",
			"min": 0.3, "max": 0.6, "value": 0.4, "step": 0.01,
			"format": "time"
		},
		"volume": {
			"display_name": "Volume",
			"description": "Output volume level",
			"min": 0.1, "max": 1.0, "value": 0.75, "step": 0.01,
			"format": "percent"
		}
	},
	
	AudioStudio.SoundType.GUITAR_CHORD: {
		"chord_type": {
			"display_name": "Chord Type",
			"description": "Guitar chord variation (0=Cmaj7, 1=Cmin7, 2=Csus2)",
			"min": 0, "max": 2, "value": 0, "step": 1,
			"format": "int"
		},
		"attack_time": {
			"display_name": "Attack Time",
			"description": "How quickly the chord fades in",
			"min": 1.0, "max": 5.0, "value": 3.0, "step": 0.1,
			"format": "float"
		},
		"sustain_decay": {
			"display_name": "Sustain Decay",
			"description": "How quickly the chord fades during sustain",
			"min": 0.1, "max": 0.5, "value": 0.3, "step": 0.01,
			"format": "float"
		},
		"harmonic_content": {
			"display_name": "Harmonic Content",
			"description": "Amount of harmonic overtones",
			"min": 0.1, "max": 0.3, "value": 0.2, "step": 0.01,
			"format": "percent"
		},
		"fundamental_amplitude": {
			"display_name": "Fundamental Amplitude",
			"description": "Volume of the fundamental frequencies",
			"min": 0.5, "max": 0.8, "value": 0.7, "step": 0.01,
			"format": "percent"
		},
		"ambient_level": {
			"display_name": "Ambient Level",
			"description": "Overall ambient volume",
			"min": 0.1, "max": 0.4, "value": 0.25, "step": 0.01,
			"format": "percent"
		}
	}
}

func _ready():
	setup_preview_audio()
	print("[SoundShaper] Parameter system ready")

func setup_preview_audio():
	preview_player = AudioStreamPlayer.new()
	add_child(preview_player)
	preview_player.volume_db = -6.0
	
	preview_generator = AudioStreamGenerator.new()
	preview_generator.mix_rate = 44100
	preview_generator.buffer_length = 1.0
	preview_player.stream = preview_generator

func load_sound_parameters(sound_type: AudioStudio.SoundType):
	current_sound_type = sound_type
	
	# Load default parameters for this sound type
	sound_parameters = parameter_definitions[sound_type].duplicate(true)
	
	print("[SoundShaper] Loaded parameters for sound type: ", sound_type)

func get_current_parameters() -> Dictionary:
	return sound_parameters

func set_parameter(param_name: String, value: float):
	if param_name in sound_parameters:
		sound_parameters[param_name]["value"] = value
		emit_signal("parameter_changed", param_name, value)

func get_parameter(param_name: String) -> float:
	if param_name in sound_parameters:
		return sound_parameters[param_name]["value"]
	return 0.0

func preview_sound():
	# Generate and play a preview of the current sound
	if not preview_player.playing:
		preview_player.play()
	
	var playback = preview_player.get_stream_playback() as AudioStreamGeneratorPlayback
	if playback:
		generate_sound_preview(playback)

func generate_sound_preview(playback: AudioStreamGeneratorPlayback):
	match current_sound_type:
		AudioStudio.SoundType.KICK_DRUM:
			generate_kick_preview(playback)
		AudioStudio.SoundType.SNARE_DRUM:
			generate_snare_preview(playback)
		AudioStudio.SoundType.HI_HAT:
			generate_hihat_preview(playback)
		AudioStudio.SoundType.COIN_CHIME:
			generate_coin_chime_preview(playback)
		AudioStudio.SoundType.WALL_HIT_TOM_FILL:
			generate_tom_fill_preview(playback)
		AudioStudio.SoundType.GUITAR_CHORD:
			generate_guitar_preview(playback)

func generate_kick_preview(playback: AudioStreamGeneratorPlayback):
	var sample_rate = 44100
	var duration = get_parameter("duration")
	var frames = int(sample_rate * duration)
	var base_freq = get_parameter("base_frequency")
	var pitch_sweep = get_parameter("pitch_sweep_amount")
	var sweep_speed = get_parameter("pitch_sweep_speed")
	var decay = get_parameter("envelope_decay")
	var volume = get_parameter("volume")
	
	for i in frames:
		var time = float(i) / sample_rate
		var envelope = exp(-time * decay)
		var frequency = base_freq + pitch_sweep * exp(-time * sweep_speed)
		var sample = sin(2.0 * PI * frequency * time) * envelope * volume
		playback.push_frame(Vector2(sample, sample))

func generate_snare_preview(playback: AudioStreamGeneratorPlayback):
	var sample_rate = 44100
	var duration = get_parameter("duration")
	var frames = int(sample_rate * duration)
	var tone_freq = get_parameter("tone_frequency")
	var noise_ratio = get_parameter("noise_ratio")
	var tone_amp = get_parameter("tone_amplitude")
	var decay = get_parameter("envelope_decay")
	var volume = get_parameter("volume")
	
	for i in frames:
		var time = float(i) / sample_rate
		var envelope = exp(-time * decay)
		
		var noise = (randf() * 2.0 - 1.0) * noise_ratio
		var tone = sin(2.0 * PI * tone_freq * time) * tone_amp
		
		var sample = (noise + tone) * envelope * volume
		playback.push_frame(Vector2(sample, sample))

func generate_hihat_preview(playback: AudioStreamGeneratorPlayback):
	var sample_rate = 44100
	var duration = get_parameter("duration")
	var frames = int(sample_rate * duration)
	var metal_freq1 = get_parameter("metallic_freq_1")
	var metal_freq2 = get_parameter("metallic_freq_2")
	var metal_amp1 = get_parameter("metallic_1_amplitude")
	var metal_amp2 = get_parameter("metallic_2_amplitude")
	var noise_amp = get_parameter("noise_amplitude")
	var decay = get_parameter("envelope_decay")
	var volume = get_parameter("volume")
	
	for i in frames:
		var time = float(i) / sample_rate
		var envelope = exp(-time * decay)
		
		var noise = (randf() * 2.0 - 1.0) * noise_amp
		var metallic1 = sin(2.0 * PI * metal_freq1 * time) * metal_amp1
		var metallic2 = sin(2.0 * PI * metal_freq2 * time) * metal_amp2
		
		var sample = (noise + metallic1 + metallic2) * envelope * volume
		playback.push_frame(Vector2(sample, sample))

func generate_coin_chime_preview(playback: AudioStreamGeneratorPlayback):
	var sample_rate = 44100
	var duration = get_parameter("duration")
	var frames = int(sample_rate * duration)
	var chord_type = int(get_parameter("chord_type"))
	var base_octave = int(get_parameter("base_octave"))
	var harmonic_richness = get_parameter("harmonic_richness")
	var decay = get_parameter("envelope_decay")
	var volume = get_parameter("volume")
	
	# Define chord variations
	var chord_sets = [
		[1046.5, 1318.5, 1568.0],  # C major triad
		[1174.7, 1318.5, 1568.0],  # C sus2
		[1046.5, 1244.5, 1568.0]   # C with color tone
	]
	
	# Adjust for octave
	var frequencies = chord_sets[chord_type]
	var octave_multiplier = pow(2, base_octave - 6)  # 6 is the base octave for frequencies above
	for i in range(frequencies.size()):
		frequencies[i] *= octave_multiplier
	
	for i in frames:
		var time = float(i) / sample_rate
		var envelope = exp(-time * decay)
		
		var chime_sample = 0.0
		for freq in frequencies:
			var fundamental = sin(2.0 * PI * freq * time) * 0.6
			var harmonic2 = sin(2.0 * PI * freq * 2.0 * time) * harmonic_richness
			var harmonic3 = sin(2.0 * PI * freq * 3.0 * time) * (harmonic_richness * 0.5)
			chime_sample += (fundamental + harmonic2 + harmonic3) / 3.0
		
		var sample = chime_sample * envelope * volume
		playback.push_frame(Vector2(sample, sample))

func generate_tom_fill_preview(playback: AudioStreamGeneratorPlayback):
	var sample_rate = 44100
	var duration = get_parameter("duration")
	var frames = int(sample_rate * duration)
	var tom1_freq = get_parameter("tom1_frequency")
	var tom2_freq = get_parameter("tom2_frequency")
	var tom3_freq = get_parameter("tom3_frequency")
	var tom1_decay = get_parameter("tom1_decay")
	var tom2_decay = get_parameter("tom2_decay")
	var tom3_decay = get_parameter("tom3_decay")
	var noise_amount = get_parameter("noise_amount")
	var volume = get_parameter("volume")
	
	for i in frames:
		var time = float(i) / sample_rate
		var tom_sample = 0.0
		
		# Three tom hits with timing
		if time < 0.08:
			# First tom
			tom_sample = sin(2.0 * PI * tom1_freq * time) * exp(-time * tom1_decay) * 0.8
		elif time < 0.16:
			# Second tom
			var tom2_time = time - 0.08
			tom_sample = sin(2.0 * PI * tom2_freq * tom2_time) * exp(-tom2_time * tom2_decay) * 0.8
		elif time < 0.32:
			# Third tom
			var tom3_time = time - 0.16
			tom_sample = sin(2.0 * PI * tom3_freq * tom3_time) * exp(-tom3_time * tom3_decay) * 1.2
		
		# Add noise texture
		var noise = (randf() * 2.0 - 1.0) * noise_amount
		var envelope = exp(-time * 10.0)
		var sample = (tom_sample + noise) * envelope * volume
		
		playback.push_frame(Vector2(sample, sample))

func generate_guitar_preview(playback: AudioStreamGeneratorPlayback):
	var sample_rate = 44100
	var duration = 2.0  # Fixed duration for guitar preview
	var frames = int(sample_rate * duration)
	var chord_type = int(get_parameter("chord_type"))
	var attack_time = get_parameter("attack_time")
	var sustain_decay = get_parameter("sustain_decay")
	var harmonic_content = get_parameter("harmonic_content")
	var fundamental_amp = get_parameter("fundamental_amplitude")
	var ambient_level = get_parameter("ambient_level")
	
	# Define guitar chord variations
	var chord_frequencies = [
		[261.63, 329.63, 392.00, 493.88],  # Cmaj7
		[261.63, 311.13, 392.00, 466.16],  # Cmin7
		[261.63, 293.66, 392.00]           # Csus2
	]
	
	var frequencies = chord_frequencies[chord_type]
	
	for i in frames:
		var time = float(i) / sample_rate
		var envelope = 1.0 - exp(-time * attack_time)  # Attack
		envelope *= exp(-time * sustain_decay)  # Sustain decay
		
		var chord_sample = 0.0
		for freq in frequencies:
			var fundamental = sin(2.0 * PI * freq * time) * fundamental_amp
			var harmonic = sin(2.0 * PI * freq * 2.0 * time) * harmonic_content
			chord_sample += (fundamental + harmonic) / frequencies.size()
		
		var sample = chord_sample * envelope * ambient_level
		playback.push_frame(Vector2(sample, sample))

func apply_to_game():
	# This would integrate with the main game's audio system
	# For now, just print the current parameters
	print("[SoundShaper] Applying parameters to game:")
	for param_name in sound_parameters:
		var param_data = sound_parameters[param_name]
		print("  ", param_name, ": ", param_data.value)
	
	# TODO: Implement actual integration with GameManager's audio system