extends Node
class_name GameManager

var player_scene = preload("res://scenes/player/Player.tscn")
var level_generator_scene = preload("res://scenes/levels/LevelGenerator.tscn")

var player: Player
var level_generator: LevelGenerator
var swipe_detector: SwipeDetector
var camera: Camera2D

var score = 0
var coins = 0
var current_level = 0
var is_game_over = false

@onready var ui_layer = $UILayer
@onready var score_label = $UILayer/ScoreLabel
@onready var coins_label = $UILayer/CoinsLabel
@onready var game_over_panel = $UILayer/GameOverPanel

func _ready():
	swipe_detector = SwipeDetector.new()
	add_child(swipe_detector)
	swipe_detector.swiped.connect(_on_swipe_detected)
	
	setup_camera()
	start_game()

func setup_camera():
	camera = Camera2D.new()
	camera.enabled = true
	add_child(camera)

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

func _on_swipe_detected(direction: Vector2):
	if not is_game_over and player:
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
	score += 1
	update_ui()
	
	if camera:
		var tween = get_tree().create_tween()
		tween.tween_property(camera, "position", player.position, 0.2)

func update_ui():
	if score_label:
		score_label.text = "Score: " + str(score)
	if coins_label:
		coins_label.text = "Coins: " + str(coins)

func restart_game():
	start_game()