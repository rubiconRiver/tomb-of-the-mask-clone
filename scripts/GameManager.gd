extends Node
class_name GameManager

var player_scene = preload("res://scenes/player/Player.tscn")
var level_generator_scene = preload("res://scenes/levels/LevelGenerator.tscn")
var beat_indicator_script = preload("res://scripts/ui/BeatIndicator.gd")
var style_score_manager_script = preload("res://scripts/ui/StyleScoreManager.gd")
var timing_feedback_script = preload("res://scripts/ui/TimingFeedback.gd")
var beat_timeline_script = preload("res://scripts/ui/BeatTimeline.gd")
var beat_visualizer_script = preload("res://scripts/visual/BeatVisualizer.gd")

var player: Player
var level_generator: LevelGenerator
var swipe_detector: SwipeDetector
var camera: Camera2D
var beat_indicator: Control
var beat_timeline: BeatTimeline
var style_score_manager: StyleScoreManager
var beat_visualizer: BeatVisualizer

var score = 0
var coins = 0
var current_level = 0
var is_game_over = false

var beat_timer = 0.0
var beat_interval = 0.5
var audio_latency_offset = 0.0  # Default to 0 as requested

@onready var ui_layer = $UILayer
@onready var score_label = $UILayer/ScoreLabel
@onready var coins_label = $UILayer/CoinsLabel
@onready var combo_label = $UILayer/ComboLabel
@onready var latency_label = $UILayer/LatencyLabel
@onready var game_over_panel = $UILayer/GameOverPanel
@onready var beat_audio: AudioStreamPlayer

signal beat_occurred

func _ready():
	swipe_detector = SwipeDetector.new()
	add_child(swipe_detector)
	swipe_detector.swiped.connect(_on_swipe_detected)
	
	style_score_manager = style_score_manager_script.new()
	add_child(style_score_manager)
	style_score_manager.timing_calculated.connect(_on_timing_calculated)
	style_score_manager.combo_changed.connect(_on_combo_changed)
	
	setup_camera()
	setup_beat_indicator()
	setup_beat_timeline()
	setup_beat_audio()
	setup_beat_visualizer()
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
		
	beat_occurred.connect(beat_indicator.pulse)

func setup_beat_timeline():
	beat_timeline = beat_timeline_script.new()
	
	if ui_layer:
		ui_layer.add_child(beat_timeline)

func setup_beat_audio():
	beat_audio = AudioStreamPlayer.new()
	add_child(beat_audio)
	beat_audio.volume_db = -10.0
	
	# Create a simple click sound using AudioStreamGenerator
	var audio_generator = AudioStreamGenerator.new()
	audio_generator.mix_rate = 44100
	audio_generator.buffer_length = 0.5  # Buffer for continuous playback
	
	beat_audio.stream = audio_generator

func setup_beat_visualizer():
	beat_visualizer = beat_visualizer_script.new()
	add_child(beat_visualizer)
	beat_occurred.connect(beat_visualizer.trigger_beat)

func _process(delta):
	if camera and player:
		camera.position = player.position
		
	# Handle beat speed controls
	if Input.is_action_just_pressed("ui_up"):
		beat_interval = max(0.2, beat_interval - 0.05)
		print("Beat interval: ", beat_interval)
	elif Input.is_action_just_pressed("ui_down"):
		beat_interval = min(2.0, beat_interval + 0.05)
		print("Beat interval: ", beat_interval)
		
	# Handle audio latency adjustment
	if Input.is_action_just_pressed("ui_left"):
		audio_latency_offset = max(-0.2, audio_latency_offset - 0.01)
		update_latency_display()
		print("Audio latency offset: ", audio_latency_offset * 1000, "ms")
	elif Input.is_action_just_pressed("ui_right"):
		audio_latency_offset = min(0.2, audio_latency_offset + 0.01)
		update_latency_display()
		print("Audio latency offset: ", audio_latency_offset * 1000, "ms")
		
	# Toggle beat timeline with ESC
	if Input.is_action_just_pressed("ui_cancel"):
		if beat_timeline:
			beat_timeline.toggle_visibility()
		
	beat_timer += delta
	
	# Play sound slightly early to compensate for audio latency
	if beat_timer >= beat_interval - audio_latency_offset and beat_timer - delta < beat_interval - audio_latency_offset:
		play_beat_sound()
	
	if beat_timer >= beat_interval:
		beat_timer -= beat_interval
		_on_beat()
		
	# Update beat timeline
	if beat_timeline:
		beat_timeline.update_beat(beat_timer, beat_interval)

func start_game():
	score = 0
	coins = 0
	current_level = 0
	is_game_over = false
	
	if game_over_panel:
		game_over_panel.visible = false
	
	setup_level()
	spawn_player()
	update_ui()
	update_latency_display()

func setup_level():
	if level_generator:
		level_generator.queue_free()
		
	level_generator = level_generator_scene.instantiate()
	add_child(level_generator)

func spawn_player():
	if player:
		player.queue_free()
		
	player = player_scene.instantiate()
	add_child(player)
	
	player.position = level_generator.get_player_spawn_position()
	player.died.connect(_on_player_died)
	player.collected_coin.connect(_on_coin_collected)
	player.moved.connect(_on_player_moved)
	
	# Remove the old techno shader application since player now has its own visual system
	# The player handles its own visuals through PlayerVisual.gd
	
	if camera:
		camera.position = player.position

func _on_beat():
	emit_signal("beat_occurred")
	
	# Pulse the background
	var background = get_node_or_null("Background")
	if background and background.material:
		var tween = get_tree().create_tween()
		tween.tween_property(background.material, "shader_parameter/pulse_strength", 0.6, 0.1)
		tween.tween_property(background.material, "shader_parameter/pulse_strength", 0.3, 0.3)

func play_beat_sound():
	if not beat_audio or not beat_audio.stream:
		return
		
	# Make sure the audio player is playing
	if not beat_audio.playing:
		beat_audio.play()
		
	# Generate snare + tambourine sound on each beat
	var playback = beat_audio.get_stream_playback() as AudioStreamGeneratorPlayback
	if playback:
		var sample_rate = 44100
		var duration = 0.08
		var frames = int(sample_rate * duration)
		
		for i in frames:
			var time = float(i) / sample_rate
			
			# Snare drum component (noise burst)
			var noise = (randf() * 2.0 - 1.0) * exp(-time * 30.0)
			
			# Tambourine component (multiple high frequencies)
			var tambourine = 0.0
			for freq in [3000.0, 4500.0, 6000.0]:
				tambourine += sin(2.0 * PI * freq * time) * 0.2
			tambourine *= exp(-time * 25.0)
			
			# Mix snare and tambourine
			var sample = (noise * 0.7 + tambourine * 0.3) * 0.5
			playback.push_frame(Vector2(sample, sample))

func _on_swipe_detected(direction: Vector2):
	if not is_game_over and player and not player.is_moving:
		# Calculate timing and score
		var timing_result = style_score_manager.register_move(beat_timer, beat_interval)
		
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
	is_game_over = true
	if game_over_panel:
		game_over_panel.visible = true

func _on_coin_collected():
	coins += 1
	score += 10
	update_ui()

func _on_player_moved():
	# Score is now handled by timing system in _on_swipe_detected
	pass

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

func _on_combo_changed(new_combo: int):
	update_ui()

func update_latency_display():
	if latency_label:
		latency_label.text = "Latency: " + str(int(audio_latency_offset * 1000)) + "ms"