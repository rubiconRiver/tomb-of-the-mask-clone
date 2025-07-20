extends Control
class_name AudioStudioLauncher

# Simple launcher to test the AudioStudio in isolation

var audio_studio: AudioStudio

func _ready():
	# Set up the window for the AudioStudio
	var window = get_window()
	if window:
		window.size = Vector2i(1600, 1000)
		window.title = "Audio Studio - Sound Design Tool"
		
		# Center the window
		var screen_size = DisplayServer.screen_get_size()
		var window_pos = (screen_size - Vector2i(1600, 1000)) / 2
		window.position = window_pos
	
	# Create the AudioStudio directly
	audio_studio = preload("res://scripts/tools/AudioStudio.gd").new()
	add_child(audio_studio)
	
	print("[AudioStudioLauncher] AudioStudio launched successfully!")
	print("Use the AudioStudio interface to shape sounds.")
	print("Press ESC or close window to quit.")

func _input(event):
	# Allow ESC to quit
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		get_tree().quit()