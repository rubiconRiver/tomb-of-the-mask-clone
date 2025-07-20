extends Control
class_name AudioStudio

# Main AudioStudio tool for shaping procedural game sounds
# Provides real-time parameter control and preview for all synthesized audio

enum SoundType {
	KICK_DRUM,
	SNARE_DRUM,
	HI_HAT,
	COIN_CHIME,
	WALL_HIT_TOM_FILL,
	GUITAR_CHORD
}

var current_sound_type = SoundType.KICK_DRUM
var window: Window

# UI Nodes (created dynamically)
var sound_type_panel: Panel
var parameter_panel: Panel
var visualization_panel: Panel
var sound_type_list: ItemList
var parameter_scroll: ScrollContainer
var parameter_container: VBoxContainer
var waveform_display: Control
var preview_button: Button
var apply_button: Button

# Audio components
var audio_player: AudioStreamPlayer
var audio_generator: AudioStreamGenerator
var sound_shaper: SoundShaper

# Sound type data
var sound_types = {
	SoundType.KICK_DRUM: {
		"name": "Kick Drum",
		"description": "Deep punchy kick for beats 1 & 3",
		"color": Color(0.8, 0.3, 0.3)
	},
	SoundType.SNARE_DRUM: {
		"name": "Snare Drum", 
		"description": "Crisp snare for beats 2 & 4",
		"color": Color(0.8, 0.8, 0.3)
	},
	SoundType.HI_HAT: {
		"name": "Hi-Hat",
		"description": "Metallic hi-hat on 8th notes",
		"color": Color(0.3, 0.8, 0.8)
	},
	SoundType.COIN_CHIME: {
		"name": "Coin Chime",
		"description": "Melodic chime when collecting coins",
		"color": Color(0.8, 0.8, 0.3)
	},
	SoundType.WALL_HIT_TOM_FILL: {
		"name": "Wall Hit Tom Fill",
		"description": "3-tom sequence when hitting walls",
		"color": Color(0.8, 0.3, 0.8)
	},
	SoundType.GUITAR_CHORD: {
		"name": "Guitar Chord",
		"description": "Sustained ambient chord during movement",
		"color": Color(0.3, 0.8, 0.3)
	}
}

func _ready():
	setup_window_size()
	setup_audio_system()
	setup_ui_layout()
	setup_sound_shaper()
	setup_sound_type_list()
	load_sound_type(current_sound_type)
	
	print("[AudioStudio] Ready - Real-time audio synthesis tool loaded")

func setup_window_size():
	# Get the main window and configure it for the audio studio
	window = get_window()
	if window:
		var studio_width = 1600
		var studio_height = 1000
		window.size = Vector2i(studio_width, studio_height)
		window.title = "Audio Studio - Sound Design Tool"
		
		# Center the window
		var screen_size = DisplayServer.screen_get_size()
		var window_pos = (screen_size - Vector2i(studio_width, studio_height)) / 2
		window.position = window_pos

func setup_audio_system():
	# Create audio system for real-time preview
	audio_player = AudioStreamPlayer.new()
	add_child(audio_player)
	audio_player.volume_db = -6.0
	
	# Create audio generator for synthesis
	audio_generator = AudioStreamGenerator.new()
	audio_generator.mix_rate = 44100
	audio_generator.buffer_length = 1.0
	audio_player.stream = audio_generator

func setup_ui_layout():
	# Create main container with proper spacing
	var main_container = HBoxContainer.new()
	main_container.add_theme_constant_override("separation", 30)
	main_container.anchors_preset = Control.PRESET_FULL_RECT
	main_container.offset_left = 30
	main_container.offset_top = 30
	main_container.offset_right = -30
	main_container.offset_bottom = -30
	add_child(main_container)
	
	# Sound Type Panel (250px wide)
	sound_type_panel = Panel.new()
	sound_type_panel.custom_minimum_size = Vector2(250, 0)
	main_container.add_child(sound_type_panel)
	
	# First separator
	var separator1 = VSeparator.new()
	separator1.custom_minimum_size = Vector2(30, 0)
	main_container.add_child(separator1)
	
	# Parameter Panel (expandable)
	parameter_panel = Panel.new()
	parameter_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_container.add_child(parameter_panel)
	
	# Second separator
	var separator2 = VSeparator.new()
	separator2.custom_minimum_size = Vector2(30, 0)
	main_container.add_child(separator2)
	
	# Visualization Panel (420px wide)
	visualization_panel = Panel.new()
	visualization_panel.custom_minimum_size = Vector2(420, 0)
	main_container.add_child(visualization_panel)
	
	setup_sound_type_panel()
	setup_parameter_panel()
	setup_visualization_panel()

func setup_sound_type_panel():
	var vbox = VBoxContainer.new()
	vbox.anchors_preset = Control.PRESET_FULL_RECT
	vbox.offset_left = 15
	vbox.offset_top = 15
	vbox.offset_right = -15
	vbox.offset_bottom = -15
	sound_type_panel.add_child(vbox)
	
	# Title
	var title = Label.new()
	title.text = "Sound Types"
	title.add_theme_font_size_override("font_size", 18)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	# Add some spacing
	var spacer1 = Control.new()
	spacer1.custom_minimum_size = Vector2(0, 15)
	vbox.add_child(spacer1)
	
	# Sound type list
	sound_type_list = ItemList.new()
	sound_type_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sound_type_list.item_selected.connect(_on_sound_type_selected)
	vbox.add_child(sound_type_list)

func setup_parameter_panel():
	var vbox = VBoxContainer.new()
	vbox.anchors_preset = Control.PRESET_FULL_RECT
	vbox.offset_left = 15
	vbox.offset_top = 15
	vbox.offset_right = -15
	vbox.offset_bottom = -15
	parameter_panel.add_child(vbox)
	
	# Title with current sound type
	var title = Label.new()
	title.text = "Parameters"
	title.add_theme_font_size_override("font_size", 18)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	# Add some spacing
	var spacer1 = Control.new()
	spacer1.custom_minimum_size = Vector2(0, 15)
	vbox.add_child(spacer1)
	
	# Scrollable parameter container
	parameter_scroll = ScrollContainer.new()
	parameter_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parameter_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(parameter_scroll)
	
	parameter_container = VBoxContainer.new()
	parameter_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parameter_scroll.add_child(parameter_container)
	
	# Add control buttons at bottom
	var spacer2 = Control.new()
	spacer2.custom_minimum_size = Vector2(0, 15)
	vbox.add_child(spacer2)
	
	var button_container = HBoxContainer.new()
	button_container.add_theme_constant_override("separation", 10)
	vbox.add_child(button_container)
	
	preview_button = Button.new()
	preview_button.text = "Preview"
	preview_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preview_button.pressed.connect(_on_preview_pressed)
	button_container.add_child(preview_button)
	
	apply_button = Button.new()
	apply_button.text = "Apply to Game"
	apply_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	apply_button.pressed.connect(_on_apply_pressed)
	button_container.add_child(apply_button)

func setup_visualization_panel():
	var vbox = VBoxContainer.new()
	vbox.anchors_preset = Control.PRESET_FULL_RECT
	vbox.offset_left = 15
	vbox.offset_top = 15
	vbox.offset_right = -15
	vbox.offset_bottom = -15
	visualization_panel.add_child(vbox)
	
	# Title
	var title = Label.new()
	title.text = "Waveform Preview"
	title.add_theme_font_size_override("font_size", 18)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	# Add some spacing
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 15)
	vbox.add_child(spacer)
	
	# Waveform display area
	waveform_display = preload("res://scripts/tools/WaveformDisplay.gd").new()
	waveform_display.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(waveform_display)

func setup_sound_shaper():
	sound_shaper = preload("res://scripts/tools/SoundShaper.gd").new()
	add_child(sound_shaper)
	sound_shaper.parameter_changed.connect(_on_parameter_changed)

func setup_sound_type_list():
	for sound_type in sound_types:
		var data = sound_types[sound_type]
		sound_type_list.add_item(data.name)
		var index = sound_type_list.get_item_count() - 1
		sound_type_list.set_item_metadata(index, sound_type)
		
		# Set color for visual distinction
		sound_type_list.set_item_custom_bg_color(index, data.color * 0.3)
	
	# Select the first item
	if sound_type_list.get_item_count() > 0:
		sound_type_list.select(0)

func load_sound_type(sound_type: SoundType):
	current_sound_type = sound_type
	var data = sound_types[sound_type]
	
	# Update parameter panel title
	var title_label = parameter_panel.get_child(0).get_child(0) as Label
	if title_label:
		title_label.text = "Parameters - " + data.name
	
	# Clear existing parameters
	for child in parameter_container.get_children():
		child.queue_free()
	
	# Load parameters for this sound type
	sound_shaper.load_sound_parameters(sound_type)
	create_parameter_controls()
	
	# Update waveform display
	if waveform_display:
		waveform_display.set_sound_type(sound_type)
		waveform_display.set_sound_shaper(sound_shaper)
	
	print("[AudioStudio] Loaded sound type: ", data.name)

func create_parameter_controls():
	var parameters = sound_shaper.get_current_parameters()
	
	for param_name in parameters:
		var param_data = parameters[param_name]
		create_parameter_control(param_name, param_data)

func create_parameter_control(param_name: String, param_data: Dictionary):
	var control_container = VBoxContainer.new()
	control_container.add_theme_constant_override("separation", 5)
	parameter_container.add_child(control_container)
	
	# Parameter name label
	var name_label = Label.new()
	name_label.text = param_data.get("display_name", param_name.capitalize())
	name_label.add_theme_font_size_override("font_size", 14)
	control_container.add_child(name_label)
	
	# Value container (slider + value label)
	var value_container = HBoxContainer.new()
	value_container.add_theme_constant_override("separation", 10)
	control_container.add_child(value_container)
	
	# Slider
	var slider = HSlider.new()
	slider.min_value = param_data.get("min", 0.0)
	slider.max_value = param_data.get("max", 1.0)
	slider.step = param_data.get("step", 0.01)
	slider.value = param_data.get("value", 0.5)
	slider.custom_minimum_size = Vector2(280, 30)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.value_changed.connect(_on_parameter_slider_changed.bind(param_name))
	value_container.add_child(slider)
	
	# Value display
	var value_label = Label.new()
	value_label.custom_minimum_size = Vector2(60, 0)
	value_label.text = format_parameter_value(param_data.get("value", 0.5), param_data)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_container.add_child(value_label)
	
	# Description (if available)
	var description = param_data.get("description", "")
	if description != "":
		var desc_label = Label.new()
		desc_label.text = description
		desc_label.add_theme_font_size_override("font_size", 11)
		desc_label.modulate = Color(0.8, 0.8, 0.8)
		desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		control_container.add_child(desc_label)
	
	# Add spacing between parameters
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 10)
	control_container.add_child(spacer)

func format_parameter_value(value: float, param_data: Dictionary) -> String:
	var format_type = param_data.get("format", "float")
	match format_type:
		"int":
			return str(int(value))
		"frequency":
			return "%.0f Hz" % value
		"time":
			return "%.3f s" % value
		"percent":
			return "%.0f%%" % (value * 100)
		"db":
			return "%.1f dB" % value
		_:
			return "%.2f" % value

func _on_sound_type_selected(index: int):
	var sound_type = sound_type_list.get_item_metadata(index)
	if sound_type != null:
		load_sound_type(sound_type)

func _on_parameter_slider_changed(param_name: String, value: float):
	sound_shaper.set_parameter(param_name, value)
	
	# Update the value label
	update_parameter_value_display(param_name, value)
	
	# Update waveform in real-time
	if waveform_display:
		waveform_display.update_waveform()

func update_parameter_value_display(param_name: String, value: float):
	# Find the parameter control and update its value label
	var parameters = sound_shaper.get_current_parameters()
	var param_data = parameters.get(param_name, {})
	
	for control in parameter_container.get_children():
		if control is VBoxContainer:
			var name_label = control.get_child(0) as Label
			if name_label and name_label.text.begins_with(param_data.get("display_name", param_name.capitalize())):
				var value_container = control.get_child(1) as HBoxContainer
				if value_container:
					var value_label = value_container.get_child(1) as Label
					if value_label:
						value_label.text = format_parameter_value(value, param_data)
				break

func _on_parameter_changed(param_name: String, value: float):
	# This is called when parameters change from the sound shaper
	if waveform_display:
		waveform_display.update_waveform()

func _on_preview_pressed():
	# Play the current sound with current parameters
	sound_shaper.preview_sound()
	print("[AudioStudio] Previewing ", sound_types[current_sound_type].name)

func _on_apply_pressed():
	# Apply current parameters to the main game
	sound_shaper.apply_to_game()
	print("[AudioStudio] Applied ", sound_types[current_sound_type].name, " parameters to game")