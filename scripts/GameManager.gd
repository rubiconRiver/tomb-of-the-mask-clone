extends Node
class_name GameManager

var player_scene = preload("res://scenes/player/Player.tscn")
var level_generator_scene = preload("res://scenes/levels/LevelGenerator.tscn")
# var beat_indicator_script = preload("res://scripts/ui/BeatIndicator.gd")  # REMOVED: Beat counter UI
var style_score_manager_script = preload("res://scripts/ui/StyleScoreManager.gd")
var timing_feedback_script = preload("res://scripts/ui/TimingFeedback.gd")
var beat_timeline_script = preload("res://scripts/ui/BeatTimeline.gd")
var beat_visualizer_script = preload("res://scripts/visual/BeatVisualizer.gd")
var timing_monitor_script = preload("res://scripts/ui/TimingMonitor.gd")
# Combo music now handled by AudioManager

var player: Player
var level_generator: LevelGenerator
var swipe_detector: SwipeDetector
var camera: Camera2D
# var beat_indicator: Control  # REMOVED: Beat counter UI
var beat_timeline: BeatTimeline
var style_score_manager: StyleScoreManager
var beat_visualizer: BeatVisualizer
# Audio now handled by AudioManager singleton

# New effect systems
var screen_shake: ScreenShake
var particle_manager: ParticleManager
var latency_compensator: LatencyCompensator
var audio_analyzer: AudioAnalyzer
# var beat_indicator_ui: BeatIndicatorUI  # REMOVED: Beat counter UI
var grid_star_effect: GridStarEffect
var mobile_controls: MobileControls

var score = 0  # Session points (coins × multiplier)
var coins = 0  # Session coins collected
var current_level = 1  # Gets set by GameData
var is_game_over = false
var game_started = false
var beat_tracking_started = false
var level_start_time = 0.0
var level_complete_time = 0.0
var is_level_complete = false
var total_coins_in_level = 0
var perfect_score = 0  # Perfect score for current level

var audio_latency_offset = 0.0  # Default to 0 as requested

# 4th beat mandatory move tracking
var last_4th_beat_move = -1  # Last beat where we successfully moved
var last_move_quality = StyleScoreManager.TimingQuality.OFF_BEAT

# Beat-synchronized audio queue
var pending_coin_chimes = 0
var pending_wall_hits = 0
var pending_coin_chimes_8th = 0  # For 8th note coin timing
var pending_wall_hits_8th = 0    # For 8th note wall hit timing

# 8th note tracking (0-7, resets every 2 beats)
var eighth_note_count = 0

# Bar tracking for double snare pattern (0-15, resets every 4 bars)
var bar_eighth_count = 0

# Current move timing quality (for wall hit tom fills)
var current_move_quality = StyleScoreManager.TimingQuality.OFF_BEAT

@onready var ui_layer = $UILayer
@onready var score_label = $UILayer/ScoreLabel
@onready var coins_label = $UILayer/CoinsLabel
@onready var combo_label = $UILayer/ComboLabel
@onready var latency_label = $UILayer/LatencyLabel
@onready var game_over_panel = $UILayer/GameOverPanel

func _ready():
	# Initialize sound bank
	SoundBank.initialize()
	
	# Initialize new effect systems
	initialize_effect_systems()
	
	swipe_detector = SwipeDetector.new()
	add_child(swipe_detector)
	swipe_detector.swiped.connect(_on_swipe_detected)
	
	style_score_manager = style_score_manager_script.new()
	add_child(style_score_manager)
	style_score_manager.timing_calculated.connect(_on_timing_calculated)
	style_score_manager.combo_changed.connect(_on_combo_changed)
	style_score_manager.multiplier_changed.connect(_on_multiplier_changed)
	
	setup_camera()
	# setup_beat_indicator()  # REMOVED: Beat counter UI
	setup_beat_timeline()
	setup_beat_visualizer()
	setup_multiplier_indicator()
	setup_timing_monitor()
	
	# Connect to AudioManager signals
	AudioManager.beat_occurred.connect(_on_beat)
	AudioManager.eighth_note_occurred.connect(_on_eighth_note)
	
	# Auto-start game only if not launched from editor
	if not LevelEditorData.is_launched_from_editor():
		start_game()
	else:
		print("[GameManager] Launched from editor - setting up level without auto-starting game")
		# Set up the level but don't start the game
		setup_level()
		spawn_player()
		update_ui()
		
		# Enable input handling for editor mode (but don't start beat tracking)
		game_started = true
		print("[GameManager] Input enabled for level editor testing")

func _exit_tree():
	# Stop audio when exiting the scene
	if AudioManager:
		AudioManager.reset()
		print("[GameManager] Audio stopped when exiting game scene")

func setup_camera():
	camera = Camera2D.new()
	camera.enabled = true
	add_child(camera)
	
	# Position camera to show entire level
	position_camera_for_full_level()
	
	# Setup themed background
	setup_themed_background()

func setup_themed_background():
	var background = get_node_or_null("Background")
	if not background:
		return
	
	# Try to get themed background texture
	var themed_texture = VisualThemeManager.get_background_texture()
	
	if themed_texture and background is ColorRect:
		# Convert ColorRect to TextureRect for themed texture
		var texture_rect = TextureRect.new()
		texture_rect.name = "Background"
		texture_rect.z_index = background.z_index
		texture_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		texture_rect.texture = themed_texture
		texture_rect.stretch_mode = TextureRect.STRETCH_TILE
		
		# Replace the ColorRect
		var parent = background.get_parent()
		parent.remove_child(background)
		parent.add_child(texture_rect)
		background.queue_free()
		
		print("[GameManager] Applied themed background texture")
	elif background is ColorRect:
		# Keep ColorRect with default color
		print("[GameManager] Using default ColorRect background")

func position_camera_for_full_level():
	if not camera or not level_generator:
		return
		
	# Get viewport size
	var viewport_size = get_viewport().get_visible_rect().size
	
	# Get level dimensions
	var level_data = level_generator.get_level_data()
	if level_data.is_empty():
		return
		
	var level_height = level_data.size()
	var level_width = level_data[0].size() if level_height > 0 else 16
	
	# Calculate level size in pixels
	var level_pixel_width = level_width * 64  # GRID_SIZE
	var level_pixel_height = level_height * 64
	
	# Debug output
	print("[GameManager] Level dimensions: ", level_width, "x", level_height, " blocks")
	print("[GameManager] Level pixel size: ", level_pixel_width, "x", level_pixel_height)
	print("[GameManager] Viewport size: ", viewport_size)
	
	# Center camera on level (simple calculation)
	# Since level is built from (0,0), center is at half the pixel dimensions
	camera.position = Vector2(level_pixel_width / 2, level_pixel_height / 2)
	print("[GameManager] Camera positioned at: ", camera.position)
	
	# Calculate zoom to fit entire level perfectly in frame
	var zoom_x = viewport_size.x / level_pixel_width
	var zoom_y = viewport_size.y / level_pixel_height
	
	# Use the smaller zoom to ensure entire level fits
	# For 16:32 ratio, this should fit perfectly in most mobile screens
	var zoom_level = min(zoom_x, zoom_y)
	
	# Apply slight margin only if needed for UI
	zoom_level = zoom_level * 0.95  # Just 5% margin for UI elements
	
	# Ensure minimum zoom for visibility
	zoom_level = max(zoom_level, 0.3)
	
	camera.zoom = Vector2(zoom_level, zoom_level)
	
	print("[GameManager] Static camera positioned - Level: ", level_width, "x", level_height, " Zoom: ", zoom_level)

# REMOVED: Beat counter UI function
# func setup_beat_indicator():
#	beat_indicator = beat_indicator_script.new()
#	beat_indicator.position = Vector2(20, 20)
#	
#	if ui_layer:
#		ui_layer.add_child(beat_indicator)
		
	# Don't auto-connect, we'll call manually based on beat type

func setup_beat_timeline():
	beat_timeline = beat_timeline_script.new()
	
	if ui_layer:
		ui_layer.add_child(beat_timeline)

# Audio setup functions removed - now handled by AudioManager

func setup_beat_visualizer():
	beat_visualizer = beat_visualizer_script.new()
	add_child(beat_visualizer)
	AudioManager.beat_occurred.connect(beat_visualizer.trigger_beat)

func setup_multiplier_indicator():
	var multiplier_indicator_scene = preload("res://scenes/ui/MultiplierIndicator.tscn")
	var multiplier_indicator = multiplier_indicator_scene.instantiate()
	
	# It's already positioned in the scene file
	if ui_layer:
		ui_layer.add_child(multiplier_indicator)
		
	# Store reference for updates
	set_meta("multiplier_indicator", multiplier_indicator)

func setup_timing_monitor():
	var timing_monitor = timing_monitor_script.new()
	timing_monitor.position = Vector2(20, 200)  # Below beat indicator
	
	if ui_layer:
		ui_layer.add_child(timing_monitor)

func _process(delta):
	# Mobile controls now handled by MobileControls UI component
		
	
	# Return to level editor with M key when launched from editor
	if Input.is_key_pressed(KEY_M) and LevelEditorData.is_launched_from_editor():
		print("M key pressed - checking if we should return to editor")
		print("Is launched from editor: ", LevelEditorData.is_launched_from_editor())
		return_to_level_editor()
		return  # Prevent further processing this frame
	
	# Return to main menu with ESC key (if not from editor)
	if Input.is_action_just_pressed("ui_cancel") and not LevelEditorData.is_launched_from_editor():
		print("ESC pressed - returning to main menu")
		return_to_menu()
		return
		
	# Update beat timeline
	if beat_timeline:
		beat_timeline.update_beat(AudioManager.get_beat_progress(), AudioManager.beat_interval)

func start_game():
	score = 0
	coins = 0
	current_level = GameData.current_level  # Get from GameData
	is_game_over = false
	game_started = false  # Will be set to true after GO message
	beat_tracking_started = false  # Will be set to true when beat tracking starts
	is_level_complete = false
	level_start_time = 0.0  # Will be set when game actually starts
	pending_coin_chimes = 0
	pending_wall_hits = 0
	pending_coin_chimes_8th = 0
	pending_wall_hits_8th = 0
	eighth_note_count = 0
	bar_eighth_count = 0
	current_move_quality = StyleScoreManager.TimingQuality.OFF_BEAT
	last_4th_beat_move = -1
	last_move_quality = StyleScoreManager.TimingQuality.OFF_BEAT
	
	# Reset audio
	AudioManager.reset()
	
	if game_over_panel:
		game_over_panel.visible = false
	
	setup_level()
	spawn_player()
	update_ui()
	update_latency_display()
	
	print("[GameManager] Starting level ", current_level)
	
	# Only show GO message and auto-start if not launched from editor
	if not LevelEditorData.is_launched_from_editor():
		# Show GO message and start game after delay
		show_go_message()
	else:
		print("[GameManager] Level editor test mode - waiting for manual start")

func setup_level():
	if level_generator:
		level_generator.queue_free()
		
	level_generator = level_generator_scene.instantiate()
	add_child(level_generator)
	
	# Pass the current level to the generator
	print("[GameManager] Setting level_generator.current_level = ", current_level)
	level_generator.current_level = current_level
	
	# Now generate the level with the correct level number
	level_generator.generate_level()
	
	# Reposition camera for the new level (with a small delay)
	if camera:
		await get_tree().process_frame
		position_camera_for_full_level()
	
	# Count total coins in the level
	total_coins_in_level = 0
	var level_data = level_generator.get_level_data()
	if level_data:
		for row in level_data:
			for cell in row:
				if cell == LevelGenerator.CellType.COIN:
					total_coins_in_level += 1

func spawn_player():
	if player:
		player.queue_free()
		
	player = player_scene.instantiate()
	add_child(player)
	
	player.position = level_generator.get_player_spawn_position()
	player.died.connect(_on_player_died)
	player.collected_coin.connect(_on_coin_collected)
	
	# Connect BPM changes to player speed updates
	if AudioManager:
		AudioManager.bpm_changed.connect(player.update_speed_from_bpm)
		print("[GameManager] Connected BPM changes to player speed updates")
	player.moved.connect(_on_player_moved)
	player.hit_wall.connect(_on_player_hit_wall)
	
	# Remove the old techno shader application since player now has its own visual system
	# The player handles its own visuals through PlayerVisual.gd
	
	if camera:
		camera.position = player.position

func _on_beat(beat_count_param: int):
	# Update beat indicator with appropriate pulse strength
	# REMOVED: Beat counter UI
	# if beat_indicator:
	#	if beat_count_param % 4 == 0:
	#		beat_indicator.pulse_strong()
	#	else:
	#		beat_indicator.pulse()
	
	# Check if this is a 4th beat and we haven't moved
	if beat_count_param % 4 == 0 and beat_count_param > 0:
		# Check if we've made a successful move since the last 4th beat
		var beats_since_move = beat_count_param - last_4th_beat_move
		if beats_since_move >= 4:
			# No successful move in 4 beats - decrease multiplier
			print("Missed 4th beat requirement! Last move was ", beats_since_move, " beats ago")
			if style_score_manager and style_score_manager.current_multiplier > style_score_manager.MIN_MULTIPLIER:
				style_score_manager.current_multiplier -= 1
				style_score_manager.emit_signal("multiplier_changed", style_score_manager.current_multiplier)
				style_score_manager.combo_count = 0
				style_score_manager.emit_signal("combo_changed", 0, false)
	
	# Play beat sound
	AudioManager.play_beat_sound(beat_count_param)
	
	# Play any pending beat-synchronized audio effects
	if pending_coin_chimes > 0:
		AudioManager.play_coin_collected()
		pending_coin_chimes -= 1
	
	if pending_wall_hits > 0:
		AudioManager.play_wall_hit()
		pending_wall_hits -= 1
	
	# Pulse the background - stronger pulse on 4th beat (whole note)
	var background = get_node_or_null("Background")
	if background and background.material:
		var tween = get_tree().create_tween()
		
		if beat_count_param % 4 == 0:
			# Whole note - much stronger pulse
			tween.tween_property(background.material, "shader_parameter/pulse_strength", 1.0, 0.1)
			tween.tween_property(background.material, "shader_parameter/pulse_strength", 0.3, 0.4)
		else:
			# Regular beats - normal pulse
			tween.tween_property(background.material, "shader_parameter/pulse_strength", 0.6, 0.1)
			tween.tween_property(background.material, "shader_parameter/pulse_strength", 0.3, 0.3)

func _on_eighth_note():
	# Track which 8th note we're on (0-7, resets every 4 quarter notes)
	eighth_note_count = (eighth_note_count + 1) % 8
	
	# Track which 8th note we're on across 4 bars (0-31, resets every 4 bars)
	bar_eighth_count = (bar_eighth_count + 1) % 32
	
	# Only play default patterns if NO custom pattern is active
	if not AudioManager.custom_pattern_data:
		# Play hi-hat (default pattern only)
		AudioManager.play_hihat()
		
		# Add kick on half note after beat 1 (8th note position 1, which is between beats 1 and 2)
		if eighth_note_count == 1:  # Half note after beat 1
			AudioManager.drum_bank.play_kick()
			print("[GameManager] Playing extra kick on half note after beat 1 (default)")
		
		# Add double snare on 3.5 beat of every 4th bar
		# Position 7 within each bar = 3.5 beat
		# 4th bar occurs at positions 24-31 in the 32-eighth-note cycle (bars 1-4 = 0-7, 8-15, 16-23, 24-31)
		if eighth_note_count == 7 and bar_eighth_count >= 24:  # 3.5 beat of 4th bar
			AudioManager.drum_bank.play_snare()
			print("[GameManager] Playing double snare on 3.5 beat of 4th bar (default)")
	
	# Play pending 8th note sounds
	if pending_coin_chimes_8th > 0:
		AudioManager.play_coin_collected()
		pending_coin_chimes_8th -= 1
	
	# Handle timing-based tom fills
	if pending_wall_hits_8th > 0:
		if pending_wall_hits_8th == 1:
			# Perfect timing - full randomized tom fill
			AudioManager.play_perfect_tom_fill()
		elif pending_wall_hits_8th == 2:
			# Great timing - 2-hit tom fill at half volume  
			AudioManager.play_great_tom_fill()
		pending_wall_hits_8th = 0  # Reset after playing

# Old audio functions removed - now handled by AudioManager
func _on_swipe_detected(direction: Vector2):
	if not game_started or is_game_over or not player:
		return
	
	# Start beat tracking on first movement if launched from editor
	if LevelEditorData.is_launched_from_editor() and not beat_tracking_started:
		print("[GameManager] Starting beat tracking on first movement (editor mode)")
		AudioManager.start_beat_tracking()
		beat_tracking_started = true
	
	# If player is already moving, buffer the input
	if player.is_moving:
		player.buffered_direction = direction
		print("Buffered swipe: ", direction)
		return
	
	# Mobile haptic feedback for swipe
	HapticFeedback.on_swipe()
	
	# Start the guitar chord when movement begins
	AudioManager.start_ambient_guitar()
	
	# Calculate timing and score
	var timing_result = style_score_manager.register_move(AudioManager.get_beat_progress(), AudioManager.beat_interval)
	
	# Store timing quality for tom fill rewards
	current_move_quality = timing_result.timing
	
	# Haptic feedback based on timing quality
	match timing_result.timing:
		StyleScoreManager.TimingQuality.PERFECT:
			HapticFeedback.trigger_haptic(HapticFeedback.HapticType.SUCCESS)
		StyleScoreManager.TimingQuality.GREAT:
			HapticFeedback.trigger_haptic(HapticFeedback.HapticType.MEDIUM)
		StyleScoreManager.TimingQuality.GOOD:
			HapticFeedback.trigger_haptic(HapticFeedback.HapticType.LIGHT)
	
	# Track successful moves for 4th beat requirement
	if timing_result.timing == StyleScoreManager.TimingQuality.PERFECT or timing_result.timing == StyleScoreManager.TimingQuality.GREAT:
		last_4th_beat_move = AudioManager.get_current_beat()
		last_move_quality = timing_result.timing
	
	# Debug info
	var timing_text = timing_result.name
	if timing_result.timing == StyleScoreManager.TimingQuality.OFF_BEAT and timing_result.distance < 0.5:
		timing_text = "too early" if timing_result.is_early else "too late"
	
	print("Move timing: ", timing_result.name, " Combo: ", timing_result.combo, 
		  " Distance: ", int(timing_result.distance * 1000), "ms",
		  " (", timing_text, ")")
	
	# Apply score multiplier
	var base_score = 1
	score += int(base_score * timing_result.multiplier)
	update_ui()
	
	# Store timing info for visual feedback
	set_meta("last_timing", timing_result)
	
	player.move(direction)

func _on_player_died():
	# Stop the guitar chord when player dies
	AudioManager.stop_ambient_guitar()
	# Game over haptic feedback
	HapticFeedback.on_game_over()
	is_game_over = true
	if game_over_panel:
		game_over_panel.visible = true

func _on_coin_collected():
	# Increment coin count
	coins += 1
	
	# Haptic feedback for coin collection
	HapticFeedback.on_coin_collect()
	
	# Add to score based on current multiplier
	var multiplier = style_score_manager.get_current_multiplier()
	score += 10 * multiplier  # Base value 10 × multiplier
	
	update_ui()
	
	# Queue coin chime to play on next 8th note (much more responsive!)
	pending_coin_chimes_8th += 1
	print("Coin collected (", multiplier, "x) - Score: ", score)

func _on_player_moved():
	# Stop the guitar chord when movement ends
	AudioManager.stop_ambient_guitar()
	# Score is now handled by timing system in _on_swipe_detected
	pass

func _on_player_hit_wall():
	# Haptic feedback for wall collision
	HapticFeedback.on_wall_hit()
	
	# Queue tom fill based on timing quality to play on next 8th note (beat-synchronized)
	match current_move_quality:
		StyleScoreManager.TimingQuality.PERFECT:
			# Queue full randomized tom fill
			pending_wall_hits_8th += 1
			print("Perfect timing - full tom fill queued for next 8th note")
		StyleScoreManager.TimingQuality.GREAT:
			# Queue 2-hit tom fill at half volume  
			pending_wall_hits_8th += 2  # Use different value to distinguish type
			print("Great timing - 2-hit tom fill queued for next 8th note")
		StyleScoreManager.TimingQuality.GOOD:
			# No tom fill
			print("Good timing - no tom fill")
		_:
			# Off-beat or other - no tom fill
			print("Off-beat timing - no tom fill")
	
	# Reset timing quality for next move
	current_move_quality = StyleScoreManager.TimingQuality.OFF_BEAT

func update_ui():
	if score_label:
		score_label.text = "Score: " + str(score)
	if coins_label:
		coins_label.text = "Coins: " + str(coins)
	if combo_label and style_score_manager:
		if style_score_manager.combo_count > 0:
			combo_label.text = "Combo: x" + str(style_score_manager.combo_count)
			combo_label.visible = true
		else:
			combo_label.visible = false

func restart_game():
	start_game()

func _on_timing_calculated(quality: int, multiplier: float):
	# Update player visual based on timing quality
	if player and player.has_method("set_timing_quality"):
		player.set_timing_quality(quality)
	
	# Create visual feedback
	if player and ui_layer:
		# Since we're using a CanvasLayer for UI, we need to position relative to game viewport
		# The game is designed for 720x1280, and player should be centered
		var screen_pos = Vector2(360, 640)  # Center of design resolution
		
		# Setup feedback based on quality
		var colors = {
			StyleScoreManager.TimingQuality.PERFECT: Color(1.0, 0.0, 1.0), # Magenta
			StyleScoreManager.TimingQuality.GREAT: Color(0.0, 1.0, 1.0),   # Cyan
			StyleScoreManager.TimingQuality.GOOD: Color(0.0, 1.0, 0.0),    # Green
			StyleScoreManager.TimingQuality.OFF_BEAT: Color(0.5, 0.5, 0.5)  # Gray
		}
		
		var texts = {
			StyleScoreManager.TimingQuality.PERFECT: "PERFECT!",
			StyleScoreManager.TimingQuality.GREAT: "GREAT!",
			StyleScoreManager.TimingQuality.GOOD: "Good!",
			StyleScoreManager.TimingQuality.OFF_BEAT: ""
		}
		
		if quality != StyleScoreManager.TimingQuality.OFF_BEAT:
			var feedback = timing_feedback_script.new()
			ui_layer.add_child(feedback)
			feedback.setup(texts[quality], colors[quality], screen_pos + Vector2(0, -100))
		else:
			# Add subtle early/late feedback
			var timing_info = get_meta("last_timing", null)
			if timing_info and timing_info.distance < 0.5:  # Within 500ms but missed
				var feedback = timing_feedback_script.new()
				ui_layer.add_child(feedback)
				var subtle_text = "early" if timing_info.is_early else "late"
				feedback.setup(subtle_text, Color(0.5, 0.5, 0.5, 0.5), screen_pos + Vector2(0, -60))
				feedback.add_theme_font_size_override("font_size", 12)  # Smaller text

func _on_combo_changed(new_combo: int, _multiplier_increased: bool = false):
	update_ui()
	# Play combo sound through AudioManager
	if new_combo > 0 and new_combo <= 8:
		AudioManager.play_combo_sound(new_combo, _multiplier_increased)
	
	# Haptic feedback for combos
	if new_combo > 0:
		HapticFeedback.trigger_combo_pattern(new_combo)

# Old combo music function removed - now handled in _on_combo_changed

func _on_multiplier_changed(new_multiplier: int):
	var multiplier_indicator = get_meta("multiplier_indicator", null)
	if multiplier_indicator:
		multiplier_indicator.update_multiplier(new_multiplier)
	
	# Update background shader with new multiplier
	var background = get_node_or_null("Background")
	if background and background.material:
		background.material.set_shader_parameter("multiplier", float(new_multiplier))

func _unhandled_key_input(event):
	if event.pressed and player:
		match event.keycode:
			KEY_R:
				player.move_speed = min(2000, player.move_speed + 100)
				print("Player move speed: ", player.move_speed)
			KEY_T:
				player.move_speed = max(100, player.move_speed - 100)
				print("Player move speed: ", player.move_speed)
			KEY_F:
				player.move_speed = min(2000, player.move_speed + 10)
				print("Player move speed: ", player.move_speed)
			KEY_G:
				player.move_speed = max(100, player.move_speed - 10)
				print("Player move speed: ", player.move_speed)

func update_latency_display():
	if latency_label:
		latency_label.text = "Latency: " + str(int(audio_latency_offset * 1000)) + "ms"

func show_results_screen():
	var results_scene = preload("res://scenes/ui/PremiumResultsScreen.tscn")
	var results_screen = results_scene.instantiate()
	
	# Pass the game_manager reference before adding to tree
	results_screen.game_manager = self
	
	# Add to UILayer instead of directly to GameManager
	var ui_layer = get_node("UILayer")
	if ui_layer:
		ui_layer.add_child(results_screen)
	else:
		add_child(results_screen)
	
	var style_accuracy = 0.0
	var timing_counts = {}
	if style_score_manager:
		style_accuracy = style_score_manager.get_accuracy()
		timing_counts = style_score_manager.get_timing_counts()
	
	results_screen.show_results(level_complete_time, coins, total_coins_in_level, style_accuracy, current_level, timing_counts)

func restart_level():
	# Save current level before resetting
	var saved_level = current_level
	
	# Use start_game to properly reset everything
	start_game()
	
	# Restore the level we were on
	current_level = saved_level

func next_level():
	print("[GameManager] next_level() called - current level: ", current_level)
	
	# Check if next level exists before proceeding
	var next_level_num = current_level + 1
	var next_level_path = "res://levels/%03d.json" % next_level_num
	
	print("[GameManager] Checking for next level: ", next_level_path)
	
	if not FileAccess.file_exists(next_level_path):
		print("[GameManager] Next level does not exist - returning to menu")
		return_to_menu()
		return
	
	# Move to next level
	current_level = next_level_num
	print("[GameManager] Successfully moved to level: ", current_level)
	
	# Clear level completion state completely
	is_level_complete = false
	level_complete_time = 0.0
	
	# Disable goal detection temporarily during setup
	set_meta("level_transition_in_progress", true)
	
	# Reset game state
	score = 0
	coins = 0
	level_start_time = Time.get_ticks_msec() / 1000.0
	
	# Tell GameData about the new level
	GameData.start_level(current_level)
	
	# Clear any existing level objects
	if level_generator:
		print("[GameManager] Clearing existing level objects...")
		# Clear existing level and wait for cleanup
		for child in level_generator.get_children():
			child.queue_free()
		
		# Wait a frame to ensure cleanup is complete
		await get_tree().process_frame
		print("[GameManager] Level cleanup complete")
		
		# Setup new level
		print("[GameManager] Generating new level ", current_level)
		level_generator.current_level = current_level
		level_generator.generate_level()
		
		# Reset player position
		var spawn_pos = level_generator.get_player_spawn_position()
		print("[GameManager] Player spawn position: ", spawn_pos)
		if player:
			player.position = spawn_pos
			player.reset()
			print("[GameManager] Player reset to position: ", player.position)
			
			# Check if player position is same as any goal position (collision detection)
			var distance_to_goal = Vector2.ZERO
			for child in level_generator.get_children():
				if child.name.begins_with("Goal"):
					distance_to_goal = child.position - player.position
					print("[GameManager] WARNING: Distance from player to goal: ", distance_to_goal.length())
					if distance_to_goal.length() < 32:  # Less than half a grid cell
						print("[GameManager] CRITICAL: Player spawned too close to goal!")
	
	# Reset all scoring systems
	if style_score_manager:
		style_score_manager.reset_score()
	
	# Reset audio state
	AudioManager.stop_ambient_guitar()
	
	print("[GameManager] Level ", current_level, " setup complete")
	
	# Add a small delay to prevent immediate goal triggering
	print("[GameManager] Waiting brief moment before level becomes active...")
	await get_tree().create_timer(0.1).timeout
	
	# Re-enable goal detection
	set_meta("level_transition_in_progress", false)
	print("[GameManager] Level is now active and ready for play")

func return_to_menu():
	# If launched from editor, go back to editor instead
	if LevelEditorData.is_launched_from_editor():
		return_to_level_editor()
	else:
		# Return to main menu
		print("[GameManager] Returning to main menu")
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func return_to_level_editor():
	print("=== RETURNING TO LEVEL EDITOR ===")
	print("Has backup: ", LevelEditorData.get_editor_backup() != null)
	
	# Clear the launched from editor flag
	LevelEditorData.set_launched_from_editor(false)
	print("Cleared launched from editor flag")
	
	# Reset viewport settings for editor
	get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	get_window().content_scale_aspect = Window.CONTENT_SCALE_ASPECT_IGNORE
	get_window().size = Vector2i(2200, 1400)
	
	# Switch back to level editor
	print("Loading level editor scene...")
	var editor_scene = load("res://scenes/level_editor/LevelEditor.tscn")
	if editor_scene:
		print("Editor scene loaded successfully")
		get_tree().change_scene_to_packed(editor_scene)
		print("Scene change initiated")
	else:
		print("ERROR: Failed to load level editor scene")

func _on_goal_reached():
	print("[GameManager] _on_goal_reached() called - current_level: ", current_level, " is_level_complete: ", is_level_complete)
	
	# Check if we're in the middle of a level transition
	if get_meta("level_transition_in_progress", false):
		print("[GameManager] Level transition in progress - ignoring goal reached")
		return
	
	if is_level_complete:
		print("[GameManager] Level already complete - ignoring goal reached")
		return
		
	is_level_complete = true
	level_complete_time = (Time.get_ticks_msec() / 1000.0) - level_start_time
	
	# Stop the guitar if playing
	AudioManager.stop_ambient_guitar()
	
	# Level complete haptic feedback
	HapticFeedback.on_level_complete()
	
	print("[GameManager] Level ", current_level, " completed! Time: ", level_complete_time, " seconds")
	print("[GameManager] Coins collected: ", coins, " Score: ", score)
	if style_score_manager:
		print("[GameManager] Style accuracy: ", style_score_manager.get_accuracy(), "%")
	
	# Update GameData with completion
	GameData.complete_level(current_level, score, coins, level_complete_time)
	
	# Show results screen
	print("[GameManager] Showing results screen...")
	show_results_screen()

func show_go_message():
	# Create GO label
	var go_label = Label.new()
	go_label.text = "GO!"
	go_label.add_theme_font_size_override("font_size", 72)
	go_label.add_theme_color_override("font_color", Color(1, 1, 1))
	go_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0))
	go_label.add_theme_constant_override("shadow_offset_x", 4)
	go_label.add_theme_constant_override("shadow_offset_y", 4)
	
	# Center it on screen
	go_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	
	if ui_layer:
		ui_layer.add_child(go_label)
	
	# After 1 second, remove GO and start the game
	await get_tree().create_timer(1.0).timeout
	
	go_label.queue_free()
	
	# NOW we start everything in sync
	game_started = true
	level_start_time = Time.get_ticks_msec() / 1000.0
	print("[GameManager] Game started at: ", level_start_time)
	
	# Start beat tracking
	print("[GameManager] Starting beat tracking")
	AudioManager.start_beat_tracking()
	beat_tracking_started = true

func initialize_effect_systems():
	# Initialize ScreenShake system
	screen_shake = ScreenShake.new()
	add_child(screen_shake)
	
	# Set camera for screen shake once player is created
	call_deferred("setup_screen_shake_camera")
	
	# Initialize ParticleManager
	particle_manager = ParticleManager.new()
	add_child(particle_manager)
	
	# Initialize LatencyCompensator
	latency_compensator = LatencyCompensator.new()
	add_child(latency_compensator)
	latency_compensator.latency_measured.connect(_on_latency_measured)
	
	# Load saved calibration if available
	if not latency_compensator.load_calibration():
		latency_compensator.auto_detect_latency()
	
	# Initialize AudioAnalyzer
	audio_analyzer = AudioAnalyzer.new()
	add_child(audio_analyzer)
	audio_analyzer.beat_detected.connect(_on_audio_beat_detected)
	audio_analyzer.tempo_detected.connect(_on_tempo_detected)
	
	# REMOVED: Beat counter UI
	# beat_indicator_ui = BeatIndicatorUI.new()
	# ui_layer.add_child(beat_indicator_ui)
	# beat_indicator_ui.set_position_preset("bottom_center")
	
	# Initialize Grid Star Effect
	var grid_star_script = preload("res://scripts/effects/GridStarEffect.gd")
	grid_star_effect = grid_star_script.new()
	add_child(grid_star_effect)
	grid_star_effect.z_index = -3  # Behind game but in front of background
	
	# Initialize Mobile Controls
	var mobile_controls_scene = preload("res://scenes/ui/MobileControls.tscn")
	mobile_controls = mobile_controls_scene.instantiate()
	add_child(mobile_controls)
	mobile_controls.layer = 100  # On top of everything

func setup_screen_shake_camera():
	if player and player.get_node_or_null("Camera2D"):
		screen_shake.set_camera(player.get_node("Camera2D"))

func _on_latency_measured(latency_ms: float):
	audio_latency_offset = latency_ms / 1000.0
	print("[GameManager] Latency compensation set to: ", latency_ms, "ms")
	
	# Update latency display
	if latency_label:
		latency_label.text = "Latency: " + str(int(latency_ms)) + "ms"

func _on_audio_beat_detected(strength: float, frequency_band: String):
	# Enhanced beat detection from audio analysis
	print("[GameManager] Audio beat detected - Strength: ", strength, " Band: ", frequency_band)
	
	# Could trigger additional visual effects based on frequency band
	match frequency_band:
		"bass":
			# Bass beats could trigger screen shake or particle bursts
			if screen_shake and strength > 0.8:
				screen_shake.add_trauma(strength * 0.1)
		"mid":
			# Mid-frequency beats could affect UI pulsing
			pass
		"treble":
			# Treble beats could trigger sparkle effects
			pass

func _on_tempo_detected(bpm: float):
	print("[GameManager] Tempo detected: ", bpm, " BPM")
	
	# Update beat indicator with detected tempo
	# REMOVED: Beat counter UI
	# if beat_indicator_ui:
	#	var beat_interval = 60.0 / bpm
	#	beat_indicator_ui.set_beat_interval(beat_interval)
