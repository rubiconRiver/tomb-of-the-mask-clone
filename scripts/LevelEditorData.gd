extends Node

# Singleton to store custom level data from the level editor
var custom_level_data = null
var use_custom_level = false
var launched_from_editor = false
var editor_level_backup = null  # Store the tilemap state before testing
var custom_audio_pattern = null  # Store audio pattern from level editor
var level_to_edit = ""  # Store which level file to load in editor

func set_custom_level(level_data: Array):
	custom_level_data = level_data
	use_custom_level = true
	print("Custom level data set with ", level_data.size(), " rows")

func get_custom_level() -> Array:
	return custom_level_data if custom_level_data else []

func clear_custom_level():
	custom_level_data = null
	use_custom_level = false

func should_use_custom_level() -> bool:
	return use_custom_level and custom_level_data != null

func set_launched_from_editor(value: bool):
	launched_from_editor = value

func is_launched_from_editor() -> bool:
	return launched_from_editor

func set_editor_backup(backup_data):
	editor_level_backup = backup_data

func get_editor_backup():
	return editor_level_backup

func clear_editor_backup():
	editor_level_backup = null

# Audio pattern functions
func set_custom_audio_pattern(pattern_data):
	custom_audio_pattern = pattern_data
	if pattern_data:
		print("[LevelEditorData] Custom audio pattern set:")
		print("  BPM: ", pattern_data.bpm)
		print("  Theme: ", pattern_data.theme)
		print("  Level: ", pattern_data.get("level_name", "Unknown"))
	else:
		print("[LevelEditorData] Custom audio pattern cleared")

func get_custom_audio_pattern():
	return custom_audio_pattern

func has_custom_audio_pattern() -> bool:
	return custom_audio_pattern != null

func clear_custom_audio_pattern():
	custom_audio_pattern = null

# Level editing functions
func set_level_to_edit(filename: String):
	level_to_edit = filename
	print("[LevelEditorData] Set level to edit: ", filename)

func get_level_to_edit() -> String:
	return level_to_edit

func has_level_to_edit() -> bool:
	return level_to_edit != ""

func clear_level_to_edit():
	level_to_edit = ""