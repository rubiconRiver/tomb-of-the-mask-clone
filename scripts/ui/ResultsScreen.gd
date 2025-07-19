extends Control

@onready var speed_stars = $Panel/VBoxContainer/ScoresContainer/SpeedScore/Stars
@onready var coins_stars = $Panel/VBoxContainer/ScoresContainer/CoinsScore/Stars
@onready var style_stars = $Panel/VBoxContainer/ScoresContainer/StyleScore/Stars

@onready var time_label = $Panel/VBoxContainer/ScoresContainer/SpeedScore/TimeLabel
@onready var count_label = $Panel/VBoxContainer/ScoresContainer/CoinsScore/CountLabel
@onready var accuracy_label = $Panel/VBoxContainer/ScoresContainer/StyleScore/AccuracyLabel

@onready var grade_label = $Panel/VBoxContainer/GradeContainer/GradeLabel
@onready var grade_text = $Panel/VBoxContainer/GradeContainer/GradeText

@onready var retry_button = $Panel/VBoxContainer/ButtonContainer/RetryButton
@onready var next_button = $Panel/VBoxContainer/ButtonContainer/NextButton
@onready var menu_button = $Panel/VBoxContainer/ButtonContainer/MenuButton

var game_manager

const STAR_FILLED = "★"
const STAR_EMPTY = "☆"

const SPEED_THRESHOLDS = {
	1: [30, 20, 15],  # Level 1: 3 stars if under 15s, 2 if under 20s, 1 if under 30s
	2: [45, 30, 20],
	3: [60, 40, 30]
}

const COIN_PERCENTAGES = [0.33, 0.66, 1.0]  # 1 star at 33%, 2 at 66%, 3 at 100%
const STYLE_PERCENTAGES = [40, 70, 90]  # 1 star at 40%, 2 at 70%, 3 at 90%

func _ready():
	retry_button.pressed.connect(_on_retry_pressed)
	next_button.pressed.connect(_on_next_pressed)
	menu_button.pressed.connect(_on_menu_pressed)

func show_results(level_time: float, coins_collected: int, total_coins: int, style_accuracy: float, level_num: int):
	var speed_rating = calculate_speed_rating(level_time, level_num)
	var coins_rating = calculate_coins_rating(coins_collected, total_coins)
	var style_rating = calculate_style_rating(style_accuracy)
	
	display_stars(speed_stars, speed_rating)
	display_stars(coins_stars, coins_rating)
	display_stars(style_stars, style_rating)
	
	time_label.text = format_time(level_time)
	count_label.text = str(coins_collected) + "/" + str(total_coins)
	accuracy_label.text = str(int(style_accuracy)) + "%"
	
	var letter_grade = calculate_letter_grade(speed_rating, coins_rating, style_rating)
	display_grade(letter_grade)
	
	visible = true

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

func display_stars(container: HBoxContainer, rating: int):
	for child in container.get_children():
		child.queue_free()
	
	for i in range(3):
		var star_label = Label.new()
		star_label.text = STAR_FILLED if i < rating else STAR_EMPTY
		star_label.add_theme_font_size_override("font_size", 28)
		star_label.add_theme_color_override("font_color", Color.YELLOW if i < rating else Color.GRAY)
		container.add_child(star_label)

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

func display_grade(grade: String):
	grade_label.text = grade
	
	var grade_colors = {
		"S": Color.GOLD,
		"A": Color.GREEN,
		"B": Color.CYAN,
		"C": Color.ORANGE,
		"D": Color.RED
	}
	
	var grade_texts = {
		"S": "PERFECT!",
		"A": "EXCELLENT!",
		"B": "GOOD JOB!",
		"C": "NOT BAD!",
		"D": "TRY AGAIN!"
	}
	
	grade_label.add_theme_color_override("font_color", grade_colors.get(grade, Color.WHITE))
	grade_text.text = grade_texts.get(grade, "")

func format_time(seconds: float) -> String:
	var minutes = int(seconds) / 60
	var secs = int(seconds) % 60
	return "%d:%02d" % [minutes, secs]

func _on_retry_pressed(): 
	print("Retry pressed")
	if game_manager:
		print("restarting level")
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