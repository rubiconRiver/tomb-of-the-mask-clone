extends Node
class_name GameManager

var player_scene = preload("res://scenes/player/Player.tscn")
var level_generator_scene = preload("res://scenes/levels/LevelGenerator.tscn")
var beat_indicator_script = preload("res://scripts/ui/BeatIndicator.gd")
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
var beat_indicator: Control
var beat_timeline: BeatTimeline
var style_score_manager: StyleScoreManager
var beat_visualizer: BeatVisualizer
# Audio now handled by AudioManager singleton

var score = 0  # Total points (coins × multiplier)
var coins = 0  # Number of coins collected
var current_level = 2  # Start with Garett's tutorial
var is_game_over = false
var game_started = false
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

@onready var ui_layer = $UILayer
@onready var score_label = $UILayer/ScoreLabel
@onready var coins_label = $UILayer/CoinsLabel
@onready var combo_label = $UILayer/ComboLabel
@onready var latency_label = $UILayer/LatencyLabel
@onready var game_over_panel = $UILayer/GameOverPanel

func _ready():
	# Initialize sound bank
	SoundBank.initialize()
	
	swipe_detector = SwipeDetector.new()
	add_child(swipe_detector)
	swipe_detector.swiped.connect(_on_swipe_detected)
	
	style_score_manager = style_score_manager_script.new()
	add_child(style_score_manager)
	style_score_manager.timing_calculated.connect(_on_timing_calculated)
	style_score_manager.combo_changed.connect(_on_combo_changed)
	style_score_manager.multiplier_changed.connect(_on_multiplier_changed)
	
	setup_camera()
	setup_beat_indicator()
	setup_beat_timeline()
	setup_beat_visualizer()
	setup_multiplier_indicator()
	setup_timing_monitor()
	
	# Connect to AudioManager signals
	AudioManager.beat_occurred.connect(_on_beat)
	AudioManager.eighth_note_occurred.connect(_on_eighth_note)
	
	start_game()

func setup_camera():
	camera = Camera2D.new()
	camera.enabled = true
	add_child(camera)

func setup_beat_indicator():
	beat_indicator = beat_indicator_script.new()
	beat_indicator.position = Vector2(20, 20)
	
	if ui_layer:
		ui_layer.add_child(beat_indicator)
		
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
	if camera and player:
		camera.position = player.position
		# Update background shader with camera position
		var background = get_node_or_null("Background")
		if background and background.material:
			background.material.set_shader_parameter("camera_position", camera.position)
		
	# Handle beat speed controls
	if Input.is_action_just_pressed("ui_up"):
		AudioManager.beat_interval = max(0.2, AudioManager.beat_interval - 0.05)
		print("Beat interval: ", AudioManager.beat_interval)
	elif Input.is_action_just_pressed("ui_down"):
		AudioManager.beat_interval = min(2.0, AudioManager.beat_interval + 0.05)
		print("Beat interval: ", AudioManager.beat_interval)
		
	# Handle player speed adjustment with dedicated keys
	
	# Handle audio latency adjustment
	if Input.is_action_just_pressed("ui_left"):
		audio_latency_offset = max(-0.2, audio_latency_offset - 0.01)
		update_latency_display()
		print("Audio latency offset: ", audio_latency_offset * 1000, "ms")
	elif Input.is_action_just_pressed("ui_right"):
		audio_latency_offset = min(0.2, audio_latency_offset + 0.01)
		update_latency_display()
		print("Audio latency offset: ", audio_latency_offset * 1000, "ms")
		
	
	# Return to level editor with M key when launched from editor
	if Input.is_key_pressed(KEY_M) and LevelEditorData.is_launched_from_editor():
		print("M key pressed - checking if we should return to editor")
		print("Is launched from editor: ", LevelEditorData.is_launched_from_editor())
		return_to_level_editor()
		return  # Prevent further processing this frame
		
	# Update beat timeline
	if beat_timeline:
		beat_timeline.update_beat(AudioManager.get_beat_progress(), AudioManager.beat_interval)

func start_game():
	score = 0
	coins = 0
	current_level = 2  # Start with Garett's tutorial
	is_game_over = false
	game_started = false  # Will be set to true after GO message
	is_level_complete = false
	level_start_time = 0.0  # Will be set when game actually starts
	pending_coin_chimes = 0
	pending_wall_hits = 0
	pending_coin_chimes_8th = 0
	pending_wall_hits_8th = 0
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
	
	# Show GO message and start game after delay
	show_go_message()

func setup_level():
	if level_generator:
		level_generator.queue_free()
		
	level_generator = level_generator_scene.instantiate()
	add_child(level_generator)
	
	# Pass the current level to the generator
	level_generator.current_level = current_level
	
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
	player.moved.connect(_on_player_moved)
	player.hit_wall.connect(_on_player_hit_wall)
	
	# Remove the old techno shader application since player now has its own visual system
	# The player handles its own visuals through PlayerVisual.gd
	
	if camera:
		camera.position = player.position

func _on_beat(beat_count_param: int):
	# Update beat indicator with appropriate pulse strength
	if beat_indicator:
		if beat_count_param % 4 == 0:
			beat_indicator.pulse_strong()
		else:
			beat_indicator.pulse()
	
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
	# Play hi-hat
	AudioManager.play_hihat()
	
	# Play pending 8th note sounds
	if pending_coin_chimes_8th > 0:
		AudioManager.play_coin_collected()
		pending_coin_chimes_8th -= 1
	
	if pending_wall_hits_8th > 0:
		AudioManager.play_wall_hit()
		pending_wall_hits_8th -= 1

# Old audio functions removed - now handled by AudioManager
func _on_swipe_detected(direction: Vector2):
	if not game_started or is_game_over or not player or player.is_moving:
		return
	
	# Start the guitar chord when movement begins
	# AudioManager.start_ambient_guitar()  # DISABLED FOR TESTING
	
	# Calculate timing and score
	var timing_result = style_score_manager.register_move(AudioManager.get_beat_progress(), AudioManager.beat_interval)
	
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
	# AudioManager.stop_ambient_guitar()  # DISABLED FOR TESTING
	is_game_over = true
	if game_over_panel:
		game_over_panel.visible = true

func _on_coin_collected():
	# Increment coin count
	coins += 1
	
	# Add to score based on current multiplier
	var multiplier = style_score_manager.get_current_multiplier()
	score += 10 * multiplier  # Base value 10 × multiplier
	
	update_ui()
	
	# Queue coin chime to play on next 8th note (much more responsive!)
	pending_coin_chimes_8th += 1
	print("Coin collected (", multiplier, "x) - Score: ", score)

func _on_player_moved():
	# Stop the guitar chord when movement ends
	# AudioManager.stop_ambient_guitar()  # DISABLED FOR TESTING
	# Score is now handled by timing system in _on_swipe_detected
	pass

func _on_player_hit_wall():
	# Queue wall hit tom fill to play on next 8th note (much more responsive!)
	pending_wall_hits_8th += 1
	print("Wall hit - tom fill queued for next 8th note")

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
	
	results_screen.show_results(level_complete_time, coins, total_coins_in_level, style_accuracy, current_level + 1, timing_counts)

func restart_level():
	# Save current level before resetting
	var saved_level = current_level
	
	# Use start_game to properly reset everything
	start_game()
	
	# Restore the level we were on
	current_level = saved_level

func next_level():
	current_level += 1
	is_level_complete = false
	level_start_time = Time.get_ticks_msec() / 1000.0
	coins = 0
	
	# Generate the next level
	if level_generator:
		level_generator.generate_level()
		var spawn_pos = level_generator.get_player_spawn_position()
		if player:
			player.position = spawn_pos
			player.reset()
	
	# Reset style scoring
	if style_score_manager:
		style_score_manager.reset_score()

func return_to_menu():
	# If launched from editor, go back to editor instead
	if LevelEditorData.is_launched_from_editor():
		return_to_level_editor()
	else:
		# For now, just restart the game
		start_game()

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
	if is_level_complete:
		return
		
	is_level_complete = true
	level_complete_time = (Time.get_ticks_msec() / 1000.0) - level_start_time
	
	# Stop the guitar if playing
	# AudioManager.stop_ambient_guitar()  # DISABLED FOR TESTING
	
	print("Level completed! Time: ", level_complete_time, " seconds")
	print("Coins collected: ", coins)
	print("Style accuracy: ", style_score_manager.get_accuracy(), "%")
	
	# Show results screen
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
