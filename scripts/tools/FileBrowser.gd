extends Panel
class_name FileBrowser

signal file_selected(path: String)
signal closed()

@onready var item_list = $ScrollContainer/ItemList
@onready var close_button = $TitleBar/CloseButton

var level_files = []

func _ready():
	close_button.pressed.connect(_on_close_pressed)
	item_list.item_selected.connect(_on_item_selected)
	
	# Load level list
	refresh_file_list()

func refresh_file_list():
	item_list.clear()
	level_files.clear()
	
	# Scan for JSON files in levels directory
	var dir = DirAccess.open("res://levels/")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".json") and not file_name.begins_with("."):
				level_files.append("levels/" + file_name)
				item_list.add_item(file_name)
			file_name = dir.get_next()
		dir.list_dir_end()
	
	# Also scan custom directory
	var custom_dir = DirAccess.open("res://levels/custom/")
	if custom_dir:
		custom_dir.list_dir_begin()
		var file_name = custom_dir.get_next()
		while file_name != "":
			if file_name.ends_with(".json") and not file_name.begins_with("."):
				level_files.append("levels/custom/" + file_name)
				item_list.add_item("custom/" + file_name)
			file_name = custom_dir.get_next()
		custom_dir.list_dir_end()
	
	print("Found ", level_files.size(), " levels")

func _on_item_selected(index: int):
	if index >= 0 and index < level_files.size():
		var path = "res://" + level_files[index]
		print("Selected: ", path)
		file_selected.emit(path)
		queue_free()

func _on_close_pressed():
	closed.emit()
	queue_free()

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		_on_close_pressed()
		get_viewport().set_input_as_handled()