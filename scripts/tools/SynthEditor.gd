extends Control
class_name SynthEditor

# Streamlined synth editor for quick sound shaping in-game
# Accessible via 'A' key - clean, simple, effective

enum SoundType {
	KICK_DRUM = 0,
	SNARE_DRUM = 1,
	HI_HAT = 2,
	COIN_CHIME = 3,
	WALL_HIT_TOM = 4,
	GUITAR_CHORD = 5
}

# UI Elements
var background_panel: Panel
var title_label: Label
var sound_selector: OptionButton
var parameter_container: VBoxContainer
var preview_button: Button
var close_button: Button
var waveform_preview: Control

# Audio system
var audio_preview: AudioStreamPlayer
var current_sound_type = SoundType.KICK_DRUM
var sound_parameters = {}

# Sound definitions with user-friendly parameters
var sound_configs = {
	SoundType.KICK_DRUM: {
		"name": "Kick Drum",
		"color": Color(0.8, 0.3, 0.3),
		"parameters": {
			"frequency": {"name": "Pitch", "min": 40, "max": 100, "default": 60, "unit": "Hz"},
			"punch": {"name": "Punch", "min": 0.1, "max": 2.0, "default": 1.0, "unit": ""},
			"decay": {"name": "Decay", "min": 0.05, "max": 0.3, "default": 0.15, "unit": "s"},
			"click": {"name": "Click", "min": 0.0, "max": 0.5, "default": 0.2, "unit": ""}
		}
	},
	SoundType.SNARE_DRUM: {
		"name": "Snare Drum",
		"color": Color(0.8, 0.8, 0.3),
		"parameters": {
			"tone": {"name": "Tone", "min": 100, "max": 400, "default": 200, "unit": "Hz"},
			"noise": {"name": "Noise", "min": 0.0, "max": 1.0, "default": 0.7, "unit": ""},
			"snap": {"name": "Snap", "min": 0.05, "max": 0.2, "default": 0.1, "unit": "s"},
			"crisp": {"name": "Crisp", "min": 20, "max": 60, "default": 50, "unit": ""}
		}
	},
	SoundType.HI_HAT: {
		"name": "Hi-Hat",
		"color": Color(0.3, 0.8, 0.8),
		"parameters": {
			"brightness": {"name": "Brightness", "min": 6000, "max": 15000, "default": 10000, "unit": "Hz"},
			"sharpness": {"name": "Sharpness", "min": 50, "max": 150, "default": 100, "unit": ""},
			"length": {"name": "Length", "min": 0.02, "max": 0.1, "default": 0.05, "unit": "s"},
			"metallic": {"name": "Metallic", "min": 0.0, "max": 1.0, "default": 0.5, "unit": ""}
		}
	},
	SoundType.COIN_CHIME: {
		"name": "Coin Chime",
		"color": Color(1.0, 0.8, 0.3),
		"parameters": {
			"pitch": {"name": "Pitch", "min": 800, "max": 2000, "default": 1200, "unit": "Hz"},
			"shimmer": {"name": "Shimmer", "min": 0.0, "max": 1.0, "default": 0.5, "unit": ""},
			"sustain": {"name": "Sustain", "min": 0.1, "max": 0.4, "default": 0.2, "unit": "s"},
			"harmony": {"name": "Harmony", "min": 0, "max": 2, "default": 0, "unit": ""}
		}
	},
	SoundType.WALL_HIT_TOM: {
		"name": "Wall Hit Tom",
		"color": Color(0.8, 0.3, 0.8),
		"parameters": {
			"low_tom": {"name": "Low Tom", "min": 80, "max": 150, "default": 100, "unit": "Hz"},
			"mid_tom": {"name": "Mid Tom", "min": 120, "max": 200, "default": 140, "unit": "Hz"},
			"high_tom": {"name": "High Tom", "min": 150, "max": 250, "default": 180, "unit": "Hz"},
			"power": {"name": "Power", "min": 0.3, "max": 0.8, "default": 0.4, "unit": "s"}
		}
	},
	SoundType.GUITAR_CHORD: {
		"name": "Guitar Chord",
		"color": Color(0.3, 0.8, 0.3),
		"parameters": {
			"warmth": {"name": "Warmth", "min": 200, "max": 600, "default": 300, "unit": "Hz"},
			"richness": {"name": "Richness", "min": 0.0, "max": 1.0, "default": 0.5, "unit": ""},
			"vibrato": {"name": "Vibrato", "min": 0.0, "max": 0.02, "default": 0.005, "unit": ""},
			"ambient": {"name": "Ambient", "min": 0.1, "max": 0.5, "default": 0.3, "unit": ""}
		}
	}
}

func _ready():
	setup_window()
	setup_ui()
	setup_audio()
	load_sound_type(current_sound_type)
	
	print("[SynthEditor] Ready - Press A in game to open")

func setup_window():
	# Create modal overlay
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modulate = Color(1, 1, 1, 1)  # Full opacity
	mouse_filter = Control.MOUSE_FILTER_STOP  # Block input to game
	
	# Add semi-transparent background
	var overlay = ColorRect.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0, 0, 0, 0.7)
	add_child(overlay)
	
	# Size and center the editor panel
	var editor_width = 800
	var editor_height = 600
	
	background_panel = Panel.new()
	background_panel.size = Vector2(editor_width, editor_height)
	background_panel.position = (get_viewport().get_visible_rect().size - background_panel.size) / 2
	add_child(background_panel)
	
	# Add subtle border and styling
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.15, 0.15, 0.2)
	style_box.border_color = Color(0.4, 0.4, 0.5)
	style_box.border_width_left = 2
	style_box.border_width_right = 2
	style_box.border_width_top = 2
	style_box.border_width_bottom = 2
	style_box.corner_radius_top_left = 8
	style_box.corner_radius_top_right = 8
	style_box.corner_radius_bottom_left = 8
	style_box.corner_radius_bottom_right = 8
	background_panel.add_theme_stylebox_override("panel", style_box)

func setup_ui():
	var main_vbox = VBoxContainer.new()
	main_vbox.anchors_preset = Control.PRESET_FULL_RECT
	main_vbox.offset_left = 20
	main_vbox.offset_top = 20
	main_vbox.offset_right = -20
	main_vbox.offset_bottom = -20
	main_vbox.add_theme_constant_override("separation", 15)
	background_panel.add_child(main_vbox)
	
	# Title and close button
	var header_container = HBoxContainer.new()
	main_vbox.add_child(header_container)
	
	title_label = Label.new()
	title_label.text = "🎛️ Synth Editor"
	title_label.add_theme_font_size_override("font_size", 24)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_container.add_child(title_label)
	
	close_button = Button.new()
	close_button.text = "✕"
	close_button.custom_minimum_size = Vector2(40, 40)
	close_button.add_theme_font_size_override("font_size", 18)
	close_button.pressed.connect(_on_close_pressed)
	header_container.add_child(close_button)
	
	# Sound selector
	var selector_container = VBoxContainer.new()
	main_vbox.add_child(selector_container)
	
	var selector_label = Label.new()
	selector_label.text = "Select Sound:"
	selector_label.add_theme_font_size_override("font_size", 16)
	selector_container.add_child(selector_label)
	
	sound_selector = OptionButton.new()
	sound_selector.custom_minimum_size = Vector2(0, 40)
	for sound_type in sound_configs:
		var config = sound_configs[sound_type]
		sound_selector.add_item(config.name)
		sound_selector.set_item_metadata(sound_selector.get_item_count() - 1, sound_type)
	sound_selector.item_selected.connect(_on_sound_selected)
	selector_container.add_child(sound_selector)
	
	# Main content area (horizontal split)
	var content_container = HBoxContainer.new()
	content_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_container.add_theme_constant_override("separation", 20)
	main_vbox.add_child(content_container)
	
	# Parameters panel
	var params_panel = Panel.new()
	params_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	params_panel.custom_minimum_size = Vector2(400, 0)
	content_container.add_child(params_panel)
	
	var params_vbox = VBoxContainer.new()
	params_vbox.anchors_preset = Control.PRESET_FULL_RECT
	params_vbox.offset_left = 15
	params_vbox.offset_top = 15
	params_vbox.offset_right = -15
	params_vbox.offset_bottom = -15
	params_panel.add_child(params_vbox)
	
	var params_title = Label.new()
	params_title.text = "Parameters"
	params_title.add_theme_font_size_override("font_size", 18)
	params_vbox.add_child(params_title)
	
	var scroll_container = ScrollContainer.new()
	scroll_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	params_vbox.add_child(scroll_container)
	
	parameter_container = VBoxContainer.new()
	parameter_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parameter_container.add_theme_constant_override("separation", 10)
	scroll_container.add_child(parameter_container)
	
	# Waveform preview panel
	var preview_panel = Panel.new()
	preview_panel.custom_minimum_size = Vector2(300, 0)
	content_container.add_child(preview_panel)
	
	var preview_vbox = VBoxContainer.new()
	preview_vbox.anchors_preset = Control.PRESET_FULL_RECT
	preview_vbox.offset_left = 15
	preview_vbox.offset_top = 15
	preview_vbox.offset_right = -15
	preview_vbox.offset_bottom = -15
	preview_panel.add_child(preview_vbox)
	
	var preview_title = Label.new()
	preview_title.text = "Preview"
	preview_title.add_theme_font_size_override("font_size", 18)
	preview_vbox.add_child(preview_title)
	
	waveform_preview = preload("res://scripts/tools/MiniWaveform.gd").new()
	waveform_preview.size_flags_vertical = Control.SIZE_EXPAND_FILL
	preview_vbox.add_child(waveform_preview)
	
	# Preview button and help text
	var bottom_container = VBoxContainer.new()
	bottom_container.add_theme_constant_override("separation", 8)
	main_vbox.add_child(bottom_container)
	
	preview_button = Button.new()
	preview_button.text = "▶ Preview Sound"
	preview_button.custom_minimum_size = Vector2(0, 40)
	preview_button.add_theme_font_size_override("font_size", 16)
	preview_button.pressed.connect(_on_preview_pressed)
	bottom_container.add_child(preview_button)
	
	var help_label = Label.new()
	help_label.text = "💡 Tip: Adjust sliders and click Preview to hear changes • Press ESC to close"
	help_label.add_theme_font_size_override("font_size", 12)
	help_label.modulate = Color(0.7, 0.7, 0.8)
	help_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bottom_container.add_child(help_label)

func setup_audio():
	audio_preview = AudioStreamPlayer.new()
	add_child(audio_preview)
	audio_preview.volume_db = -6.0
	
	var generator = AudioStreamGenerator.new()
	generator.mix_rate = 44100
	generator.buffer_length = 1.0
	audio_preview.stream = generator

func load_sound_type(sound_type: SoundType):
	current_sound_type = sound_type
	var config = sound_configs[sound_type]
	
	# Update title color
	title_label.text = "🎛️ Synth Editor - " + config.name
	title_label.modulate = config.color
	
	# Clear existing parameters
	for child in parameter_container.get_children():
		child.queue_free()
	
	# Reset parameters to defaults
	sound_parameters.clear()
	for param_name in config.parameters:
		var param_config = config.parameters[param_name]
		sound_parameters[param_name] = param_config.default
	
	# Create parameter controls
	for param_name in config.parameters:
		create_parameter_control(param_name, config.parameters[param_name])
	
	# Update preview
	update_waveform_preview()

func create_parameter_control(param_name: String, param_config: Dictionary):
	var control_container = VBoxContainer.new()
	control_container.add_theme_constant_override("separation", 5)
	parameter_container.add_child(control_container)
	
	# Parameter name and value
	var header_container = HBoxContainer.new()
	control_container.add_child(header_container)
	
	var name_label = Label.new()
	name_label.text = param_config.name
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_container.add_child(name_label)
	
	var value_label = Label.new()
	value_label.text = format_value(sound_parameters[param_name], param_config.unit)
	value_label.add_theme_font_size_override("font_size", 12)
	value_label.modulate = Color(0.8, 0.8, 1.0)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.custom_minimum_size = Vector2(80, 0)
	header_container.add_child(value_label)
	
	# Slider control
	var slider = HSlider.new()
	slider.min_value = param_config.min
	slider.max_value = param_config.max
	slider.value = sound_parameters[param_name]
	slider.step = (param_config.max - param_config.min) / 100.0  # 100 steps
	slider.custom_minimum_size = Vector2(0, 30)
	slider.value_changed.connect(_on_parameter_changed.bind(param_name, value_label, param_config.unit))
	control_container.add_child(slider)
	
	# Add visual separator
	var separator = HSeparator.new()
	separator.modulate = Color(1, 1, 1, 0.3)
	control_container.add_child(separator)

func format_value(value: float, unit: String) -> String:
	if unit == "Hz":
		return "%.0f Hz" % value
	elif unit == "s":
		return "%.3f s" % value
	elif unit == "":
		if value < 10:
			return "%.2f" % value
		else:
			return "%.0f" % value
	else:
		return "%.2f %s" % [value, unit]

func _on_parameter_changed(param_name: String, value_label: Label, unit: String, new_value: float):
	sound_parameters[param_name] = new_value
	value_label.text = format_value(new_value, unit)
	update_waveform_preview()

func _on_sound_selected(index: int):
	var sound_type = sound_selector.get_item_metadata(index)
	if sound_type != null:
		load_sound_type(sound_type)

func _on_preview_pressed():
	generate_and_play_sound()

func _on_close_pressed():
	queue_free()

func update_waveform_preview():
	if waveform_preview:
		waveform_preview.update_waveform(current_sound_type, sound_parameters)

func generate_and_play_sound():
	# Generate audio based on current parameters
	var audio_data = generate_current_sound()
	
	if audio_data.size() > 0:
		if not audio_preview.playing:
			audio_preview.play()
		
		var playback = audio_preview.get_stream_playback() as AudioStreamGeneratorPlayback
		if playback:
			AudioGenerator.push_samples_to_playback(playback, audio_data, 1.0)

func generate_current_sound() -> PackedFloat32Array:
	# Generate sound based on current type and parameters
	match current_sound_type:
		SoundType.KICK_DRUM:
			return generate_custom_kick()
		SoundType.SNARE_DRUM:
			return generate_custom_snare()
		SoundType.HI_HAT:
			return generate_custom_hihat()
		SoundType.COIN_CHIME:
			return generate_custom_coin_chime()
		SoundType.WALL_HIT_TOM:
			return generate_custom_tom_fill()
		SoundType.GUITAR_CHORD:
			return generate_custom_guitar()
		_:
			return PackedFloat32Array()

# Custom sound generators using parameters
func generate_custom_kick() -> PackedFloat32Array:
	var frequency = sound_parameters.get("frequency", 60)
	var punch = sound_parameters.get("punch", 1.0)
	var decay_time = sound_parameters.get("decay", 0.15)
	var click_amount = sound_parameters.get("click", 0.2)
	
	var samples = int(44100 * decay_time)
	var audio_data = PackedFloat32Array()
	
	for i in samples:
		var time = float(i) / 44100.0
		var pitch_sweep = frequency * exp(-time * 35.0 * punch)
		var main_tone = sin(2.0 * PI * pitch_sweep * time)
		var click = sin(2.0 * PI * 1500.0 * time) * exp(-time * 100.0) * click_amount
		var envelope = exp(-time * 20.0)
		var sample = (main_tone * 0.8 + click * 0.2) * envelope
		audio_data.append(sample)
	
	return audio_data

func generate_custom_snare() -> PackedFloat32Array:
	var tone_freq = sound_parameters.get("tone", 200)
	var noise_amount = sound_parameters.get("noise", 0.7)
	var duration = sound_parameters.get("snap", 0.1)
	var crisp = sound_parameters.get("crisp", 50)
	
	var samples = int(44100 * duration)
	var audio_data = PackedFloat32Array()
	
	for i in samples:
		var time = float(i) / 44100.0
		var noise = (randf() * 2.0 - 1.0) * noise_amount
		var tone = sin(2.0 * PI * tone_freq * time) * (1.0 - noise_amount)
		var envelope = exp(-time * crisp)
		var sample = (noise + tone) * envelope
		audio_data.append(sample)
	
	return audio_data

func generate_custom_hihat() -> PackedFloat32Array:
	var brightness = sound_parameters.get("brightness", 10000)
	var sharpness = sound_parameters.get("sharpness", 100)
	var duration = sound_parameters.get("length", 0.05)
	var metallic = sound_parameters.get("metallic", 0.5)
	
	var samples = int(44100 * duration)
	var audio_data = PackedFloat32Array()
	
	for i in samples:
		var time = float(i) / 44100.0
		var noise = (randf() * 2.0 - 1.0)
		var metal1 = sin(2.0 * PI * brightness * time) * metallic
		var metal2 = sin(2.0 * PI * brightness * 1.5 * time) * metallic * 0.5
		var envelope = exp(-time * sharpness)
		var sample = (noise + metal1 + metal2) * envelope * 0.5
		audio_data.append(sample)
	
	return audio_data

func generate_custom_coin_chime() -> PackedFloat32Array:
	var base_pitch = sound_parameters.get("pitch", 1200)
	var shimmer = sound_parameters.get("shimmer", 0.5)
	var duration = sound_parameters.get("sustain", 0.2)
	var harmony_type = int(sound_parameters.get("harmony", 0))
	
	var samples = int(44100 * duration)
	var audio_data = PackedFloat32Array()
	
	# Define chord based on harmony type
	var frequencies = []
	match harmony_type:
		0: frequencies = [base_pitch, base_pitch * 1.25, base_pitch * 1.5]  # Major
		1: frequencies = [base_pitch, base_pitch * 1.12, base_pitch * 1.5]  # Sus2
		2: frequencies = [base_pitch, base_pitch * 1.19, base_pitch * 1.5]  # Minor
	
	for i in samples:
		var time = float(i) / 44100.0
		var sample = 0.0
		
		for freq in frequencies:
			var harmonic1 = sin(2.0 * PI * freq * time) * 0.6
			var harmonic2 = sin(2.0 * PI * freq * 2.0 * time) * shimmer * 0.3
			sample += (harmonic1 + harmonic2) / frequencies.size()
		
		var envelope = exp(-time * 8.0)
		sample *= envelope * 0.3
		audio_data.append(sample)
	
	return audio_data

func generate_custom_tom_fill() -> PackedFloat32Array:
	var low_tom = sound_parameters.get("low_tom", 100)
	var mid_tom = sound_parameters.get("mid_tom", 140)
	var high_tom = sound_parameters.get("high_tom", 180)
	var duration = sound_parameters.get("power", 0.4)
	
	var samples = int(44100 * duration)
	var audio_data = PackedFloat32Array()
	
	for i in samples:
		var time = float(i) / 44100.0
		var sample = 0.0
		
		var tom_duration = duration / 3.0
		if time < tom_duration:
			var t = time
			sample = sin(2.0 * PI * high_tom * t) * exp(-t * 25.0)
		elif time < tom_duration * 2:
			var t = time - tom_duration
			sample = sin(2.0 * PI * mid_tom * t) * exp(-t * 25.0)
		else:
			var t = time - tom_duration * 2
			sample = sin(2.0 * PI * low_tom * t) * exp(-t * 25.0) * 1.2
		
		audio_data.append(sample)
	
	return audio_data

func generate_custom_guitar() -> PackedFloat32Array:
	var warmth = sound_parameters.get("warmth", 300)
	var richness = sound_parameters.get("richness", 0.5)
	var vibrato_amount = sound_parameters.get("vibrato", 0.005)
	var ambient_level = sound_parameters.get("ambient", 0.3)
	
	var duration = 1.0  # Fixed duration for preview
	var samples = int(44100 * duration)
	var audio_data = PackedFloat32Array()
	
	# Build chord around warmth frequency
	var frequencies = [warmth, warmth * 1.25, warmth * 1.5, warmth * 1.875]
	
	for i in samples:
		var time = float(i) / 44100.0
		var sample = 0.0
		
		for freq in frequencies:
			var vibrato = 1.0 + sin(2.0 * PI * 5.0 * time) * vibrato_amount
			var fundamental = sin(2.0 * PI * freq * vibrato * time) * 0.7
			var harmonic = sin(2.0 * PI * freq * 2.0 * vibrato * time) * richness * 0.3
			sample += (fundamental + harmonic) / frequencies.size()
		
		var envelope = min(time * 2.0, 1.0) * exp(-time * 0.5)
		sample *= envelope * ambient_level
		audio_data.append(sample)
	
	return audio_data

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			_on_close_pressed()

# Input handling for opening synth editor
static func handle_synth_editor_input(event: InputEvent, parent_node: Node) -> bool:
	if event is InputEventKey and event.pressed and event.keycode == KEY_A:
		open_synth_editor(parent_node)
		return true
	return false

static func open_synth_editor(parent_node: Node):
	var synth_editor = preload("res://scripts/tools/SynthEditor.gd").new()
	parent_node.get_tree().root.add_child(synth_editor)
	print("[SynthEditor] Opened synth editor")