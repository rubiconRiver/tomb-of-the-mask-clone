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

# Sound definitions with comprehensive parameters for each sound type
var sound_types = {
	"Kick Drum": {
		"function": "generate_custom_kick",
		"parameters": {
			"frequency": {"min": 30.0, "max": 120.0, "default": 60.0, "step": 1.0, "label": "Base Frequency (Hz)"},
			"pitch_decay": {"min": 10.0, "max": 50.0, "default": 35.0, "step": 1.0, "label": "Pitch Decay Speed"},
			"amplitude": {"min": 0.1, "max": 1.0, "default": 0.8, "step": 0.05, "label": "Volume"},
			"click_amount": {"min": 0.0, "max": 0.5, "default": 0.2, "step": 0.05, "label": "Click Attack"},
			"duration": {"min": 0.05, "max": 0.5, "default": 0.15, "step": 0.01, "label": "Duration (s)"}
		}
	},
	"Snare Drum": {
		"function": "generate_custom_snare",
		"parameters": {
			"tone_freq": {"min": 150.0, "max": 400.0, "default": 200.0, "step": 5.0, "label": "Tone Frequency (Hz)"},
			"noise_amount": {"min": 0.3, "max": 0.9, "default": 0.7, "step": 0.05, "label": "Noise Amount"},
			"tone_amount": {"min": 0.1, "max": 0.5, "default": 0.3, "step": 0.05, "label": "Tone Amount"},
			"decay_speed": {"min": 15.0, "max": 40.0, "default": 25.0, "step": 1.0, "label": "Decay Speed"},
			"duration": {"min": 0.05, "max": 0.3, "default": 0.1, "step": 0.01, "label": "Duration (s)"}
		}
	},
	"Hi-Hat": {
		"function": "generate_custom_hihat",
		"parameters": {
			"brightness": {"min": 6000.0, "max": 15000.0, "default": 8000.0, "step": 100.0, "label": "Brightness (Hz)"},
			"metallic": {"min": 8000.0, "max": 16000.0, "default": 12000.0, "step": 100.0, "label": "Metallic Freq (Hz)"},
			"noise_amount": {"min": 0.5, "max": 1.0, "default": 0.8, "step": 0.05, "label": "Noise Amount"},
			"decay_speed": {"min": 30.0, "max": 80.0, "default": 40.0, "step": 2.0, "label": "Decay Speed"},
			"duration": {"min": 0.02, "max": 0.2, "default": 0.05, "step": 0.01, "label": "Duration (s)"}
		}
	},
	"Coin Chime": {
		"function": "generate_custom_chime",
		"parameters": {
			"root_freq": {"min": 800.0, "max": 1400.0, "default": 1046.5, "step": 10.0, "label": "Root Note (Hz)"},
			"chord_type": {"min": 0, "max": 2, "default": 0, "step": 1, "label": "Chord Type"},
			"harmonics": {"min": 0.0, "max": 0.5, "default": 0.2, "step": 0.05, "label": "Harmonic Content"},
			"decay_speed": {"min": 8.0, "max": 20.0, "default": 12.0, "step": 1.0, "label": "Decay Speed"},
			"duration": {"min": 0.1, "max": 0.5, "default": 0.2, "step": 0.05, "label": "Duration (s)"}
		}
	},
	"Wall Hit (Tom Fill)": {
		"function": "generate_custom_tom_fill",
		"parameters": {
			"tom1_freq": {"min": 120.0, "max": 250.0, "default": 180.0, "step": 5.0, "label": "High Tom (Hz)"},
			"tom2_freq": {"min": 100.0, "max": 200.0, "default": 160.0, "step": 5.0, "label": "Mid Tom (Hz)"},
			"tom3_freq": {"min": 60.0, "max": 120.0, "default": 80.0, "step": 2.0, "label": "Low Tom (Hz)"},
			"noise_amount": {"min": 0.1, "max": 0.4, "default": 0.25, "step": 0.05, "label": "Noise Texture"},
			"duration": {"min": 0.2, "max": 0.8, "default": 0.4, "step": 0.05, "label": "Duration (s)"}
		}
	},
	"Guitar Chord": {
		"function": "generate_custom_guitar",
		"parameters": {
			"root_freq": {"min": 200.0, "max": 400.0, "default": 261.63, "step": 5.0, "label": "Root Note (Hz)"},
			"chord_type": {"min": 0, "max": 3, "default": 0, "step": 1, "label": "Chord Type"},
			"vibrato_rate": {"min": 3.0, "max": 8.0, "default": 5.0, "step": 0.5, "label": "Vibrato Rate (Hz)"},
			"vibrato_depth": {"min": 0.0, "max": 0.02, "default": 0.005, "step": 0.001, "label": "Vibrato Depth"},
			"duration": {"min": 0.5, "max": 3.0, "default": 1.0, "step": 0.1, "label": "Duration (s)"}
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
	
	# Generate sound based on type with custom parameters
	match function_name:
		"generate_custom_kick":
			return generate_custom_kick_drum(param_values)
		"generate_custom_snare":
			return generate_custom_snare_drum(param_values)
		"generate_custom_hihat":
			return generate_custom_hihat(param_values)
		"generate_custom_chime":
			return generate_custom_coin_chime(param_values)
		"generate_custom_tom_fill":
			return generate_custom_tom_fill(param_values)
		"generate_custom_guitar":
			return generate_custom_guitar_chord(param_values)
		_:
			print("Unknown sound function: ", function_name)
			return PackedFloat32Array()

# Custom sound generation functions with full parameter control

func generate_custom_kick_drum(params: Dictionary) -> PackedFloat32Array:
	var frequency = params.get("frequency", 60.0)
	var pitch_decay = params.get("pitch_decay", 35.0)
	var amplitude = params.get("amplitude", 0.8)
	var click_amount = params.get("click_amount", 0.2)
	var duration = params.get("duration", 0.15)
	
	var samples = int(AudioGenerator.SAMPLE_RATE * duration)
	var audio_data = PackedFloat32Array()
	
	for i in samples:
		var time = float(i) / AudioGenerator.SAMPLE_RATE
		var envelope = exp(-time * 20.0)
		
		# Main tone with controllable pitch decay
		var freq = frequency * exp(-time * pitch_decay)
		var main_tone = sin(2.0 * PI * freq * time)
		
		# Controllable click attack
		var click = sin(2.0 * PI * 1500.0 * time) * exp(-time * 100.0)
		
		var sample = (main_tone * (1.0 - click_amount) + click * click_amount) * envelope * amplitude
		audio_data.append(sample)
	
	return audio_data

func generate_custom_snare_drum(params: Dictionary) -> PackedFloat32Array:
	var tone_freq = params.get("tone_freq", 200.0)
	var noise_amount = params.get("noise_amount", 0.7)
	var tone_amount = params.get("tone_amount", 0.3)
	var decay_speed = params.get("decay_speed", 25.0)
	var duration = params.get("duration", 0.1)
	
	var samples = int(AudioGenerator.SAMPLE_RATE * duration)
	var audio_data = PackedFloat32Array()
	
	for i in samples:
		var time = float(i) / AudioGenerator.SAMPLE_RATE
		var envelope = exp(-time * decay_speed)
		
		# Noise component
		var noise = (randf() * 2.0 - 1.0) * noise_amount
		
		# Tonal component
		var tone = sin(2.0 * PI * tone_freq * time) * tone_amount
		
		var sample = (noise + tone) * envelope
		audio_data.append(sample)
	
	return audio_data

func generate_custom_hihat(params: Dictionary) -> PackedFloat32Array:
	var brightness = params.get("brightness", 8000.0)
	var metallic = params.get("metallic", 12000.0)
	var noise_amount = params.get("noise_amount", 0.8)
	var decay_speed = params.get("decay_speed", 40.0)
	var duration = params.get("duration", 0.05)
	
	var samples = int(AudioGenerator.SAMPLE_RATE * duration)
	var audio_data = PackedFloat32Array()
	
	for i in samples:
		var time = float(i) / AudioGenerator.SAMPLE_RATE
		var envelope = exp(-time * decay_speed)
		
		# High-frequency noise
		var noise = (randf() * 2.0 - 1.0) * noise_amount
		var metallic1 = sin(2.0 * PI * brightness * time) * 0.3
		var metallic2 = sin(2.0 * PI * metallic * time) * 0.2
		
		var sample = (noise + metallic1 + metallic2) * envelope
		audio_data.append(sample)
	
	return audio_data

func generate_custom_coin_chime(params: Dictionary) -> PackedFloat32Array:
	var root_freq = params.get("root_freq", 1046.5)
	var chord_type = int(params.get("chord_type", 0))
	var harmonics = params.get("harmonics", 0.2)
	var decay_speed = params.get("decay_speed", 12.0)
	var duration = params.get("duration", 0.2)
	
	# Different chord types
	var chord_intervals = [
		[1.0, 1.26, 1.5],     # Major triad (C, E, G)
		[1.0, 1.189, 1.5],    # Minor triad (C, Eb, G)
		[1.0, 1.125, 1.5]     # Sus2 (C, D, G)
	]
	
	var intervals = chord_intervals[chord_type % chord_intervals.size()]
	var samples = int(AudioGenerator.SAMPLE_RATE * duration)
	var audio_data = PackedFloat32Array()
	
	for i in samples:
		var time = float(i) / AudioGenerator.SAMPLE_RATE
		var envelope = exp(-time * decay_speed)
		
		var chime_sample = 0.0
		for interval in intervals:
			var freq = root_freq * interval
			# Fundamental + harmonics
			var fundamental = sin(2.0 * PI * freq * time) * 0.6
			var harmonic2 = sin(2.0 * PI * freq * 2.0 * time) * harmonics * 0.3
			var harmonic3 = sin(2.0 * PI * freq * 3.0 * time) * harmonics * 0.1
			chime_sample += (fundamental + harmonic2 + harmonic3) / 3.0
		
		var final_sample = chime_sample * envelope * 0.35
		audio_data.append(final_sample)
	
	return audio_data

func generate_custom_tom_fill(params: Dictionary) -> PackedFloat32Array:
	var tom1_freq = params.get("tom1_freq", 180.0)
	var tom2_freq = params.get("tom2_freq", 160.0) 
	var tom3_freq = params.get("tom3_freq", 80.0)
	var noise_amount = params.get("noise_amount", 0.25)
	var duration = params.get("duration", 0.4)
	
	var samples = int(AudioGenerator.SAMPLE_RATE * duration)
	var audio_data = PackedFloat32Array()
	
	for i in samples:
		var time = float(i) / AudioGenerator.SAMPLE_RATE
		var envelope = exp(-time * 10.0)
		
		var tom_sample = 0.0
		var beat_duration = duration / 3.0  # Three beats
		
		if time < beat_duration:
			# First tom
			tom_sample = sin(2.0 * PI * tom1_freq * time) * exp(-time * 30.0) * 0.8
		elif time < beat_duration * 2:
			# Second tom
			var tom2_time = time - beat_duration
			tom_sample = sin(2.0 * PI * tom2_freq * tom2_time) * exp(-tom2_time * 30.0) * 0.8
		else:
			# Third tom (emphasis)
			var tom3_time = time - beat_duration * 2
			tom_sample = sin(2.0 * PI * tom3_freq * tom3_time) * exp(-tom3_time * 20.0) * 1.2
		
		# Add noise texture
		var noise = (randf() * 2.0 - 1.0) * noise_amount * envelope
		var final_sample = (tom_sample + noise) * envelope * 0.75
		audio_data.append(final_sample)
	
	return audio_data

func generate_custom_guitar_chord(params: Dictionary) -> PackedFloat32Array:
	var root_freq = params.get("root_freq", 261.63)
	var chord_type = int(params.get("chord_type", 0))
	var vibrato_rate = params.get("vibrato_rate", 5.0)
	var vibrato_depth = params.get("vibrato_depth", 0.005)
	var duration = params.get("duration", 1.0)
	
	# Different chord types
	var chord_ratios = [
		[1.0, 1.26, 1.5, 1.89],        # Cmaj7 (C, E, G, B)
		[1.0, 1.189, 1.5, 1.78],       # Cm7 (C, Eb, G, Bb)
		[1.0, 1.125, 1.5, 1.78],       # C7sus2 (C, D, G, Bb)
		[1.0, 1.335, 1.5, 2.0]         # C6 (C, F, G, C)
	]
	
	var ratios = chord_ratios[chord_type % chord_ratios.size()]
	var samples = int(AudioGenerator.SAMPLE_RATE * duration)
	var audio_data = PackedFloat32Array()
	
	for i in samples:
		var time = float(i) / AudioGenerator.SAMPLE_RATE
		var sample = 0.0
		
		# Mix all chord notes with vibrato
		for ratio in ratios:
			var freq = root_freq * ratio
			var vibrato = 1.0 + sin(2.0 * PI * vibrato_rate * time) * vibrato_depth
			sample += sin(2.0 * PI * freq * vibrato * time) * 0.25
		
		# Soft envelope for guitar-like sustain
		var envelope = min(time * 2.0, 1.0) * (1.0 - time / duration)
		sample *= envelope * 0.3
		
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