extends Node

# Singleton to store custom level data from the level editor
var custom_level_data = null
var use_custom_level = false
var launched_from_editor = false

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