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
var level_start_time = 0.0
var level_complete_time = 0.0
var is_level_complete = false
var total_coins_in_level = 0

var beat_timer = 0.0
var beat_interval = 0.5
var audio_latency_offset = 0.0  # Default to 0 as requested
var beat_count = 0
var hihat_timer = 0.0
var hihat_interval = 0.25  # 8th notes
var guitar_sample_timer = 0.0
var guitar_time_position = 0.0
var guitar_is_playing = false

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
@onready var beat_audio: AudioStreamPlayer
@onready var hihat_audio: AudioStreamPlayer
@onready var guitar_audio: AudioStreamPlayer
@onready var coin_audio: AudioStreamPlayer
@onready var wall_hit_audio: AudioStreamPlayer

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
	setup_hihat_audio()
	setup_guitar_audio()
	setup_coin_audio()
	setup_wall_hit_audio()
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
	beat_audio.volume_db = -8.0
	
	# Create audio generator for kick and snare
	var audio_generator = AudioStreamGenerator.new()
	audio_generator.mix_rate = 44100
	audio_generator.buffer_length = 0.5  # Buffer for continuous playback
	
	beat_audio.stream = audio_generator

func setup_hihat_audio():
	hihat_audio = AudioStreamPlayer.new()
	add_child(hihat_audio)
	hihat_audio.volume_db = -15.0  # Quieter hi-hat
	
	# Create audio generator for hi-hat
	var hihat_generator = AudioStreamGenerator.new()
	hihat_generator.mix_rate = 44100
	hihat_generator.buffer_length = 0.3
	
	hihat_audio.stream = hihat_generator

func setup_guitar_audio():
	guitar_audio = AudioStreamPlayer.new()
	add_child(guitar_audio)
	guitar_audio.volume_db = -12.0  # Ambient level
	
	# Create audio generator for guitar
	var guitar_generator = AudioStreamGenerator.new()
	guitar_generator.mix_rate = 44100
	guitar_generator.buffer_length = 1.0  # Longer buffer for sustained sound
	
	guitar_audio.stream = guitar_generator

func setup_coin_audio():
	coin_audio = AudioStreamPlayer.new()
	add_child(coin_audio)
	coin_audio.volume_db = -8.0  # Clear and present
	
	# Create audio generator for coin chime
	var coin_generator = AudioStreamGenerator.new()
	coin_generator.mix_rate = 44100
	coin_generator.buffer_length = 0.5
	
	coin_audio.stream = coin_generator

func setup_wall_hit_audio():
	wall_hit_audio = AudioStreamPlayer.new()
	add_child(wall_hit_audio)
	wall_hit_audio.volume_db = -6.0  # Punchy tom sound
	
	# Create audio generator for wall hit tom fill
	var wall_hit_generator = AudioStreamGenerator.new()
	wall_hit_generator.mix_rate = 44100
	wall_hit_generator.buffer_length = 0.8
	
	wall_hit_audio.stream = wall_hit_generator

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
		
	
	# Return to level editor with E key
	if Input.is_action_just_pressed("ui_select"):  # Usually Enter/Space
		var editor_scene = preload("res://scenes/level_editor/LevelEditor.tscn")
		get_tree().change_scene_to_packed(editor_scene)
		
	beat_timer += delta
	hihat_timer += delta
	
	# Play sound slightly early to compensate for audio latency
	if beat_timer >= beat_interval - audio_latency_offset and beat_timer - delta < beat_interval - audio_latency_offset:
		play_beat_sound()
	
	# Play hi-hat on 8th notes
	if hihat_timer >= hihat_interval - audio_latency_offset and hihat_timer - delta < hihat_interval - audio_latency_offset:
		play_hihat_sound()
		
		# Also trigger coin chimes and wall hits on 8th notes
		if pending_coin_chimes_8th > 0:
			play_coin_chime()
			pending_coin_chimes_8th -= 1
			
		if pending_wall_hits_8th > 0:
			play_wall_hit_tom_fill()
			pending_wall_hits_8th -= 1
	
	# Update guitar streaming if playing
	if guitar_is_playing:
		update_guitar_stream(delta)
	
	if beat_timer >= beat_interval:
		beat_timer -= beat_interval
		beat_count += 1
		_on_beat()
		
	if hihat_timer >= hihat_interval:
		hihat_timer -= hihat_interval
		
	# Update beat timeline
	if beat_timeline:
		beat_timeline.update_beat(beat_timer, beat_interval)

func start_game():
	score = 0
	coins = 0
	current_level = 0
	is_game_over = false
	is_level_complete = false
	level_start_time = Time.get_ticks_msec() / 1000.0
	beat_count = 0
	beat_timer = 0.0
	hihat_timer = 0.0
	guitar_sample_timer = 0.0
	guitar_time_position = 0.0
	guitar_is_playing = false
	pending_coin_chimes = 0
	pending_wall_hits = 0
	pending_coin_chimes_8th = 0
	pending_wall_hits_8th = 0
	
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

func _on_beat():
	emit_signal("beat_occurred")
	
	# Play any pending beat-synchronized audio effects
	if pending_coin_chimes > 0:
		play_coin_chime()
		pending_coin_chimes -= 1
	
	if pending_wall_hits > 0:
		play_wall_hit_tom_fill()
		pending_wall_hits -= 1
	
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
		
	var playback = beat_audio.get_stream_playback() as AudioStreamGeneratorPlayback
	if playback:
		# Play kick on beats 1 and 3, snare on beats 2 and 4
		if beat_count % 4 == 0 or beat_count % 4 == 2:  # beats 1 and 3
			generate_kick_drum(playback)
		else:  # beats 2 and 4
			generate_snare_drum(playback)

func generate_kick_drum(playback: AudioStreamGeneratorPlayback):
	var sample_rate = 44100
	var duration = 0.15
	var frames = int(sample_rate * duration)
	
	for i in frames:
		var time = float(i) / sample_rate
		var envelope = exp(-time * 15.0)
		var frequency = 60.0 + 40.0 * exp(-time * 20.0)  # Pitch sweep down
		var sample = sin(2.0 * PI * frequency * time) * envelope
		playback.push_frame(Vector2(sample, sample) * 0.8)

func generate_snare_drum(playback: AudioStreamGeneratorPlayback):
	var sample_rate = 44100
	var duration = 0.1
	var frames = int(sample_rate * duration)
	
	for i in frames:
		var time = float(i) / sample_rate
		var envelope = exp(-time * 25.0)
		
		# Snare drum component (noise burst)
		var noise = (randf() * 2.0 - 1.0) * 0.7
		
		# Tonal component
		var tone = sin(2.0 * PI * 200.0 * time) * 0.3
		
		var sample = (noise + tone) * envelope
		playback.push_frame(Vector2(sample, sample) * 0.6)

func play_hihat_sound():
	if not hihat_audio or not hihat_audio.stream:
		return
		
	if not hihat_audio.playing:
		hihat_audio.play()
		
	var playback = hihat_audio.get_stream_playback() as AudioStreamGeneratorPlayback
	if playback:
		generate_hihat_sound(playback)

func generate_hihat_sound(playback: AudioStreamGeneratorPlayback):
	var sample_rate = 44100
	var duration = 0.05  # Very short for crisp hi-hat
	var frames = int(sample_rate * duration)
	
	for i in frames:
		var time = float(i) / sample_rate
		var envelope = exp(-time * 40.0)  # Very fast decay
		
		# Generate hi-hat with high-frequency noise and metallic shimmer
		var noise = (randf() * 2.0 - 1.0) * 0.8
		var metallic1 = sin(2.0 * PI * 8000.0 * time) * 0.3
		var metallic2 = sin(2.0 * PI * 12000.0 * time) * 0.2
		
		var sample = (noise + metallic1 + metallic2) * envelope
		playback.push_frame(Vector2(sample, sample) * 0.4)  # Quieter volume

func start_guitar_chord():
	if not guitar_audio or not guitar_audio.stream:
		return
		
	if not guitar_audio.playing:
		guitar_audio.play()
	
	# Start streaming mode
	guitar_is_playing = true
	guitar_time_position = 0.0
	guitar_sample_timer = 0.0
	print("Guitar chord streaming started")

func stop_guitar_chord():
	if guitar_audio and guitar_is_playing:
		# Fade out the guitar instead of abrupt stop
		var tween = get_tree().create_tween()
		tween.tween_property(guitar_audio, "volume_db", -30.0, 0.2)
		tween.tween_callback(func(): 
			guitar_audio.stop()
			guitar_is_playing = false
		)
		tween.tween_property(guitar_audio, "volume_db", -12.0, 0.0)  # Reset for next time
		print("Guitar chord fading out")

func update_guitar_stream(delta: float):
	if not guitar_audio or not guitar_audio.playing or not guitar_is_playing:
		return
	
	var playback = guitar_audio.get_stream_playback() as AudioStreamGeneratorPlayback
	if not playback:
		return
	
	# Generate small chunks of audio to avoid stuttering
	var sample_rate = 44100.0
	var chunk_duration = 0.02  # 20ms chunks - small enough to avoid stuttering
	var samples_per_chunk = int(sample_rate * chunk_duration)
	
	guitar_sample_timer += delta
	
	# Generate chunks as needed
	while guitar_sample_timer >= chunk_duration:
		guitar_sample_timer -= chunk_duration
		generate_guitar_chunk(playback, samples_per_chunk, sample_rate)

func generate_guitar_chunk(playback: AudioStreamGeneratorPlayback, chunk_size: int, sample_rate: float):
	# Define a nice ambient chord (Cmaj7 - C, E, G, B)
	var chord_frequencies = [261.63, 329.63, 392.00, 493.88]  # C4, E4, G4, B4
	
	for i in chunk_size:
		var time = guitar_time_position
		var envelope = 1.0 - exp(-time * 3.0)  # Slow attack
		envelope *= exp(-time * 0.3)  # Very slow decay for sustain
		
		var chord_sample = 0.0
		for freq in chord_frequencies:
			# Simplified generation for better performance
			var fundamental = sin(2.0 * PI * freq * time) * 0.7
			var harmonic = sin(2.0 * PI * freq * 2.0 * time) * 0.2
			chord_sample += (fundamental + harmonic) / 4.0
		
		var final_sample = chord_sample * envelope * 0.25  # Ambient volume
		playback.push_frame(Vector2(final_sample, final_sample))
		
		# Advance time position
		guitar_time_position += 1.0 / sample_rate

func play_coin_chime():
	if not coin_audio or not coin_audio.stream:
		return
		
	if not coin_audio.playing:
		coin_audio.play()
		
	var playback = coin_audio.get_stream_playback() as AudioStreamGeneratorPlayback
	if playback:
		generate_coin_chime(playback)

func generate_coin_chime(playback: AudioStreamGeneratorPlayback):
	var sample_rate = 44100
	var duration = 0.2  # Shorter for 8th note frequency
	var frames = int(sample_rate * duration)
	
	# Three beautiful coin chime variations - pleasing melodic intervals
	var chime_sets = [
		[1046.5, 1318.5, 1568.0],  # C6, E6, G6 (major triad - bright & happy)
		[1174.7, 1318.5, 1568.0],  # D6, E6, G6 (sus2 harmony - dreamy)
		[1046.5, 1244.5, 1568.0]   # C6, D#6, G6 (major with color tone - mystical)
	]
	
	# Randomly choose one of the three chime sets
	var chime_frequencies = chime_sets[randi() % chime_sets.size()]
	
	for i in frames:
		var time = float(i) / sample_rate
		var envelope = exp(-time * 12.0)  # Faster decay for crisp 8th note timing
		
		var chime_sample = 0.0
		for freq in chime_frequencies:
			# Add harmonics for bell-like quality
			var fundamental = sin(2.0 * PI * freq * time) * 0.6
			var harmonic2 = sin(2.0 * PI * freq * 2.0 * time) * 0.2
			var harmonic3 = sin(2.0 * PI * freq * 3.0 * time) * 0.1
			chime_sample += (fundamental + harmonic2 + harmonic3) / 3.0
		
		var final_sample = chime_sample * envelope * 0.35  # Slightly quieter for frequent use
		playback.push_frame(Vector2(final_sample, final_sample))

func play_wall_hit_tom_fill():
	if not wall_hit_audio or not wall_hit_audio.stream:
		return
		
	if not wall_hit_audio.playing:
		wall_hit_audio.play()
		
	var playback = wall_hit_audio.get_stream_playback() as AudioStreamGeneratorPlayback
	if playback:
		generate_wall_hit_tom_fill(playback)

func generate_wall_hit_tom_fill(playback: AudioStreamGeneratorPlayback):
	var sample_rate = 44100
	var duration = 0.4  # Slightly longer for 3-note fill
	var frames = int(sample_rate * duration)
	
	for i in frames:
		var time = float(i) / sample_rate
		var envelope = exp(-time * 10.0)  # Moderate decay for punchy tom sequence
		
		# Three tom hits: du-du-DUH pattern (high-high-low)
		var tom1_freq = 180.0  # High tom (du)
		var tom2_freq = 160.0  # High tom (du) 
		var tom3_freq = 80.0   # Low tom (DUH!)
		
		# Timing: tom1 (0-0.08s), tom2 (0.08-0.16s), tom3 (0.16-0.32s)
		var tom_sample = 0.0
		if time < 0.08:
			# First tom (du) - crisp and high
			tom_sample = sin(2.0 * PI * tom1_freq * time) * exp(-time * 30.0) * 0.8
		elif time < 0.16:
			# Second tom (du) - similar pitch, slight variation
			var tom2_time = time - 0.08
			tom_sample = sin(2.0 * PI * tom2_freq * tom2_time) * exp(-tom2_time * 30.0) * 0.8
		elif time < 0.32:
			# Third tom (DUH!) - deep and punchy
			var tom3_time = time - 0.16
			tom_sample = sin(2.0 * PI * tom3_freq * tom3_time) * exp(-tom3_time * 20.0) * 1.2  # Louder for emphasis
		
		# Add noise for realistic tom texture
		var noise = (randf() * 2.0 - 1.0) * 0.25 * envelope
		var final_sample = (tom_sample + noise) * envelope * 0.75
		
		playback.push_frame(Vector2(final_sample, final_sample))

func _on_swipe_detected(direction: Vector2):
	if not is_game_over and player and not player.is_moving:
		# Start the guitar chord when movement begins
		start_guitar_chord()
		
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
	# Stop the guitar chord when player dies
	guitar_is_playing = false
	stop_guitar_chord()
	is_game_over = true
	if game_over_panel:
		game_over_panel.visible = true

func _on_coin_collected():
	coins += 1
	score += 10
	update_ui()
	
	# Queue coin chime to play on next 8th note (much more responsive!)
	pending_coin_chimes_8th += 1
	print("Coin collected - chime queued for next 8th note")

func _on_player_moved():
	# Stop the guitar chord when movement ends
	stop_guitar_chord()
	# Score is now handled by timing system in _on_swipe_detected

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

func _on_combo_changed(new_combo: int):
	update_ui()

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
	# For now, just restart the game
	start_game()

func _on_goal_reached():
	if is_level_complete:
		return
		
	is_level_complete = true
	level_complete_time = (Time.get_ticks_msec() / 1000.0) - level_start_time
	
	# Stop the guitar if playing
	stop_guitar_chord()
	
	print("Level completed! Time: ", level_complete_time, " seconds")
	print("Coins collected: ", coins)
	print("Style accuracy: ", style_score_manager.get_accuracy(), "%")
	
	# Show results screen
	show_results_screen()
