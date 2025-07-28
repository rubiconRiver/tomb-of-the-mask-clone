extends Control

@onready var title_label = $AnimationContainer/TitleLabel
@onready var panel = $AnimationContainer/ResultsPanel
@onready var speed_container = $AnimationContainer/ResultsPanel/ContentContainer/StatsContainer/SpeedContainer
@onready var coins_container = $AnimationContainer/ResultsPanel/ContentContainer/StatsContainer/CoinsContainer
@onready var style_container = $AnimationContainer/ResultsPanel/ContentContainer/StatsContainer/StyleContainer

@onready var speed_value = $AnimationContainer/ResultsPanel/ContentContainer/StatsContainer/SpeedContainer/ValueContainer/TimeValue
@onready var coins_value = $AnimationContainer/ResultsPanel/ContentContainer/StatsContainer/CoinsContainer/ValueContainer/CoinsValue
@onready var style_value = $AnimationContainer/ResultsPanel/ContentContainer/StatsContainer/StyleContainer/ValueContainer/StyleValue

@onready var speed_stars = $AnimationContainer/ResultsPanel/ContentContainer/StatsContainer/SpeedContainer/StarRating
@onready var coins_stars = $AnimationContainer/ResultsPanel/ContentContainer/StatsContainer/CoinsContainer/StarRating
@onready var style_stars = $AnimationContainer/ResultsPanel/ContentContainer/StatsContainer/StyleContainer/StarRating

@onready var perfect_count = $AnimationContainer/ResultsPanel/ContentContainer/StatsContainer/StyleContainer/TimingBreakdown/PerfectContainer/PerfectCount
@onready var great_count = $AnimationContainer/ResultsPanel/ContentContainer/StatsContainer/StyleContainer/TimingBreakdown/GreatContainer/GreatCount
@onready var good_count = $AnimationContainer/ResultsPanel/ContentContainer/StatsContainer/StyleContainer/TimingBreakdown/GoodContainer/GoodCount
@onready var miss_count = $AnimationContainer/ResultsPanel/ContentContainer/StatsContainer/StyleContainer/TimingBreakdown/MissContainer/MissCount

@onready var total_score_container = $AnimationContainer/ResultsPanel/ContentContainer/TotalScoreContainer
@onready var total_score_value = $AnimationContainer/ResultsPanel/ContentContainer/TotalScoreContainer/ScoreValue
@onready var grade_badge = $AnimationContainer/ResultsPanel/ContentContainer/GradeBadge
@onready var grade_label = $AnimationContainer/ResultsPanel/ContentContainer/GradeBadge/GradeLabel

@onready var buttons_container = $AnimationContainer/ResultsPanel/ButtonsContainer
@onready var retry_button = $AnimationContainer/ResultsPanel/ButtonsContainer/RetryButton
@onready var next_button = $AnimationContainer/ResultsPanel/ButtonsContainer/NextButton
@onready var menu_button = $AnimationContainer/ResultsPanel/ButtonsContainer/MenuButton

var game_manager
var level_time: float
var coins_collected: int
var total_coins: int
var style_accuracy: float
var level_num: int

# Animation values
var displayed_time: float = 0.0
var displayed_coins: int = 0
var displayed_style: float = 0.0
var displayed_score: int = 0

const SPEED_THRESHOLDS = {
	1: [30, 20, 15],
	2: [45, 30, 20],
	3: [60, 40, 30]
}

const COIN_PERCENTAGES = [0.33, 0.66, 1.0]
const STYLE_PERCENTAGES = [40, 70, 90]

func _ready():
	# Hide everything initially
	modulate.a = 0.0
	panel.scale = Vector2.ZERO
	title_label.modulate.a = 0.0
	
	# Connect buttons
	retry_button.pressed.connect(_on_retry_pressed)
	next_button.pressed.connect(_on_next_pressed)
	menu_button.pressed.connect(_on_menu_pressed)

func show_results(time: float, coins: int, total: int, accuracy: float, level: int, timing_counts: Dictionary):
	level_time = time
	coins_collected = coins
	total_coins = total
	style_accuracy = accuracy
	level_num = level
	
	# Set timing breakdown counts
	if perfect_count:
		perfect_count.text = str(timing_counts.get("perfect", 0))
	if great_count:
		great_count.text = str(timing_counts.get("great", 0))
	if good_count:
		good_count.text = str(timing_counts.get("good", 0))
	if miss_count:
		miss_count.text = str(timing_counts.get("miss", 0))
	
	# Calculate ratings
	var speed_rating = calculate_speed_rating(time, level)
	var coins_rating = calculate_coins_rating(coins, total)
	var style_rating = calculate_style_rating(accuracy)
	
	# Start the animation sequence
	animate_entrance()

func animate_entrance():
	# Fade in background and panel together
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.2)
	
	# Panel appears immediately
	var panel_tween = create_tween()
	panel_tween.set_ease(Tween.EASE_OUT)
	panel_tween.set_trans(Tween.TRANS_BACK)
	panel_tween.tween_property(panel, "scale", Vector2.ONE, 0.3)
	
	# Title appears quickly
	var title_tween = create_tween()
	title_tween.set_ease(Tween.EASE_OUT)
	title_tween.tween_property(title_label, "modulate:a", 1.0, 0.2)
	title_tween.parallel().tween_property(title_label, "scale", Vector2(1.1, 1.1), 0.15)
	title_tween.tween_property(title_label, "scale", Vector2.ONE, 0.1)
	
	# Show all stat containers immediately (no slide animation)
	var containers = [speed_container, coins_container, style_container]
	for container in containers:
		container.modulate.a = 1.0
	
	# Go straight to values
	await get_tree().create_timer(0.3).timeout
	animate_values()

func animate_values():
	# All values count up simultaneously and quickly
	var time_tween = create_tween()
	time_tween.tween_method(update_time_display, 0.0, level_time, 0.4)
	
	var coins_tween = create_tween()
	coins_tween.tween_method(update_coins_display, 0, coins_collected, 0.4)
	
	var style_tween = create_tween()
	style_tween.tween_method(update_style_display, 0.0, style_accuracy, 0.4)
	
	# Wait briefly for counters to finish
	await get_tree().create_timer(0.5).timeout
	
	# Animate stars immediately
	animate_star_ratings()

func update_time_display(value: float):
	displayed_time = value
	var minutes = int(value) / 60
	var seconds = int(value) % 60
	speed_value.text = "%d:%02d" % [minutes, seconds]

func update_coins_display(value: int):
	displayed_coins = value
	coins_value.text = "%d/%d" % [value, total_coins]

func update_style_display(value: float):
	displayed_style = value
	style_value.text = "%d%%" % int(value)

func animate_star_ratings():
	# Calculate ratings
	var speed_rating = calculate_speed_rating(level_time, level_num)
	var coins_rating = calculate_coins_rating(coins_collected, total_coins)
	var style_rating = calculate_style_rating(style_accuracy)
	
	# Animate all star ratings at once
	speed_stars.set_rating(speed_rating, true)
	coins_stars.set_rating(coins_rating, true) 
	style_stars.set_rating(style_rating, true)
	
	# Wait for stars to finish
	await style_stars.animation_finished
	
	# Show total score and grade quickly
	animate_final_score(speed_rating, coins_rating, style_rating)

func animate_final_score(speed_rating: int, coins_rating: int, style_rating: int):
	# Calculate total score
	var base_score = 1000
	var speed_bonus = speed_rating * 300
	var coins_bonus = coins_rating * 300
	var style_bonus = style_rating * 400
	var total_score = base_score + speed_bonus + coins_bonus + style_bonus
	
	# Animate score container appearing
	total_score_container.modulate.a = 0.0
	total_score_container.scale = Vector2(0.9, 0.9)
	
	var score_tween = create_tween()
	score_tween.set_ease(Tween.EASE_OUT)
	score_tween.set_trans(Tween.TRANS_BACK)
	score_tween.tween_property(total_score_container, "modulate:a", 1.0, 0.2)
	score_tween.parallel().tween_property(total_score_container, "scale", Vector2.ONE, 0.2)
	
	# Count up score quickly
	await get_tree().create_timer(0.1).timeout
	var count_tween = create_tween()
	count_tween.tween_method(update_score_display, 0, total_score, 0.5)
	
	# Show grade badge quickly
	await get_tree().create_timer(0.3).timeout
	animate_grade_badge(speed_rating, coins_rating, style_rating)

func update_score_display(value: int):
	displayed_score = value
	total_score_value.text = str(value)

func animate_grade_badge(speed: int, coins: int, style: int):
	var letter_grade = calculate_letter_grade(speed, coins, style)
	grade_label.text = letter_grade
	
	# Set grade color
	var grade_colors = {
		"S": Color(1.0, 0.84, 0.0),  # Gold
		"A": Color(0.0, 1.0, 0.0),   # Green
		"B": Color(0.0, 0.7, 1.0),   # Blue
		"C": Color(1.0, 0.5, 0.0),   # Orange
		"D": Color(1.0, 0.0, 0.0)    # Red
	}
	
	grade_badge.modulate = grade_colors.get(letter_grade, Color.WHITE)
	grade_badge.modulate.a = 0.0
	grade_badge.scale = Vector2(2.0, 2.0)
	
	var grade_tween = create_tween()
	grade_tween.set_ease(Tween.EASE_OUT)
	grade_tween.set_trans(Tween.TRANS_BACK)
	grade_tween.tween_property(grade_badge, "scale", Vector2.ONE, 0.3)
	grade_tween.parallel().tween_property(grade_badge, "modulate:a", 1.0, 0.2)
	grade_tween.parallel().tween_property(grade_badge, "rotation", deg_to_rad(360), 0.3)
	
	# Show buttons quickly
	await get_tree().create_timer(0.2).timeout
	animate_buttons()

func animate_buttons():
	# Check if next level exists and disable button if not
	check_next_level_availability()
	
	buttons_container.modulate.a = 0.0
	buttons_container.position.y += 50
	
	var buttons_tween = create_tween()
	buttons_tween.set_ease(Tween.EASE_OUT)
	buttons_tween.set_trans(Tween.TRANS_CUBIC)
	buttons_tween.tween_property(buttons_container, "position:y", buttons_container.position.y - 50, 0.3)
	buttons_tween.parallel().tween_property(buttons_container, "modulate:a", 1.0, 0.3)

func check_next_level_availability():
	# Check if the next level file exists
	var next_level_num = level_num + 1
	var next_level_path = "res://levels/%03d.json" % next_level_num
	
	print("[ResultsScreen] Checking next level: ", next_level_path)
	
	if not FileAccess.file_exists(next_level_path):
		print("[ResultsScreen] Next level does not exist - disabling Next button")
		next_button.disabled = true
		next_button.modulate = Color(0.5, 0.5, 0.5, 0.7)  # Grey out the button
		next_button.text = "No More Levels"
	else:
		print("[ResultsScreen] Next level exists - enabling Next button")
		next_button.disabled = false
		next_button.modulate = Color.WHITE
		next_button.text = "Next Level"

func calculate_speed_rating(time: float, level: int) -> int:
	var thresholds = SPEED_THRESHOLDS.get(level, [60, 40, 30])
	if time <= thresholds[2]:
		return 3
	elif time <= thresholds[1]:
		return 2
	elif time <= thresholds[0]:
		return 1
	else:
		return 0

func calculate_coins_rating(collected: int, total: int) -> int:
	if total == 0:
		return 0
	var percentage = float(collected) / float(total)
	for i in range(2, -1, -1):
		if percentage >= COIN_PERCENTAGES[i]:
			return i + 1
	return 0

func calculate_style_rating(accuracy: float) -> int:
	for i in range(2, -1, -1):
		if accuracy >= STYLE_PERCENTAGES[i]:
			return i + 1
	return 0

func calculate_letter_grade(speed: int, coins: int, style: int) -> String:
	var total_stars = speed + coins + style
	var average = float(total_stars) / 3.0
	
	if average >= 2.7:
		return "S"
	elif average >= 2.3:
		return "A"
	elif average >= 1.7:
		return "B"
	elif average >= 1.0:
		return "C"
	else:
		return "D"

func _on_retry_pressed():
	if game_manager:
		game_manager.restart_level()
	queue_free()

func _on_next_pressed():
	if game_manager:
		game_manager.next_level()
	queue_free()

func _on_menu_pressed():
	if game_manager:
		game_manager.return_to_menu()
	queue_free()