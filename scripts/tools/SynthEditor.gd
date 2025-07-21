extends Control
class_name SynthEditor

# Modern synth editor with real-time preview using AudioGenerator
var audio_player: AudioStreamPlayer
var background_panel: Panel
var main_vbox: VBoxContainer
var sound_dropdown: OptionButton
var parameter_container: VBoxContainer
var preview_button: Button
var mini_waveform: Control

# Parameter controls storage
var parameter_sliders = {}
var parameter_labels = {}

# Professional sound definitions with comprehensive synthesizer controls
var sound_types = {
	"Kick Drum": {
		"function": "generate_advanced_kick",
		"parameters": {
			# Oscillator
			"frequency": {"min": 20.0, "max": 200.0, "default": 60.0, "step": 1.0, "label": "Base Frequency (Hz)"},
			"osc_type": {"min": 0, "max": 4, "default": 0, "step": 1, "label": "Oscillator (0=Sine 1=Sq 2=Saw 3=Tri 4=Noise)"},
			"pitch_decay": {"min": 5.0, "max": 100.0, "default": 35.0, "step": 1.0, "label": "Pitch Decay Speed"},
			# Envelope (ADSR)
			"attack": {"min": 0.001, "max": 0.1, "default": 0.01, "step": 0.001, "label": "Attack (s)"},
			"decay": {"min": 0.01, "max": 1.0, "default": 0.1, "step": 0.01, "label": "Decay (s)"},
			"sustain": {"min": 0.0, "max": 1.0, "default": 0.3, "step": 0.05, "label": "Sustain Level"},
			"release": {"min": 0.01, "max": 2.0, "default": 0.2, "step": 0.01, "label": "Release (s)"},
			# Effects
			"distortion": {"min": 0.0, "max": 0.8, "default": 0.0, "step": 0.05, "label": "Distortion"},
			"chorus_depth": {"min": 0.0, "max": 0.3, "default": 0.0, "step": 0.01, "label": "Chorus Depth"},
			"reverb": {"min": 0.0, "max": 0.5, "default": 0.0, "step": 0.05, "label": "Reverb"},
			# General
			"amplitude": {"min": 0.1, "max": 2.0, "default": 0.8, "step": 0.05, "label": "Volume"},
			"duration": {"min": 0.05, "max": 2.0, "default": 0.15, "step": 0.01, "label": "Duration (s)"}
		}
	},
	"Snare Drum": {
		"function": "generate_advanced_snare",
		"parameters": {
			# Oscillator  
			"tone_freq": {"min": 80.0, "max": 800.0, "default": 200.0, "step": 5.0, "label": "Tone Frequency (Hz)"},
			"osc_type": {"min": 0, "max": 4, "default": 0, "step": 1, "label": "Tone Oscillator (0=Sin 1=Sq 2=Saw 3=Tri 4=Noise)"},
			"noise_mix": {"min": 0.0, "max": 1.0, "default": 0.7, "step": 0.05, "label": "Noise/Tone Mix"},
			# Envelope
			"attack": {"min": 0.001, "max": 0.05, "default": 0.005, "step": 0.001, "label": "Attack (s)"},
			"decay": {"min": 0.01, "max": 0.5, "default": 0.08, "step": 0.01, "label": "Decay (s)"},
			"sustain": {"min": 0.0, "max": 0.8, "default": 0.2, "step": 0.05, "label": "Sustain Level"},
			"release": {"min": 0.01, "max": 0.5, "default": 0.1, "step": 0.01, "label": "Release (s)"},
			# Filter
			"filter_freq": {"min": 500.0, "max": 8000.0, "default": 3000.0, "step": 100.0, "label": "Filter Cutoff (Hz)"},
			"filter_res": {"min": 0.1, "max": 4.0, "default": 1.0, "step": 0.1, "label": "Filter Resonance"},
			# Effects
			"distortion": {"min": 0.0, "max": 0.6, "default": 0.1, "step": 0.05, "label": "Distortion"},
			"reverb": {"min": 0.0, "max": 0.4, "default": 0.05, "step": 0.05, "label": "Reverb"},
			"amplitude": {"min": 0.1, "max": 1.5, "default": 0.8, "step": 0.05, "label": "Volume"}
		}
	},
	"Hi-Hat": {
		"function": "generate_advanced_hihat",
		"parameters": {
			# Oscillator
			"base_freq": {"min": 4000.0, "max": 20000.0, "default": 8000.0, "step": 100.0, "label": "Base Frequency (Hz)"},
			"noise_type": {"min": 0, "max": 2, "default": 0, "step": 1, "label": "Noise Type (0=White 1=Pink 2=Brown)"},
			"metallic_mix": {"min": 0.0, "max": 1.0, "default": 0.4, "step": 0.05, "label": "Metallic/Noise Mix"},
			# Envelope
			"attack": {"min": 0.001, "max": 0.02, "default": 0.002, "step": 0.001, "label": "Attack (s)"},
			"decay": {"min": 0.005, "max": 0.2, "default": 0.03, "step": 0.005, "label": "Decay (s)"},
			"sustain": {"min": 0.0, "max": 0.3, "default": 0.0, "step": 0.05, "label": "Sustain Level"},
			"release": {"min": 0.005, "max": 0.1, "default": 0.02, "step": 0.005, "label": "Release (s)"},
			# Filter
			"filter_freq": {"min": 6000.0, "max": 20000.0, "default": 12000.0, "step": 200.0, "label": "Filter Cutoff (Hz)"},
			"filter_res": {"min": 0.1, "max": 8.0, "default": 2.0, "step": 0.2, "label": "Filter Resonance"},
			# Effects
			"chorus_rate": {"min": 0.0, "max": 10.0, "default": 0.0, "step": 0.5, "label": "Chorus Rate (Hz)"},
			"reverb": {"min": 0.0, "max": 0.3, "default": 0.0, "step": 0.02, "label": "Reverb"},
			"amplitude": {"min": 0.1, "max": 1.2, "default": 0.6, "step": 0.05, "label": "Volume"}
		}
	},
	"Coin Chime": {
		"function": "generate_advanced_chime",
		"parameters": {
			# Oscillator
			"root_freq": {"min": 200.0, "max": 4000.0, "default": 1046.5, "step": 10.0, "label": "Root Note (Hz)"},
			"osc_type": {"min": 0, "max": 3, "default": 0, "step": 1, "label": "Oscillator (0=Sine 1=Square 2=Saw 3=Triangle)"},
			"chord_type": {"min": 0, "max": 5, "default": 0, "step": 1, "label": "Chord (0=Maj 1=Min 2=Sus2 3=Sus4 4=Dim 5=Aug)"},
			"harmonics": {"min": 0.0, "max": 1.0, "default": 0.3, "step": 0.05, "label": "Harmonic Content"},
			# Envelope
			"attack": {"min": 0.001, "max": 0.2, "default": 0.01, "step": 0.001, "label": "Attack (s)"},
			"decay": {"min": 0.1, "max": 3.0, "default": 0.8, "step": 0.05, "label": "Decay (s)"},
			"sustain": {"min": 0.0, "max": 0.8, "default": 0.3, "step": 0.05, "label": "Sustain Level"},
			"release": {"min": 0.1, "max": 5.0, "default": 1.0, "step": 0.1, "label": "Release (s)"},
			# Effects
			"chorus_depth": {"min": 0.0, "max": 0.4, "default": 0.05, "step": 0.01, "label": "Chorus Depth"},
			"chorus_rate": {"min": 0.1, "max": 8.0, "default": 2.5, "step": 0.1, "label": "Chorus Rate (Hz)"},
			"reverb": {"min": 0.0, "max": 0.8, "default": 0.3, "step": 0.05, "label": "Reverb"},
			"amplitude": {"min": 0.1, "max": 1.0, "default": 0.6, "step": 0.05, "label": "Volume"}
		}
	},
	"Wall Hit (Tom Fill)": {
		"function": "generate_advanced_tom_fill",
		"parameters": {
			# Oscillators for 3 toms
			"tom1_freq": {"min": 80.0, "max": 400.0, "default": 180.0, "step": 5.0, "label": "High Tom (Hz)"},
			"tom2_freq": {"min": 60.0, "max": 300.0, "default": 140.0, "step": 5.0, "label": "Mid Tom (Hz)"},
			"tom3_freq": {"min": 40.0, "max": 200.0, "default": 80.0, "step": 2.0, "label": "Low Tom (Hz)"},
			"osc_type": {"min": 0, "max": 4, "default": 0, "step": 1, "label": "Tom Oscillator (0=Sin 1=Sq 2=Saw 3=Tri 4=Noise)"},
			"noise_mix": {"min": 0.0, "max": 0.8, "default": 0.25, "step": 0.05, "label": "Noise/Tone Mix"},
			# Envelope
			"attack": {"min": 0.001, "max": 0.05, "default": 0.005, "step": 0.001, "label": "Attack (s)"},
			"decay": {"min": 0.05, "max": 0.5, "default": 0.15, "step": 0.01, "label": "Decay (s)"},
			"sustain": {"min": 0.0, "max": 0.6, "default": 0.2, "step": 0.05, "label": "Sustain Level"},
			"release": {"min": 0.05, "max": 1.0, "default": 0.2, "step": 0.01, "label": "Release (s)"},
			# Effects
			"distortion": {"min": 0.0, "max": 0.5, "default": 0.05, "step": 0.05, "label": "Distortion"},
			"reverb": {"min": 0.0, "max": 0.6, "default": 0.15, "step": 0.05, "label": "Reverb"},
			"duration": {"min": 0.2, "max": 2.0, "default": 0.6, "step": 0.05, "label": "Total Duration (s)"},
			"amplitude": {"min": 0.1, "max": 1.5, "default": 0.9, "step": 0.05, "label": "Volume"}
		}
	},
	"Guitar Chord": {
		"function": "generate_advanced_guitar",
		"parameters": {
			# Oscillator
			"root_freq": {"min": 80.0, "max": 800.0, "default": 261.63, "step": 5.0, "label": "Root Note (Hz)"},
			"osc_type": {"min": 0, "max": 3, "default": 0, "step": 1, "label": "Oscillator (0=Sine 1=Square 2=Saw 3=Triangle)"},
			"chord_type": {"min": 0, "max": 7, "default": 0, "step": 1, "label": "Chord (0=Maj7 1=m7 2=7 3=Maj 4=m 5=dim 6=aug 7=sus)"},
			"voices": {"min": 2, "max": 6, "default": 4, "step": 1, "label": "Number of Voices"},
			# Envelope
			"attack": {"min": 0.01, "max": 1.0, "default": 0.1, "step": 0.01, "label": "Attack (s)"},
			"decay": {"min": 0.1, "max": 2.0, "default": 0.3, "step": 0.05, "label": "Decay (s)"},
			"sustain": {"min": 0.3, "max": 1.0, "default": 0.7, "step": 0.05, "label": "Sustain Level"},
			"release": {"min": 0.2, "max": 5.0, "default": 1.0, "step": 0.1, "label": "Release (s)"},
			# Modulation
			"vibrato_rate": {"min": 0.0, "max": 10.0, "default": 5.0, "step": 0.2, "label": "Vibrato Rate (Hz)"},
			"vibrato_depth": {"min": 0.0, "max": 0.05, "default": 0.005, "step": 0.001, "label": "Vibrato Depth"},
			# Effects
			"chorus_depth": {"min": 0.0, "max": 0.6, "default": 0.2, "step": 0.02, "label": "Chorus Depth"},
			"chorus_rate": {"min": 0.1, "max": 5.0, "default": 1.5, "step": 0.1, "label": "Chorus Rate (Hz)"},
			"reverb": {"min": 0.0, "max": 0.8, "default": 0.4, "step": 0.05, "label": "Reverb"},
			"duration": {"min": 0.5, "max": 8.0, "default": 2.0, "step": 0.1, "label": "Duration (s)"},
			"amplitude": {"min": 0.1, "max": 1.0, "default": 0.5, "step": 0.05, "label": "Volume"}
		}
	}
}

var current_sound_type = "Kick Drum"

func _init():
	name = "SynthEditor"
	setup_window()
	setup_audio()
	setup_ui()

func setup_window():
	# Create full-screen overlay with proper centering
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	z_index = 1000  # Ensure it's on top of everything
	
	# Semi-transparent dark overlay
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.7)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)
	
	# Center container for proper positioning
	var center_container = CenterContainer.new()
	center_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center_container)
	
	# Main panel with larger size
	background_panel = Panel.new()
	background_panel.custom_minimum_size = Vector2(900, 700)
	
	# Style the panel with border and shadow effect
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.15, 0.15, 0.2, 0.95)
	style_box.border_width_left = 2
	style_box.border_width_right = 2
	style_box.border_width_top = 2
	style_box.border_width_bottom = 2
	style_box.border_color = Color(0.4, 0.6, 0.8, 0.8)
	style_box.corner_radius_top_left = 10
	style_box.corner_radius_top_right = 10
	style_box.corner_radius_bottom_left = 10
	style_box.corner_radius_bottom_right = 10
	background_panel.add_theme_stylebox_override("panel", style_box)
	
	center_container.add_child(background_panel)

func setup_audio():
	audio_player = AudioStreamPlayer.new()
	add_child(audio_player)

func setup_ui():
	# Main vertical layout
	main_vbox = VBoxContainer.new()
	main_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	main_vbox.add_theme_constant_override("separation", 20)
	background_panel.add_child(main_vbox)
	
	# Add margin
	var margin_container = MarginContainer.new()
	margin_container.add_theme_constant_override("margin_left", 30)
	margin_container.add_theme_constant_override("margin_right", 30)
	margin_container.add_theme_constant_override("margin_top", 30)
	margin_container.add_theme_constant_override("margin_bottom", 30)
	main_vbox.add_child(margin_container)
	
	var content_vbox = VBoxContainer.new()
	content_vbox.add_theme_constant_override("separation", 25)
	margin_container.add_child(content_vbox)
	
	# Title
	var title_label = Label.new()
	title_label.text = "🎵 SYNTH EDITOR"
	title_label.add_theme_font_size_override("font_size", 32)
	title_label.add_theme_color_override("font_color", Color(0.9, 0.9, 1.0))
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content_vbox.add_child(title_label)
	
	# Sound selection
	setup_sound_selection(content_vbox)
	
	# Parameter controls
	setup_parameter_controls(content_vbox)
	
	# Mini waveform preview
	setup_mini_waveform(content_vbox)
	
	# Control buttons
	setup_control_buttons(content_vbox)

func setup_sound_selection(parent):
	var selection_vbox = VBoxContainer.new()
	parent.add_child(selection_vbox)
	
	var selection_label = Label.new()
	selection_label.text = "Select Sound Type:"
	selection_label.add_theme_font_size_override("font_size", 18)
	selection_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.9))
	selection_vbox.add_child(selection_label)
	
	sound_dropdown = OptionButton.new()
	sound_dropdown.custom_minimum_size = Vector2(300, 40)
	
	# Populate dropdown
	for sound_name in sound_types.keys():
		sound_dropdown.add_item(sound_name)
	
	sound_dropdown.selected = 0
	sound_dropdown.item_selected.connect(_on_sound_type_changed)
	selection_vbox.add_child(sound_dropdown)

func setup_parameter_controls(parent):
	var params_label = Label.new()
	params_label.text = "Parameters:"
	params_label.add_theme_font_size_override("font_size", 18)
	params_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.9))
	parent.add_child(params_label)
	
	# Container for parameter controls
	parameter_container = VBoxContainer.new()
	parameter_container.add_theme_constant_override("separation", 15)
	parent.add_child(parameter_container)
	
	# Initially populate with first sound type
	update_parameter_controls()

func setup_mini_waveform(parent):
	var waveform_label = Label.new()
	waveform_label.text = "Waveform Preview:"
	waveform_label.add_theme_font_size_override("font_size", 18)
	waveform_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.9))
	parent.add_child(waveform_label)
	
	mini_waveform = preload("res://scripts/tools/MiniWaveform.gd").new()
	mini_waveform.custom_minimum_size = Vector2(600, 120)
	parent.add_child(mini_waveform)

func setup_control_buttons(parent):
	var button_hbox = HBoxContainer.new()
	button_hbox.add_theme_constant_override("separation", 20)
	button_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	parent.add_child(button_hbox)
	
	# Preview button
	preview_button = Button.new()
	preview_button.text = "🔊 Preview Sound"
	preview_button.custom_minimum_size = Vector2(150, 50)
	preview_button.add_theme_font_size_override("font_size", 16)
	preview_button.pressed.connect(_on_preview_pressed)
	button_hbox.add_child(preview_button)
	
	# Close button
	var close_button = Button.new()
	close_button.text = "✕ Close"
	close_button.custom_minimum_size = Vector2(120, 50)
	close_button.add_theme_font_size_override("font_size", 16)
	close_button.pressed.connect(_on_close_pressed)
	button_hbox.add_child(close_button)

func update_parameter_controls():
	# Clear existing controls
	for child in parameter_container.get_children():
		child.queue_free()
	parameter_sliders.clear()
	parameter_labels.clear()
	
	var sound_config = sound_types[current_sound_type]
	var parameters = sound_config.get("parameters", {})
	
	if parameters.is_empty():
		var no_params_label = Label.new()
		no_params_label.text = "This sound has no adjustable parameters."
		no_params_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
		no_params_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		parameter_container.add_child(no_params_label)
		return
	
	# Create controls for each parameter
	for param_name in parameters.keys():
		var param_config = parameters[param_name]
		create_parameter_control(param_name, param_config)

func create_parameter_control(param_name: String, config: Dictionary):
	var param_hbox = HBoxContainer.new()
	param_hbox.add_theme_constant_override("separation", 15)
	parameter_container.add_child(param_hbox)
	
	# Parameter label with custom label text
	var label = Label.new()
	var label_text = config.get("label", param_name.capitalize())
	label.text = label_text + ":"
	label.custom_minimum_size = Vector2(180, 0)
	label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.9))
	param_hbox.add_child(label)
	
	# Parameter slider
	var slider = HSlider.new()
	slider.min_value = config.get("min", 0.0)
	slider.max_value = config.get("max", 1.0)
	slider.step = config.get("step", 0.01)
	slider.value = config.get("default", 0.5)
	slider.custom_minimum_size = Vector2(300, 30)
	param_hbox.add_child(slider)
	
	# Value label with better formatting
	var value_label = Label.new()
	var value = slider.value
	# Format based on parameter type
	if param_name.ends_with("_type"):
		value_label.text = str(int(value))
	elif value >= 1000:
		value_label.text = str(int(value))
	elif value >= 1:
		value_label.text = "%.1f" % value
	else:
		value_label.text = "%.3f" % value
	value_label.custom_minimum_size = Vector2(80, 0)
	value_label.add_theme_color_override("font_color", Color(0.9, 0.9, 1.0))
	param_hbox.add_child(value_label)
	
	# Store references
	parameter_sliders[param_name] = slider
	parameter_labels[param_name] = value_label
	
	# Connect slider to update label and waveform
	slider.value_changed.connect(_on_parameter_changed.bind(param_name))

func _on_sound_type_changed(index: int):
	current_sound_type = sound_dropdown.get_item_text(index)
	update_parameter_controls()
	update_waveform_preview()

func _on_parameter_changed(param_name: String, value: float):
	# Update value label with proper formatting
	if param_name in parameter_labels:
		var formatted_value: String
		if param_name.ends_with("_type"):
			formatted_value = str(int(value))
		elif value >= 1000:
			formatted_value = str(int(value))
		elif value >= 1:
			formatted_value = "%.1f" % value
		else:
			formatted_value = "%.3f" % value
		parameter_labels[param_name].text = formatted_value
	
	# Update waveform preview
	update_waveform_preview()

func _on_preview_pressed():
	play_current_sound()

func _on_close_pressed():
	close_editor()

func play_current_sound():
	var audio_data = generate_current_sound()
	if audio_data.size() > 0:
		AudioGenerator.play_samples_on_player(audio_player, audio_data)

func generate_current_sound() -> PackedFloat32Array:
	var sound_config = sound_types[current_sound_type]
	var function_name = sound_config["function"]
	var parameters = sound_config.get("parameters", {})
	
	# Get current parameter values
	var param_values = {}
	for param_name in parameters.keys():
		if param_name in parameter_sliders:
			param_values[param_name] = parameter_sliders[param_name].value
	
	# Generate sound based on type with advanced parameters
	match function_name:
		"generate_advanced_kick":
			return generate_advanced_kick_drum(param_values)
		"generate_advanced_snare":
			return generate_advanced_snare_drum(param_values)
		"generate_advanced_hihat":
			return generate_advanced_hihat(param_values)
		"generate_advanced_chime":
			return generate_advanced_coin_chime(param_values)
		"generate_advanced_tom_fill":
			return generate_advanced_tom_fill(param_values)
		"generate_advanced_guitar":
			return generate_advanced_guitar_chord(param_values)
		_:
			print("Unknown sound function: ", function_name)
			return PackedFloat32Array()

# Advanced sound generation functions with professional synthesizer controls

# Utility functions for advanced synthesis
func generate_oscillator(osc_type: int, frequency: float, time: float, phase: float = 0.0) -> float:
	match osc_type:
		0: # Sine
			return sin(2.0 * PI * frequency * time + phase)
		1: # Square
			return sign(sin(2.0 * PI * frequency * time + phase))
		2: # Sawtooth
			return 2.0 * fmod(frequency * time + phase / (2.0 * PI), 1.0) - 1.0
		3: # Triangle
			var t = fmod(frequency * time + phase / (2.0 * PI), 1.0)
			return 4.0 * abs(t - 0.5) - 1.0
		4: # Noise
			return randf() * 2.0 - 1.0
		_:
			return 0.0

func apply_adsr_envelope(time: float, duration: float, attack: float, decay: float, sustain: float, release: float) -> float:
	if time < attack:
		return time / attack
	elif time < attack + decay:
		var decay_progress = (time - attack) / decay
		return 1.0 - (1.0 - sustain) * decay_progress
	elif time < duration - release:
		return sustain
	else:
		var release_progress = (time - (duration - release)) / release
		return sustain * (1.0 - release_progress)

func apply_distortion(sample: float, amount: float) -> float:
	if amount <= 0.0:
		return sample
	var drive = 1.0 + amount * 10.0
	var distorted = sample * drive
	return tanh(distorted) / drive * (1.0 + amount * 0.5)

func apply_chorus(sample: float, time: float, depth: float, rate: float, voices: int = 3) -> float:
	if depth <= 0.0:
		return sample
	
	var chorus_sample = sample
	for v in range(1, voices + 1):
		var delay_time = 0.01 + depth * 0.02 * sin(2.0 * PI * rate * time + v * PI / voices)
		var delayed_sample = sample * 0.7  # Simplified delay
		chorus_sample += delayed_sample * (depth / voices)
	
	return chorus_sample

func apply_reverb(sample: float, amount: float) -> float:
	if amount <= 0.0:
		return sample
	# Simplified reverb simulation
	var reverb_tail = sample * amount * 0.3
	return sample + reverb_tail

func apply_filter(sample: float, frequency: float, resonance: float, sample_rate: float) -> float:
	# Simplified lowpass filter simulation
	var cutoff = min(frequency / sample_rate * 2.0, 0.99)
	var filtered = sample * cutoff + sample * (1.0 - cutoff) * resonance * 0.1
	return filtered

func generate_advanced_kick_drum(params: Dictionary) -> PackedFloat32Array:
	var frequency = params.get("frequency", 60.0)
	var osc_type = int(params.get("osc_type", 0))
	var pitch_decay = params.get("pitch_decay", 35.0)
	var attack = params.get("attack", 0.01)
	var decay = params.get("decay", 0.1)
	var sustain = params.get("sustain", 0.3)
	var release = params.get("release", 0.2)
	var distortion = params.get("distortion", 0.0)
	var chorus_depth = params.get("chorus_depth", 0.0)
	var reverb = params.get("reverb", 0.0)
	var amplitude = params.get("amplitude", 0.8)
	var duration = params.get("duration", 0.15)
	
	var samples = int(AudioGenerator.SAMPLE_RATE * duration)
	var audio_data = PackedFloat32Array()
	
	for i in samples:
		var time = float(i) / AudioGenerator.SAMPLE_RATE
		
		# Dynamic frequency with pitch decay
		var current_freq = frequency * exp(-time * pitch_decay)
		
		# Generate oscillator
		var sample = generate_oscillator(osc_type, current_freq, time)
		
		# Apply ADSR envelope
		var envelope = apply_adsr_envelope(time, duration, attack, decay, sustain, release)
		sample *= envelope
		
		# Apply effects
		sample = apply_distortion(sample, distortion)
		sample = apply_chorus(sample, time, chorus_depth, 2.0)
		sample = apply_reverb(sample, reverb)
		
		# Final amplitude
		sample *= amplitude
		
		audio_data.append(sample)
	
	return audio_data

func generate_advanced_snare_drum(params: Dictionary) -> PackedFloat32Array:
	var tone_freq = params.get("tone_freq", 200.0)
	var osc_type = int(params.get("osc_type", 0))
	var noise_mix = params.get("noise_mix", 0.7)
	var attack = params.get("attack", 0.005)
	var decay = params.get("decay", 0.08)
	var sustain = params.get("sustain", 0.2)
	var release = params.get("release", 0.1)
	var filter_freq = params.get("filter_freq", 3000.0)
	var filter_res = params.get("filter_res", 1.0)
	var distortion = params.get("distortion", 0.1)
	var reverb = params.get("reverb", 0.05)
	var amplitude = params.get("amplitude", 0.8)
	
	var duration = attack + decay + release + 0.05
	var samples = int(AudioGenerator.SAMPLE_RATE * duration)
	var audio_data = PackedFloat32Array()
	
	for i in samples:
		var time = float(i) / AudioGenerator.SAMPLE_RATE
		
		# Generate noise and tone components
		var noise = generate_oscillator(4, 0.0, time)  # Noise oscillator
		var tone = generate_oscillator(osc_type, tone_freq, time)
		
		# Mix noise and tone
		var sample = lerp(tone, noise, noise_mix)
		
		# Apply ADSR envelope
		var envelope = apply_adsr_envelope(time, duration, attack, decay, sustain, release)
		sample *= envelope
		
		# Apply filter
		sample = apply_filter(sample, filter_freq, filter_res, AudioGenerator.SAMPLE_RATE)
		
		# Apply effects
		sample = apply_distortion(sample, distortion)
		sample = apply_reverb(sample, reverb)
		
		# Final amplitude
		sample *= amplitude
		
		audio_data.append(sample)
	
	return audio_data

func generate_advanced_hihat(params: Dictionary) -> PackedFloat32Array:
	var base_freq = params.get("base_freq", 8000.0)
	var noise_type = int(params.get("noise_type", 0))
	var metallic_mix = params.get("metallic_mix", 0.4)
	var attack = params.get("attack", 0.002)
	var decay = params.get("decay", 0.03)
	var sustain = params.get("sustain", 0.0)
	var release = params.get("release", 0.02)
	var filter_freq = params.get("filter_freq", 12000.0)
	var filter_res = params.get("filter_res", 2.0)
	var chorus_rate = params.get("chorus_rate", 0.0)
	var reverb = params.get("reverb", 0.0)
	var amplitude = params.get("amplitude", 0.6)
	
	var duration = attack + decay + release + 0.01
	var samples = int(AudioGenerator.SAMPLE_RATE * duration)
	var audio_data = PackedFloat32Array()
	
	for i in samples:
		var time = float(i) / AudioGenerator.SAMPLE_RATE
		
		# Generate different noise types
		var noise: float
		match noise_type:
			0: # White noise
				noise = generate_oscillator(4, 0.0, time)
			1: # Pink noise (simplified)
				noise = generate_oscillator(4, 0.0, time) * 0.7
			2: # Brown noise (simplified)
				noise = generate_oscillator(4, 0.0, time) * 0.5
			_:
				noise = generate_oscillator(4, 0.0, time)
		
		# High frequency metallic components
		var metallic = sin(2.0 * PI * base_freq * time) + sin(2.0 * PI * base_freq * 1.5 * time) * 0.5
		
		# Mix noise and metallic
		var sample = lerp(noise, metallic, metallic_mix)
		
		# Apply ADSR envelope
		var envelope = apply_adsr_envelope(time, duration, attack, decay, sustain, release)
		sample *= envelope
		
		# Apply filter
		sample = apply_filter(sample, filter_freq, filter_res, AudioGenerator.SAMPLE_RATE)
		
		# Apply effects
		if chorus_rate > 0.0:
			sample = apply_chorus(sample, time, 0.1, chorus_rate)
		sample = apply_reverb(sample, reverb)
		
		# Final amplitude
		sample *= amplitude
		
		audio_data.append(sample)
	
	return audio_data

func generate_advanced_coin_chime(params: Dictionary) -> PackedFloat32Array:
	var root_freq = params.get("root_freq", 1046.5)
	var osc_type = int(params.get("osc_type", 0))
	var chord_type = int(params.get("chord_type", 0))
	var harmonics = params.get("harmonics", 0.3)
	var attack = params.get("attack", 0.01)
	var decay = params.get("decay", 0.8)
	var sustain = params.get("sustain", 0.3)
	var release = params.get("release", 1.0)
	var chorus_depth = params.get("chorus_depth", 0.05)
	var chorus_rate = params.get("chorus_rate", 2.5)
	var reverb = params.get("reverb", 0.3)
	var amplitude = params.get("amplitude", 0.6)
	
	# Extended chord types
	var chord_intervals = [
		[1.0, 1.26, 1.5],           # Major triad
		[1.0, 1.189, 1.5],          # Minor triad
		[1.0, 1.125, 1.5],          # Sus2
		[1.0, 1.335, 1.5],          # Sus4
		[1.0, 1.189, 1.414],        # Diminished
		[1.0, 1.26, 1.587]          # Augmented
	]
	
	var intervals = chord_intervals[chord_type % chord_intervals.size()]
	var duration = attack + decay + release
	var samples = int(AudioGenerator.SAMPLE_RATE * duration)
	var audio_data = PackedFloat32Array()
	
	for i in samples:
		var time = float(i) / AudioGenerator.SAMPLE_RATE
		
		var chime_sample = 0.0
		for interval in intervals:
			var freq = root_freq * interval
			
			# Generate oscillator with harmonics
			var fundamental = generate_oscillator(osc_type, freq, time)
			var harmonic2 = generate_oscillator(osc_type, freq * 2.0, time) * harmonics * 0.5
			var harmonic3 = generate_oscillator(osc_type, freq * 3.0, time) * harmonics * 0.25
			
			chime_sample += (fundamental + harmonic2 + harmonic3) / intervals.size()
		
		# Apply ADSR envelope
		var envelope = apply_adsr_envelope(time, duration, attack, decay, sustain, release)
		chime_sample *= envelope
		
		# Apply effects
		chime_sample = apply_chorus(chime_sample, time, chorus_depth, chorus_rate)
		chime_sample = apply_reverb(chime_sample, reverb)
		
		# Final amplitude
		chime_sample *= amplitude
		
		audio_data.append(chime_sample)
	
	return audio_data

func generate_advanced_tom_fill(params: Dictionary) -> PackedFloat32Array:
	var tom1_freq = params.get("tom1_freq", 180.0)
	var tom2_freq = params.get("tom2_freq", 140.0)
	var tom3_freq = params.get("tom3_freq", 80.0)
	var osc_type = int(params.get("osc_type", 0))
	var noise_mix = params.get("noise_mix", 0.25)
	var attack = params.get("attack", 0.005)
	var decay = params.get("decay", 0.15)
	var sustain = params.get("sustain", 0.2)
	var release = params.get("release", 0.2)
	var distortion = params.get("distortion", 0.05)
	var reverb = params.get("reverb", 0.15)
	var duration = params.get("duration", 0.6)
	var amplitude = params.get("amplitude", 0.9)
	
	var samples = int(AudioGenerator.SAMPLE_RATE * duration)
	var audio_data = PackedFloat32Array()
	var beat_duration = duration / 3.0
	
	for i in samples:
		var time = float(i) / AudioGenerator.SAMPLE_RATE
		var tom_sample = 0.0
		var local_time = 0.0
		var freq = 0.0
		
		# Determine which tom and local timing
		if time < beat_duration:
			freq = tom1_freq
			local_time = time
		elif time < beat_duration * 2:
			freq = tom2_freq
			local_time = time - beat_duration
		else:
			freq = tom3_freq
			local_time = time - beat_duration * 2
		
		# Generate tom with noise mix
		var tone = generate_oscillator(osc_type, freq, local_time)
		var noise = generate_oscillator(4, 0.0, time)
		tom_sample = lerp(tone, noise, noise_mix)
		
		# Apply ADSR envelope
		var envelope = apply_adsr_envelope(local_time, beat_duration, attack, decay, sustain, release)
		tom_sample *= envelope
		
		# Apply effects
		tom_sample = apply_distortion(tom_sample, distortion)
		tom_sample = apply_reverb(tom_sample, reverb)
		
		# Final amplitude
		tom_sample *= amplitude
		
		audio_data.append(tom_sample)
	
	return audio_data

func generate_advanced_guitar_chord(params: Dictionary) -> PackedFloat32Array:
	var root_freq = params.get("root_freq", 261.63)
	var osc_type = int(params.get("osc_type", 0))
	var chord_type = int(params.get("chord_type", 0))
	var voices = int(params.get("voices", 4))
	var attack = params.get("attack", 0.1)
	var decay = params.get("decay", 0.3)
	var sustain = params.get("sustain", 0.7)
	var release = params.get("release", 1.0)
	var vibrato_rate = params.get("vibrato_rate", 5.0)
	var vibrato_depth = params.get("vibrato_depth", 0.005)
	var chorus_depth = params.get("chorus_depth", 0.2)
	var chorus_rate = params.get("chorus_rate", 1.5)
	var reverb = params.get("reverb", 0.4)
	var duration = params.get("duration", 2.0)
	var amplitude = params.get("amplitude", 0.5)
	
	# Extended chord types
	var chord_ratios = [
		[1.0, 1.26, 1.5, 1.89],        # Cmaj7
		[1.0, 1.189, 1.5, 1.78],       # Cm7
		[1.0, 1.26, 1.5, 1.78],        # C7
		[1.0, 1.26, 1.5],              # Major
		[1.0, 1.189, 1.5],             # Minor
		[1.0, 1.189, 1.414, 1.78],     # Diminished
		[1.0, 1.26, 1.587],            # Augmented
		[1.0, 1.125, 1.5]              # Sus2
	]
	
	var ratios = chord_ratios[chord_type % chord_ratios.size()]
	ratios = ratios.slice(0, min(voices, ratios.size()))
	
	var samples = int(AudioGenerator.SAMPLE_RATE * duration)
	var audio_data = PackedFloat32Array()
	
	for i in samples:
		var time = float(i) / AudioGenerator.SAMPLE_RATE
		var sample = 0.0
		
		# Mix all chord voices
		for ratio in ratios:
			var freq = root_freq * ratio
			
			# Apply vibrato
			var vibrato = 1.0 + sin(2.0 * PI * vibrato_rate * time) * vibrato_depth
			var voice_sample = generate_oscillator(osc_type, freq * vibrato, time)
			
			sample += voice_sample / ratios.size()
		
		# Apply ADSR envelope
		var envelope = apply_adsr_envelope(time, duration, attack, decay, sustain, release)
		sample *= envelope
		
		# Apply effects
		sample = apply_chorus(sample, time, chorus_depth, chorus_rate)
		sample = apply_reverb(sample, reverb)
		
		# Final amplitude
		sample *= amplitude
		
		audio_data.append(sample)
	
	return audio_data

func update_waveform_preview():
	if mini_waveform:
		var audio_data = generate_current_sound()
		mini_waveform.update_waveform(audio_data, current_sound_type)

func close_editor():
	queue_free()

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		close_editor()
		get_viewport().set_input_as_handled()