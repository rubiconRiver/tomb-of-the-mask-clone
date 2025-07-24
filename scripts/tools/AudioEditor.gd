extends Control
class_name AudioEditor

# Pattern sequencer for level editor
# Creates 16-step patterns for 5 instrument tracks

signal closed
signal pattern_saved(pattern_data)

# Track types with colors for visual distinction
enum TrackType {
	KICK,
	SNARE, 
	HIHAT,
	PERCUSSION,
	MELODY
}

const TRACK_NAMES = {
	TrackType.KICK: "Kick",
	TrackType.SNARE: "Snare", 
	TrackType.HIHAT: "Hi-Hat",
	TrackType.PERCUSSION: "Percussion",
	TrackType.MELODY: "Melody"
}

const TRACK_COLORS = {
	TrackType.KICK: Color(0.8, 0.2, 0.2), # Red
	TrackType.SNARE: Color(0.2, 0.8, 0.2), # Green
	TrackType.HIHAT: Color(0.2, 0.2, 0.8), # Blue
	TrackType.PERCUSSION: Color(0.8, 0.8, 0.2), # Yellow
	TrackType.MELODY: Color(0.8, 0.2, 0.8) # Magenta
}

# Pattern data: [track_type][step] = bool
var patterns = {}

# Playback state
var is_playing = false
var current_step = 0
var bpm = 120
var step_timer = 0.0
var step_interval = 0.0 # Calculated from BPM

# UI references (will be created programmatically)
var close_button: Button
var theme_option: OptionButton
var preview_button: Button
var play_button: Button
var stop_button: Button
var clear_button: Button
var save_button: Button
var bpm_label: Label
var bpm_slider: HSlider
var tracks_container: VBoxContainer
var level_name_label: Label

# Track UI references
var track_widgets = {}

# Level information
var current_level_name = "Untitled Level"

func _ready():
	print("[AudioEditor] Initializing audio editor...")
	
	# Initialize patterns
	initialize_patterns()
	
	# Ensure audio system is initialized
	if not AudioManager:
		print("[AudioEditor] WARNING: AudioManager not found!")
	else:
		print("[AudioEditor] AudioManager found: ", AudioManager)
		if not AudioManager.drum_bank:
			print("[AudioEditor] WARNING: drum_bank not found!")
		if not AudioManager.sfx_bank:
			print("[AudioEditor] WARNING: sfx_bank not found!")
		if not AudioManager.mixer:
			print("[AudioEditor] WARNING: mixer not found!")
	
	# Create entire UI programmatically
	create_ui()
	
	# Setup UI connections
	setup_connections()
	
	# Create track widgets
	create_track_widgets()
	
	# Update BPM calculations
	update_bpm(bpm)
	
	# Ensure SoundBank is initialized for immediate audio playback
	if not SoundBank._initialized or SoundBank.cached_sounds.is_empty():
		print("[AudioEditor] Initializing SoundBank for immediate audio playback...")
		SoundBank.initialize()
		print("[AudioEditor] SoundBank initialized with ", SoundBank.cached_sounds.size(), " sounds")
	else:
		print("[AudioEditor] SoundBank already initialized with ", SoundBank.cached_sounds.size(), " sounds")
	
	print("[AudioEditor] Audio editor ready!")

func create_ui():
	print("[AudioEditor] Creating UI programmatically...")
	
	# Create background
	var background = ColorRect.new()
	background.anchors_preset = Control.PRESET_FULL_RECT
	background.color = Color(0, 0, 0, 0.7)
	add_child(background)
	
	# Create main panel with styling
	var main_panel = Panel.new()
	main_panel.anchors_preset = Control.PRESET_CENTER
	main_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	main_panel.size = Vector2(1200, 800)
	main_panel.position = Vector2(-600, -400)
	
	# Create panel style
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.15, 0.15, 0.2, 0.95)
	style_box.border_width_left = 2
	style_box.border_width_top = 2
	style_box.border_width_right = 2
	style_box.border_width_bottom = 2
	style_box.border_color = Color(0.4, 0.4, 0.5, 1)
	style_box.corner_radius_top_left = 8
	style_box.corner_radius_top_right = 8
	style_box.corner_radius_bottom_right = 8
	style_box.corner_radius_bottom_left = 8
	main_panel.add_theme_stylebox_override("panel", style_box)
	
	add_child(main_panel)
	
	# Create main container
	var main_container = VBoxContainer.new()
	main_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	main_container.offset_left = 20
	main_container.offset_top = 20
	main_container.offset_right = -20
	main_container.offset_bottom = -20
	main_panel.add_child(main_container)
	
	# Header section
	var header_section = HBoxContainer.new()
	main_container.add_child(header_section)
	
	var title_container = VBoxContainer.new()
	title_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_section.add_child(title_container)
	
	var title_label = Label.new()
	title_label.text = "Audio Editor - Pattern Sequencer"
	title_label.add_theme_font_size_override("font_size", 24)
	title_container.add_child(title_label)
	
	level_name_label = Label.new()
	level_name_label.text = "Editing: " + current_level_name
	level_name_label.add_theme_font_size_override("font_size", 16)
	level_name_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	title_container.add_child(level_name_label)
	
	close_button = Button.new()
	close_button.text = "✕ Close"
	close_button.custom_minimum_size = Vector2(100, 40)
	header_section.add_child(close_button)
	
	# Separator
	var separator1 = HSeparator.new()
	main_container.add_child(separator1)
	
	# Theme section
	var theme_section = VBoxContainer.new()
	main_container.add_child(theme_section)
	
	var theme_label = Label.new()
	theme_label.text = "Audio Theme:"
	theme_label.add_theme_font_size_override("font_size", 18)
	theme_section.add_child(theme_label)
	
	var theme_selector = HBoxContainer.new()
	theme_section.add_child(theme_selector)
	
	theme_option = OptionButton.new()
	theme_option.add_item("default")
	theme_option.add_item("test")
	theme_option.add_item("Kid")
	theme_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	theme_selector.add_child(theme_option)
	
	preview_button = Button.new()
	preview_button.text = "Preview Theme"
	preview_button.custom_minimum_size = Vector2(120, 40)
	theme_selector.add_child(preview_button)
	
	# Separator
	var separator2 = HSeparator.new()
	main_container.add_child(separator2)
	
	# Sequencer section
	var sequencer_section = VBoxContainer.new()
	sequencer_section.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_container.add_child(sequencer_section)
	
	var sequencer_label = Label.new()
	sequencer_label.text = "16-Step Pattern Sequencer:"
	sequencer_label.add_theme_font_size_override("font_size", 18)
	sequencer_section.add_child(sequencer_label)
	
	# PLAYBACK CONTROLS - This is the critical section!
	var playback_controls = HBoxContainer.new()
	playback_controls.custom_minimum_size = Vector2(0, 80)
	playback_controls.add_theme_constant_override("separation", 20)
	sequencer_section.add_child(playback_controls)
	
	# Play button - LARGE AND VISIBLE
	play_button = Button.new()
	play_button.text = "▶ PLAY"
	play_button.custom_minimum_size = Vector2(150, 70)
	play_button.add_theme_font_size_override("font_size", 20)
	play_button.add_theme_color_override("font_color", Color(0.2, 0.8, 0.2))
	playback_controls.add_child(play_button)
	
	# Stop button - LARGE AND VISIBLE
	stop_button = Button.new()
	stop_button.text = "⏹ STOP"
	stop_button.custom_minimum_size = Vector2(150, 70)
	stop_button.add_theme_font_size_override("font_size", 20)
	stop_button.add_theme_color_override("font_color", Color(0.8, 0.2, 0.2))
	playback_controls.add_child(stop_button)
	
	# Clear button - LARGE AND VISIBLE
	clear_button = Button.new()
	clear_button.text = "CLEAR ALL"
	clear_button.custom_minimum_size = Vector2(150, 70)
	clear_button.add_theme_font_size_override("font_size", 20)
	clear_button.add_theme_color_override("font_color", Color(0.8, 0.8, 0.2))
	playback_controls.add_child(clear_button)
	
	# Save button - LARGE AND VISIBLE
	save_button = Button.new()
	save_button.text = "💾 SAVE"
	save_button.custom_minimum_size = Vector2(150, 70)
	save_button.add_theme_font_size_override("font_size", 20)
	save_button.add_theme_color_override("font_color", Color(0.2, 0.8, 0.8))
	playback_controls.add_child(save_button)
	
	# Separator
	var vseparator = VSeparator.new()
	playback_controls.add_child(vseparator)
	
	# BPM Label
	bpm_label = Label.new()
	bpm_label.text = "BPM: 120"
	bpm_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	bpm_label.add_theme_font_size_override("font_size", 16)
	playback_controls.add_child(bpm_label)
	
	# BPM Slider
	bpm_slider = HSlider.new()
	bpm_slider.min_value = 60.0
	bpm_slider.max_value = 180.0
	bpm_slider.step = 5.0
	bpm_slider.value = 120.0
	bpm_slider.custom_minimum_size = Vector2(200, 70)
	bpm_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	playback_controls.add_child(bpm_slider)
	
	# Separator
	var separator3 = HSeparator.new()
	sequencer_section.add_child(separator3)
	
	# Scroll container for tracks
	var scroll_container = ScrollContainer.new()
	scroll_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sequencer_section.add_child(scroll_container)
	
	tracks_container = VBoxContainer.new()
	tracks_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_container.add_child(tracks_container)
	
	print("[AudioEditor] ✓ UI created programmatically!")
	print("  Play button size: ", play_button.custom_minimum_size)
	print("  Stop button size: ", stop_button.custom_minimum_size)
	print("  Clear button size: ", clear_button.custom_minimum_size)

func debug_ui_elements():
	print("[AudioEditor] Debugging UI elements...")
	print("  close_button: ", close_button)
	print("  theme_option: ", theme_option)
	print("  preview_button: ", preview_button)
	print("  play_button: ", play_button)
	print("  stop_button: ", stop_button)
	print("  clear_button: ", clear_button)
	print("  save_button: ", save_button)
	print("  bpm_label: ", bpm_label)
	print("  bpm_slider: ", bpm_slider)
	print("  tracks_container: ", tracks_container)

func initialize_patterns():
	# Initialize empty patterns for each track
	for track_type in TrackType.values():
		patterns[track_type] = []
		for step in range(16):
			patterns[track_type].append(false)

func setup_connections():
	print("[AudioEditor] Setting up connections...")
	
	if close_button:
		close_button.pressed.connect(_on_close_pressed)
		print("  ✓ Close button connected")
	else:
		print("  ✗ Close button is null!")
		
	if theme_option:
		theme_option.item_selected.connect(_on_theme_selected)
		print("  ✓ Theme option connected")
	else:
		print("  ✗ Theme option is null!")
		
	if preview_button:
		preview_button.pressed.connect(_on_preview_theme)
		print("  ✓ Preview button connected")
	else:
		print("  ✗ Preview button is null!")
		
	if play_button:
		play_button.pressed.connect(_on_play_pressed)
		print("  ✓ Play button connected")
	else:
		print("  ✗ Play button is null!")
		
	if stop_button:
		stop_button.pressed.connect(_on_stop_pressed)
		print("  ✓ Stop button connected")
	else:
		print("  ✗ Stop button is null!")
		
	if clear_button:
		clear_button.pressed.connect(_on_clear_pressed)
		print("  ✓ Clear button connected")
	else:
		print("  ✗ Clear button is null!")
		
	if save_button:
		save_button.pressed.connect(_on_save_pressed)
		print("  ✓ Save button connected")
	else:
		print("  ✗ Save button is null!")
		
	if bpm_slider:
		bpm_slider.value_changed.connect(_on_bpm_changed)
		print("  ✓ BPM slider connected")
	else:
		print("  ✗ BPM slider is null!")

func create_track_widgets():
	if not tracks_container:
		print("[AudioEditor] ERROR: tracks_container not found!")
		return
		
	print("[AudioEditor] Creating track widgets...")
	
	for track_type in TrackType.values():
		var track_widget = create_track_widget(track_type)
		tracks_container.add_child(track_widget)
		track_widgets[track_type] = track_widget
	
	print("[AudioEditor] Created ", track_widgets.size(), " track widgets")

func create_track_widget(track_type: TrackType) -> Control:
	var track_container = VBoxContainer.new()
	
	# Track header
	var header = HBoxContainer.new()
	track_container.add_child(header)
	
	# Track name label
	var name_label = Label.new()
	name_label.text = TRACK_NAMES[track_type]
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.add_theme_color_override("font_color", TRACK_COLORS[track_type])
	name_label.custom_minimum_size = Vector2(80, 0)
	header.add_child(name_label)
	
	# Mute button
	var mute_button = Button.new()
	mute_button.text = "M"
	mute_button.custom_minimum_size = Vector2(30, 30)
	mute_button.toggle_mode = true
	mute_button.pressed.connect(_on_track_muted.bind(track_type, mute_button))
	header.add_child(mute_button)
	
	# Solo button
	var solo_button = Button.new()
	solo_button.text = "S"
	solo_button.custom_minimum_size = Vector2(30, 30)
	solo_button.toggle_mode = true
	solo_button.pressed.connect(_on_track_soloed.bind(track_type, solo_button))
	header.add_child(solo_button)
	
	# Volume slider
	var volume_slider = HSlider.new()
	volume_slider.min_value = 0.0
	volume_slider.max_value = 1.0
	volume_slider.value = 0.7
	volume_slider.step = 0.1
	volume_slider.custom_minimum_size = Vector2(100, 30)
	volume_slider.value_changed.connect(_on_track_volume_changed.bind(track_type))
	header.add_child(volume_slider)
	
	# Step buttons container (BACK TO ORIGINAL WORKING VERSION)
	var steps_container = HBoxContainer.new()
	track_container.add_child(steps_container)
	
	# Create 16 step buttons with musical notation
	var step_buttons = []
	for step in range(16):
		var step_button = Button.new()
		step_button.custom_minimum_size = Vector2(40, 40)
		step_button.toggle_mode = true
		
		# Set text based on musical timing
		if step % 4 == 0:
			# Quarter notes: 1, 2, 3, 4 (steps 0,4,8,12 -> 1,2,3,4)
			step_button.text = str((step / 4) + 1)
			step_button.add_theme_color_override("font_color", Color.WHITE)
		elif step % 2 == 0:
			# 8th notes: + (steps 2,6,10,14)
			step_button.text = "+"
			step_button.add_theme_color_override("font_color", Color.GRAY)
		else:
			# 16th notes: • (steps 1,3,5,7,9,11,13,15)
			step_button.text = "•"
			step_button.add_theme_color_override("font_color", Color.GRAY)
		
		step_button.pressed.connect(_on_step_toggled.bind(track_type, step, step_button))
		steps_container.add_child(step_button)
		step_buttons.append(step_button)
	
	# Store references for later access
	track_container.set_meta("step_buttons", step_buttons)
	track_container.set_meta("mute_button", mute_button)
	track_container.set_meta("solo_button", solo_button)
	track_container.set_meta("volume_slider", volume_slider)
	
	return track_container

func _on_step_toggled(track_type: TrackType, step: int, button: Button):
	patterns[track_type][step] = button.button_pressed
	
	# Visual feedback (ORIGINAL WORKING VERSION)
	if button.button_pressed:
		button.add_theme_color_override("font_outline_color", TRACK_COLORS[track_type])
		button.add_theme_constant_override("outline_size", 3)
	else:
		button.remove_theme_color_override("font_outline_color")
		button.remove_theme_constant_override("outline_size")
	
	print("[AudioEditor] Track ", TRACK_NAMES[track_type], " step ", step + 1, ": ", button.button_pressed)

func _on_track_muted(track_type: TrackType, button: Button):
	print("[AudioEditor] Track ", TRACK_NAMES[track_type], " muted: ", button.button_pressed)

func _on_track_soloed(track_type: TrackType, button: Button):
	print("[AudioEditor] Track ", TRACK_NAMES[track_type], " soloed: ", button.button_pressed)

func _on_track_volume_changed(track_type: TrackType, value: float):
	print("[AudioEditor] Track ", TRACK_NAMES[track_type], " volume: ", value)

func _on_theme_selected(index: int):
	var theme_names = ["default", "test", "Kid"]
	var selected_theme = theme_names[index]
	print("[AudioEditor] Selected theme: ", selected_theme)
	
	# Change the SoundBank theme and reinitialize to load new files
	print("[AudioEditor] Switching SoundBank to theme: ", selected_theme)
	SoundBank.set_theme(selected_theme)
	print("[AudioEditor] Theme switched! New cached sounds: ", SoundBank.cached_sounds.size())
	print("[AudioEditor] Available sound keys: ", SoundBank.cached_sounds.keys())

func _on_preview_theme():
	print("[AudioEditor] Previewing current theme...")
	print("[AudioEditor] AudioManager: ", AudioManager)
	print("[AudioEditor] drum_bank: ", AudioManager.drum_bank if AudioManager else "N/A")
	print("[AudioEditor] sfx_bank: ", AudioManager.sfx_bank if AudioManager else "N/A")
	
	# Check SoundBank initialization
	print("[AudioEditor] SoundBank current theme: ", SoundBank.current_theme)
	print("[AudioEditor] SoundBank initialized: ", SoundBank._initialized)
	print("[AudioEditor] Cached sounds count: ", SoundBank.cached_sounds.size())
	print("[AudioEditor] Available sound keys: ", SoundBank.cached_sounds.keys())
	
	# Test SoundBank directly
	print("[AudioEditor] Testing SoundBank.get_kick(): ", SoundBank.get_kick())
	print("[AudioEditor] Testing SoundBank.get_snare(): ", SoundBank.get_snare())
	print("[AudioEditor] Testing SoundBank.get_hihat(): ", SoundBank.get_hihat())
	print("[AudioEditor] Testing SoundBank.get_coin_chime(): ", SoundBank.get_coin_chime())
	
	# Force reinitialize SoundBank if needed
	if not SoundBank._initialized or SoundBank.cached_sounds.is_empty():
		print("[AudioEditor] SoundBank not initialized, initializing now...")
		SoundBank.initialize()
		await get_tree().process_frame  # Give it time to load
	
	# Test basic audio with debug
	if AudioManager and AudioManager.drum_bank:
		print("[AudioEditor] Testing kick...")
		AudioManager.drum_bank.play_kick()
		await get_tree().create_timer(0.5).timeout
		print("[AudioEditor] Testing snare...")
		AudioManager.drum_bank.play_snare()
		await get_tree().create_timer(0.5).timeout
		print("[AudioEditor] Testing hihat...")
		AudioManager.drum_bank.play_hihat()
		await get_tree().create_timer(0.5).timeout
	else:
		print("[AudioEditor] Cannot test drums - AudioManager or drum_bank is null")
		
	if AudioManager and AudioManager.sfx_bank:
		print("[AudioEditor] Testing coin sound...")
		AudioManager.sfx_bank.play_coin_chime()
	else:
		print("[AudioEditor] Cannot test SFX - AudioManager or sfx_bank is null")

func _on_play_pressed():
	if is_playing:
		return
		
	print("[AudioEditor] Starting pattern playback at ", bpm, " BPM")
	is_playing = true
	current_step = 0
	step_timer = 0.0
	
	play_button.text = "⏸ Playing"
	play_button.disabled = true

func _on_stop_pressed():
	if not is_playing:
		return
		
	print("[AudioEditor] Stopping pattern playback")
	is_playing = false
	current_step = 0
	
	play_button.text = "▶ Play"
	play_button.disabled = false
	
	# Clear current step highlight
	clear_step_highlights()

func _on_clear_pressed():
	print("[AudioEditor] Clearing all patterns")
	
	# Stop playback if running
	if is_playing:
		_on_stop_pressed()
	
	# Clear all patterns
	initialize_patterns()
	
	# Update UI to reflect cleared patterns
	for track_type in TrackType.values():
		if track_type in track_widgets:
			var track_widget = track_widgets[track_type]
			var step_buttons = track_widget.get_meta("step_buttons", [])
			for i in range(step_buttons.size()):
				var button = step_buttons[i]
				button.button_pressed = false
				button.remove_theme_color_override("font_outline_color")
				button.remove_theme_constant_override("outline_size")

func _on_save_pressed():
	print("[AudioEditor] Saving pattern for level: ", current_level_name)
	
	# Create audio pattern data structure
	var audio_pattern = {
		"bpm": bpm,
		"theme": SoundBank.current_theme,
		"level_name": current_level_name,
		"patterns": {}
	}
	
	# Convert patterns to saveable format (track name -> step array)
	for track_type in TrackType.values():
		var track_name = TRACK_NAMES[track_type].to_lower()
		audio_pattern.patterns[track_name] = patterns[track_type].duplicate()
	
	print("[AudioEditor] Audio pattern created: ", audio_pattern)
	
	# Store pattern data globally so LevelEditor can access it
	set_meta("saved_audio_pattern", audio_pattern)
	
	# Also send signal to parent (LevelEditor) that pattern was saved
	print("[AudioEditor] Emitting pattern_saved signal with data:")
	print("  BPM: ", audio_pattern.bpm)
	print("  Theme: ", audio_pattern.theme)
	print("  Patterns: ", audio_pattern.patterns.keys())
	emit_signal("pattern_saved", audio_pattern)
	
	print("[AudioEditor] ✓ Pattern saved! The level editor can now include this audio pattern when saving.")

func _on_bpm_changed(value: float):
	update_bpm(int(value))

func update_bpm(new_bpm: int):
	bpm = new_bpm
	# 16th notes at given BPM: 60 / BPM / 4 seconds per 16th note
	step_interval = 60.0 / float(bpm) / 4.0
	
	if bpm_label:
		bpm_label.text = "BPM: " + str(bpm)
	
	print("[AudioEditor] BPM set to ", bpm, " (step interval: ", step_interval, "s)")

func _process(delta):
	if not is_playing:
		return
		
	step_timer += delta
	
	if step_timer >= step_interval:
		step_timer = 0.0
		play_current_step()
		advance_step()

func play_current_step():
	# Highlight current step
	highlight_current_step()
	
	print("[AudioEditor] Playing step ", current_step + 1)
	
	# Play sounds for active steps
	for track_type in TrackType.values():
		if patterns[track_type][current_step]:
			print("[AudioEditor] Playing ", TRACK_NAMES[track_type], " on step ", current_step + 1)
			play_track_sound(track_type)
		else:
			print("[AudioEditor] Step ", current_step + 1, " - ", TRACK_NAMES[track_type], " is OFF")

func play_track_sound(track_type: TrackType):
	print("[AudioEditor] play_track_sound called for ", TRACK_NAMES[track_type])
	
	if not AudioManager:
		print("[AudioEditor] ERROR: AudioManager is null!")
		return
	
	print("[AudioEditor] AudioManager found: ", AudioManager)
	print("[AudioEditor] drum_bank: ", AudioManager.drum_bank)
	print("[AudioEditor] sfx_bank: ", AudioManager.sfx_bank)
	print("[AudioEditor] mixer: ", AudioManager.mixer)
		
	match track_type:
		TrackType.KICK:
			print("[AudioEditor] Playing kick...")
			if AudioManager.drum_bank:
				print("[AudioEditor] Calling drum_bank.play_kick()")
				AudioManager.drum_bank.play_kick()
				print("[AudioEditor] ✓ Kick called")
			else:
				print("[AudioEditor] ERROR: drum_bank is null!")
		TrackType.SNARE:
			print("[AudioEditor] Playing snare...")
			if AudioManager.drum_bank:
				print("[AudioEditor] Calling drum_bank.play_snare()")
				AudioManager.drum_bank.play_snare()
				print("[AudioEditor] ✓ Snare called")
			else:
				print("[AudioEditor] ERROR: drum_bank is null!")
		TrackType.HIHAT:
			print("[AudioEditor] Playing hihat...")
			if AudioManager.drum_bank:
				print("[AudioEditor] Calling drum_bank.play_hihat()")
				AudioManager.drum_bank.play_hihat()
				print("[AudioEditor] ✓ Hihat called")
			else:
				print("[AudioEditor] ERROR: drum_bank is null!")
		TrackType.PERCUSSION:
			print("[AudioEditor] Playing percussion...")
			# Use SFX sounds directly instead of generating toms
			if AudioManager.sfx_bank:
				print("[AudioEditor] Calling sfx_bank.play_wall_hit()")
				AudioManager.sfx_bank.play_wall_hit()
				print("[AudioEditor] ✓ Percussion played via wall_hit")
			else:
				print("[AudioEditor] ERROR: sfx_bank is null!")
		TrackType.MELODY:
			print("[AudioEditor] Playing melody...")
			# Use SFX sounds for melody too
			if AudioManager.sfx_bank:
				print("[AudioEditor] Calling sfx_bank.play_coin_chime()")
				AudioManager.sfx_bank.play_coin_chime()
				print("[AudioEditor] ✓ Melody played via coin sound")
			else:
				print("[AudioEditor] ERROR: sfx_bank is null for melody!")

func highlight_current_step():
	# Clear previous highlights
	clear_step_highlights()
	
	# Create subtle playback position indicator for all tracks
	for track_type in TrackType.values():
		if track_type in track_widgets:
			var track_widget = track_widgets[track_type]
			var step_buttons = track_widget.get_meta("step_buttons", [])
			if current_step < step_buttons.size():
				var button = step_buttons[current_step]
				
				# Create a subtle border-only playback indicator
				var playback_style = StyleBoxFlat.new()
				# Keep the original background transparent/default
				playback_style.bg_color = Color.TRANSPARENT
				# Add a subtle colored border
				playback_style.border_width_left = 2
				playback_style.border_width_top = 2
				playback_style.border_width_right = 2
				playback_style.border_width_bottom = 2
				playback_style.border_color = Color(0.8, 0.8, 0.8, 0.9)  # Subtle light gray
				playback_style.corner_radius_top_left = 4
				playback_style.corner_radius_top_right = 4
				playback_style.corner_radius_bottom_left = 4
				playback_style.corner_radius_bottom_right = 4
				
				button.add_theme_stylebox_override("normal", playback_style)
				button.add_theme_stylebox_override("pressed", playback_style)

func clear_step_highlights():
	# Simply remove playback position styling, keeping toggle feedback intact
	for track_type in TrackType.values():
		if track_type in track_widgets:
			var track_widget = track_widgets[track_type]
			var step_buttons = track_widget.get_meta("step_buttons", [])
			for i in range(step_buttons.size()):
				var button = step_buttons[i]
				# Remove playback position styling only
				button.remove_theme_stylebox_override("normal")
				button.remove_theme_stylebox_override("pressed")
				# Keep the outline-based toggle feedback untouched!

func advance_step():
	current_step = (current_step + 1) % 16
	
	# If we completed a full loop, we could add loop controls here
	if current_step == 0:
		print("[AudioEditor] Pattern loop completed")

func load_pattern_data(pattern_data):
	print("[AudioEditor] ===== LOADING PATTERN DATA =====")
	print("  BPM: ", pattern_data.bpm)
	print("  Theme: ", pattern_data.theme)
	print("  Level: ", pattern_data.get("level_name", "Unknown"))
	print("  Pattern tracks: ", pattern_data.patterns.keys())
	print("  UI ready check - bpm_slider: ", bpm_slider != null)
	print("  UI ready check - theme_option: ", theme_option != null)
	print("  UI ready check - track_widgets: ", track_widgets.size())
	
	# Set BPM
	update_bpm(pattern_data.bpm)
	if bpm_slider:
		bpm_slider.value = pattern_data.bpm
		print("[AudioEditor] BPM slider updated to: ", pattern_data.bpm)
	
	# Set theme
	if pattern_data.has("theme") and theme_option:
		var theme_names = ["default", "test", "Kid"]
		var theme_index = theme_names.find(pattern_data.theme)
		if theme_index >= 0:
			theme_option.selected = theme_index
			SoundBank.set_theme(pattern_data.theme)
			print("[AudioEditor] Theme set to: ", pattern_data.theme)
		else:
			print("[AudioEditor] Warning: Unknown theme '", pattern_data.theme, "'")
	
	# Load patterns
	if pattern_data.has("patterns"):
		print("[AudioEditor] Loading patterns for tracks:")
		for track_type in TrackType.values():
			var track_name = TRACK_NAMES[track_type].to_lower()
			if track_name in pattern_data.patterns:
				var pattern_array = pattern_data.patterns[track_name]
				patterns[track_type] = pattern_array.duplicate()
				print("  ", track_name, ": ", pattern_array.count(true), " active steps")
			else:
				print("  ", track_name, ": no pattern data found")
		
		# Update UI to reflect loaded patterns
		print("[AudioEditor] Updating UI with loaded patterns...")
		update_ui_from_patterns()
	else:
		print("[AudioEditor] No pattern data found in pattern_data")
	
	print("[AudioEditor] ✓ Pattern data loaded successfully")

func set_level_info(level_name: String):
	current_level_name = level_name
	# Update the display label if it exists
	if level_name_label:
		level_name_label.text = "Editing: " + current_level_name
	print("[AudioEditor] Level set to: ", current_level_name)

func _on_close_pressed():
	print("[AudioEditor] Closing audio editor")
	
	# Stop playback if running
	if is_playing:
		_on_stop_pressed()
	
	# Emit signal and remove self
	emit_signal("closed")
	queue_free()

# Save/Load pattern functions (for future expansion)
func save_pattern_to_file(filename: String):
	var data = {
		"bpm": bpm,
		"patterns": patterns
	}
	
	var file = FileAccess.open("res://audio_patterns/" + filename + ".json", FileAccess.WRITE)
	if file:
		var json = JSON.new()
		file.store_string(json.stringify(data, "\t"))
		file.close()
		print("[AudioEditor] Pattern saved to: ", filename)

func load_pattern_from_file(filename: String):
	var file = FileAccess.open("res://audio_patterns/" + filename + ".json", FileAccess.READ)
	if not file:
		print("[AudioEditor] Could not load pattern: ", filename)
		return
		
	var json = JSON.new()
	var parse_result = json.parse(file.get_as_text())
	file.close()
	
	if parse_result != OK:
		print("[AudioEditor] Failed to parse pattern file: ", filename)
		return
		
	var data = json.data
	if data.has("bpm"):
		update_bpm(data.bpm)
		bpm_slider.value = data.bpm
		
	if data.has("patterns"):
		patterns = data.patterns
		update_ui_from_patterns()
		
	print("[AudioEditor] Pattern loaded from: ", filename)

func update_ui_from_patterns():
	print("[AudioEditor] ===== UPDATING UI FROM PATTERNS =====")
	# Update step buttons to reflect loaded patterns
	for track_type in TrackType.values():
		var track_name = TRACK_NAMES[track_type]
		print("  Updating track: ", track_name)
		print("    track_type in track_widgets: ", track_type in track_widgets)
		print("    track_type in patterns: ", track_type in patterns)
		
		if track_type in track_widgets and track_type in patterns:
			var track_widget = track_widgets[track_type]
			var step_buttons = track_widget.get_meta("step_buttons", [])
			print("    Found ", step_buttons.size(), " step buttons")
			print("    Pattern data: ", patterns[track_type])
			
			var buttons_updated = 0
			for i in range(min(step_buttons.size(), patterns[track_type].size())):
				var button = step_buttons[i]
				var is_active = patterns[track_type][i]
				button.button_pressed = is_active
				
				if is_active:
					button.add_theme_color_override("font_outline_color", TRACK_COLORS[track_type])
					button.add_theme_constant_override("outline_size", 3)
					buttons_updated += 1
				else:
					button.remove_theme_color_override("font_outline_color")
					button.remove_theme_constant_override("outline_size")
			
			print("    ✓ Updated ", buttons_updated, " active buttons for ", track_name)
		else:
			print("    ✗ Skipped ", track_name, " - not ready")
	
	print("[AudioEditor] ===== UI UPDATE COMPLETE =====")
