extends Node
class_name GameManager

var player_scene = preload("res://scenes/player/Player.tscn")
var level_generator_scene = preload("res://scenes/levels/LevelGenerator.tscn")
var beat_indicator_script = preload("res://scripts/ui/BeatIndicator.gd")
var style_score_manager_script = preload("res://scripts/ui/StyleScoreManager.gd")

var player: Player
var level_generator: LevelGenerator
var swipe_detector: SwipeDetector
var camera: Camera2D
var beat_indicator: Control
var style_score_manager: StyleScoreManager

var score = 0
var coins = 0
var current_level = 0
var is_game_over = false

var beat_timer = 0.0
var beat_interval = 0.5

@onready var ui_layer = $UILayer
@onready var score_label = $UILayer/ScoreLabel
@onready var coins_label = $UILayer/CoinsLabel
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
	
	setup_camera()
	setup_beat_indicator()
	setup_beat_audio()
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

func setup_beat_audio():
	beat_audio = AudioStreamPlayer.new()
	add_child(beat_audio)
	beat_audio.volume_db = -10.0
	
	# Create a simple click sound using AudioStreamGenerator
	var audio_generator = AudioStreamGenerator.new()
	audio_generator.mix_rate = 44100
	audio_generator.buffer_length = 0.5  # Buffer for continuous playback
	
	beat_audio.stream = audio_generator

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
		
	beat_timer += delta
	if beat_timer >= beat_interval:
		beat_timer -= beat_interval
		_on_beat()

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
	
	if camera:
		camera.position = player.position

func _on_beat():
	emit_signal("beat_occurred")
	
	# Play the beat sound
	play_beat_sound()

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
		print("Move timing: ", timing_result.name, " Combo: ", timing_result.combo)
		
		# Apply score multiplier
		var base_score = 1
		score += int(base_score * timing_result.multiplier)
		update_ui()
		
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

func restart_game():
	start_game()

func _on_timing_calculated(quality: int, multiplier: float):
	# This will be used for visual feedback in Stage 4
	pass