extends Node

# ============================================
# GAME DATA SINGLETON
# ============================================
# Manages player progression, scores, and game state

signal level_completed(level_number: int, score: int, stars: int)
signal player_data_updated

# Player progression data
var player_data = {
	"player_level": 1,
	"total_score": 0,
	"total_coins": 0,
	"total_stars": 0,
	"unlocked_levels": 1,
	"level_scores": {},  # level_number: best_score
	"level_stars": {},   # level_number: star_count
	"level_times": {},   # level_number: best_time
	"achievements": [],
	"settings": {
		"sfx_volume": 1.0,
		"music_volume": 1.0,
		"vibration": true
	}
}

# Game session data
var current_level = 1
var session_score = 0
var session_coins = 0
var returning_from_game = false

# Save file path
var save_path = "user://player_data.save"

func _ready():
	load_player_data()

# ============================================
# SAVE/LOAD SYSTEM
# ============================================

func save_player_data():
	var save_file = FileAccess.open(save_path, FileAccess.WRITE)
	if save_file:
		save_file.store_string(JSON.stringify(player_data))
		save_file.close()
		print("[GameData] Player data saved")
	else:
		print("[GameData] Error saving player data")

func load_player_data():
	if FileAccess.file_exists(save_path):
		var save_file = FileAccess.open(save_path, FileAccess.READ)
		if save_file:
			var json_string = save_file.get_as_text()
			save_file.close()
			
			var json = JSON.new()
			var parse_result = json.parse(json_string)
			
			if parse_result == OK:
				var loaded_data = json.data
				# Merge loaded data with defaults
				for key in loaded_data:
					player_data[key] = loaded_data[key]
				print("[GameData] Player data loaded")
			else:
				print("[GameData] Error parsing save file")
		else:
			print("[GameData] Error opening save file")
	else:
		print("[GameData] No save file found, using defaults")
		save_player_data()  # Create initial save file

# ============================================
# LEVEL MANAGEMENT
# ============================================

func start_level(level_number: int):
	current_level = level_number
	session_score = 0
	session_coins = 0
	returning_from_game = false
	print("[GameData] Starting level ", level_number)

func complete_level(level_number: int, score: int, coins: int, time: float):
	print("[GameData] Level ", level_number, " completed - Score: ", score, " Coins: ", coins, " Time: ", time)
	
	# Calculate star rating (1-3 stars based on performance)
	var stars = calculate_star_rating(level_number, score, coins, time)
	
	# Update level data
	var is_new_best_score = false
	if level_number not in player_data.level_scores or score > player_data.level_scores[level_number]:
		player_data.level_scores[level_number] = score
		is_new_best_score = true
	
	if level_number not in player_data.level_stars or stars > player_data.level_stars[level_number]:
		player_data.level_stars[level_number] = stars
	
	if level_number not in player_data.level_times or time < player_data.level_times[level_number]:
		player_data.level_times[level_number] = time
	
	# Update totals (only if new best score)
	if is_new_best_score:
		player_data.total_score += score
		player_data.total_coins += coins
		player_data.total_stars = calculate_total_stars()
	
	# Unlock next level
	if level_number >= player_data.unlocked_levels:
		var max_levels = 20  # TODO: Get from level data
		player_data.unlocked_levels = min(level_number + 1, max_levels)
		print("[GameData] Level ", player_data.unlocked_levels, " unlocked!")
	
	# Update player level based on total stars
	update_player_level()
	
	# Save and emit signals
	save_player_data()
	level_completed.emit(level_number, score, stars)
	player_data_updated.emit()
	
	returning_from_game = true

func calculate_star_rating(level_number: int, score: int, coins: int, time: float) -> int:
	# Simple star calculation - can be made more sophisticated
	var stars = 1  # Base star for completion
	
	# Add star for good score (relative to level)
	var score_threshold = level_number * 50  # Adjust as needed
	if score >= score_threshold:
		stars += 1
	
	# Add star for collecting coins or fast completion
	if coins >= 5 or time < 30.0:  # Adjust thresholds as needed
		stars += 1
	
	return min(stars, 3)

func calculate_total_stars() -> int:
	var total = 0
	for level in player_data.level_stars:
		total += player_data.level_stars[level]
	return total

func update_player_level():
	# Player level based on total stars (every 10 stars = 1 level)
	var new_level = 1 + (player_data.total_stars / 10)
	if new_level > player_data.player_level:
		player_data.player_level = new_level
		print("[GameData] Player leveled up to level ", new_level, "!")

# ============================================
# GETTERS
# ============================================

func get_player_level() -> int:
	return player_data.player_level

func get_total_score() -> int:
	return player_data.total_score

func get_total_coins() -> int:
	return player_data.total_coins

func get_total_stars() -> int:
	return player_data.total_stars

func get_unlocked_levels() -> int:
	return player_data.unlocked_levels

func get_level_score(level_number: int) -> int:
	return player_data.level_scores.get(level_number, 0)

func get_level_stars(level_number: int) -> int:
	return player_data.level_stars.get(level_number, 0)

func get_level_time(level_number: int) -> float:
	return player_data.level_times.get(level_number, 0.0)

func is_level_unlocked(level_number: int) -> bool:
	return level_number <= player_data.unlocked_levels

func is_level_completed(level_number: int) -> bool:
	return level_number in player_data.level_scores

func is_returning_from_game() -> bool:
	return returning_from_game

# ============================================
# SETTINGS
# ============================================

func set_setting(key: String, value):
	if key in player_data.settings:
		player_data.settings[key] = value
		save_player_data()

func get_setting(key: String):
	return player_data.settings.get(key, null)

# ============================================
# DEBUG/TESTING
# ============================================

func reset_all_data():
	player_data = {
		"player_level": 1,
		"total_score": 0,
		"total_coins": 0,
		"total_stars": 0,
		"unlocked_levels": 1,
		"level_scores": {},
		"level_stars": {},
		"level_times": {},
		"achievements": [],
		"settings": {
			"sfx_volume": 1.0,
			"music_volume": 1.0,
			"vibration": true
		}
	}
	save_player_data()
	player_data_updated.emit()
	print("[GameData] All player data reset")

func unlock_all_levels():
	player_data.unlocked_levels = 20  # Adjust max levels as needed
	save_player_data()
	player_data_updated.emit()
	print("[GameData] All levels unlocked")