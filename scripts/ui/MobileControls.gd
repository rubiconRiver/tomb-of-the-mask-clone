extends CanvasLayer
class_name MobileControls

# ============================================
# MOBILE-FRIENDLY GAME CONTROLS
# ============================================

@onready var control_panel = $ControlPanel
@onready var settings_toggle = $SettingsToggle
@onready var swipe_hint = $SwipeHint

# Beat speed controls
@onready var slower_button = $ControlPanel/VBoxContainer/BeatSpeedContainer/BeatSpeedButtons/SlowerButton
@onready var faster_button = $ControlPanel/VBoxContainer/BeatSpeedContainer/BeatSpeedButtons/FasterButton
@onready var beat_speed_value = $ControlPanel/VBoxContainer/BeatSpeedContainer/BeatSpeedValue

# Latency controls  
@onready var earlier_button = $ControlPanel/VBoxContainer/LatencyContainer/LatencyButtons/EarlierButton
@onready var later_button = $ControlPanel/VBoxContainer/LatencyContainer/LatencyButtons/LaterButton
@onready var latency_value = $ControlPanel/VBoxContainer/LatencyContainer/LatencyValue

# Menu controls
@onready var menu_button = $ControlPanel/VBoxContainer/MenuButton
@onready var close_button = $ControlPanel/VBoxContainer/CloseButton

var game_manager: GameManager
var is_panel_open = false

func _ready():
	setup_mobile_controls()
	connect_signals()
	update_displays()
	
	# Hide swipe hint after a few seconds
	await get_tree().create_timer(3.0).timeout
	if swipe_hint:
		var tween = create_tween()
		tween.tween_property(swipe_hint, "modulate", Color.TRANSPARENT, 1.0)

func setup_mobile_controls():
	# Find the GameManager
	game_manager = get_tree().get_first_node_in_group("game_manager")
	
	# Style the control panel with synthwave aesthetics
	if control_panel:
		var style_box = StyleBoxFlat.new()
		style_box.bg_color = Color(0.05, 0.05, 0.1, 0.95)
		style_box.border_width_left = 2
		style_box.border_width_top = 2
		style_box.border_width_right = 2
		style_box.border_width_bottom = 2
		style_box.border_color = Color("#94fbe6")
		style_box.corner_radius_top_left = 8
		style_box.corner_radius_top_right = 8
		style_box.corner_radius_bottom_left = 8
		style_box.corner_radius_bottom_right = 8
		control_panel.add_theme_stylebox_override("panel", style_box)

func connect_signals():
	# Settings toggle
	if settings_toggle:
		settings_toggle.pressed.connect(_on_settings_toggle_pressed)
	
	# Beat speed controls
	if slower_button:
		slower_button.pressed.connect(_on_slower_pressed)
	if faster_button:
		faster_button.pressed.connect(_on_faster_pressed)
	
	# Latency controls
	if earlier_button:
		earlier_button.pressed.connect(_on_earlier_pressed)
	if later_button:
		later_button.pressed.connect(_on_later_pressed)
	
	# Menu controls
	if menu_button:
		menu_button.pressed.connect(_on_menu_pressed)
	if close_button:
		close_button.pressed.connect(_on_close_pressed)

func _on_settings_toggle_pressed():
	toggle_control_panel()

func toggle_control_panel():
	is_panel_open = !is_panel_open
	
	if control_panel:
		var tween = create_tween()
		if is_panel_open:
			control_panel.visible = true
			tween.tween_property(control_panel, "modulate", Color.WHITE, 0.2)
		else:
			tween.tween_property(control_panel, "modulate", Color.TRANSPARENT, 0.2)
			tween.tween_callback(func(): control_panel.visible = false)

# Beat speed controls
func _on_slower_pressed():
	if game_manager:
		AudioManager.beat_interval = min(2.0, AudioManager.beat_interval + 0.05)
		update_displays()
		print("[MobileControls] Beat interval: ", AudioManager.beat_interval)

func _on_faster_pressed():
	if game_manager:
		AudioManager.beat_interval = max(0.2, AudioManager.beat_interval - 0.05)
		update_displays()
		print("[MobileControls] Beat interval: ", AudioManager.beat_interval)

# Latency controls  
func _on_earlier_pressed():
	if game_manager:
		game_manager.audio_latency_offset = max(-0.2, game_manager.audio_latency_offset - 0.01)
		game_manager.update_latency_display()
		update_displays()
		print("[MobileControls] Audio latency offset: ", game_manager.audio_latency_offset * 1000, "ms")

func _on_later_pressed():
	if game_manager:
		game_manager.audio_latency_offset = min(0.2, game_manager.audio_latency_offset + 0.01)
		game_manager.update_latency_display()
		update_displays()
		print("[MobileControls] Audio latency offset: ", game_manager.audio_latency_offset * 1000, "ms")

# Menu controls
func _on_menu_pressed():
	print("[MobileControls] Returning to main menu")
	if game_manager:
		game_manager.return_to_menu()

func _on_close_pressed():
	toggle_control_panel()

func update_displays():
	# Update beat speed display
	if beat_speed_value:
		beat_speed_value.text = "%.2fs" % AudioManager.beat_interval
	
	# Update latency display
	if latency_value and game_manager:
		latency_value.text = "%dms" % int(game_manager.audio_latency_offset * 1000)

# Touch gesture detection for swipe hints
func _input(event):
	if event is InputEventScreenTouch or event is InputEventMouseButton:
		if event.pressed:
			# Hide swipe hint on first touch
			if swipe_hint and swipe_hint.modulate.a > 0:
				var tween = create_tween()
				tween.tween_property(swipe_hint, "modulate", Color.TRANSPARENT, 0.5)