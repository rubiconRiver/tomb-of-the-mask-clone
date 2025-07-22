extends Node
class_name HapticFeedback

# ============================================
# MOBILE HAPTIC FEEDBACK SYSTEM
# ============================================

enum HapticType {
	LIGHT,      # Subtle feedback for UI interactions
	MEDIUM,     # Standard feedback for button presses
	HEAVY,      # Strong feedback for impacts/collisions
	SUCCESS,    # Positive feedback for achievements
	WARNING,    # Attention feedback for errors
	SELECTION   # Feedback for item selection
}

# Settings
var haptic_enabled = true
var intensity_multiplier = 1.0

func _ready():
	# Load haptic settings from GameData if available
	if GameData and GameData.get_setting("vibration") != null:
		haptic_enabled = GameData.get_setting("vibration")

# Main haptic feedback function
func trigger_haptic(type: HapticType):
	if not haptic_enabled:
		return
	
	# Check if running on mobile device
	if not (OS.has_feature("mobile") or OS.has_feature("android") or OS.has_feature("ios")):
		print("[HapticFeedback] Desktop - simulating haptic: ", HapticType.keys()[type])
		return
	
	# Get vibration parameters based on type
	var duration_ms = get_vibration_duration(type)
	var intensity = get_vibration_intensity(type) * intensity_multiplier
	
	# Trigger platform-specific haptic feedback
	if OS.has_feature("android"):
		trigger_android_haptic(duration_ms, intensity)
	elif OS.has_feature("ios"):
		trigger_ios_haptic(type, intensity)
	else:
		# Generic fallback
		trigger_generic_vibration(duration_ms)

func get_vibration_duration(type: HapticType) -> int:
	match type:
		HapticType.LIGHT:
			return 10
		HapticType.MEDIUM:
			return 20
		HapticType.HEAVY:
			return 40
		HapticType.SUCCESS:
			return 25
		HapticType.WARNING:
			return 30
		HapticType.SELECTION:
			return 15
		_:
			return 20

func get_vibration_intensity(type: HapticType) -> float:
	match type:
		HapticType.LIGHT:
			return 0.3
		HapticType.MEDIUM:
			return 0.6
		HapticType.HEAVY:
			return 1.0
		HapticType.SUCCESS:
			return 0.7
		HapticType.WARNING:
			return 0.8
		HapticType.SELECTION:
			return 0.4
		_:
			return 0.6

func trigger_android_haptic(duration_ms: int, intensity: float):
	# Android vibration - use Input.vibrate_handheld()
	Input.vibrate_handheld(duration_ms)

func trigger_ios_haptic(type: HapticType, intensity: float):
	# iOS has more sophisticated haptic feedback
	# For now, use generic vibration but could be extended with plugins
	var duration_ms = get_vibration_duration(type)
	Input.vibrate_handheld(duration_ms)

func trigger_generic_vibration(duration_ms: int):
	# Generic vibration fallback
	Input.vibrate_handheld(duration_ms)

# Convenience functions for common game events
func on_button_press():
	trigger_haptic(HapticType.MEDIUM)

func on_swipe():
	trigger_haptic(HapticType.LIGHT)

func on_wall_hit():
	trigger_haptic(HapticType.HEAVY)

func on_coin_collect():
	trigger_haptic(HapticType.SUCCESS)

func on_level_complete():
	trigger_haptic(HapticType.SUCCESS)
	# Add a second pulse for extra satisfaction
	await get_tree().create_timer(0.1).timeout
	trigger_haptic(HapticType.MEDIUM)

func on_game_over():
	trigger_haptic(HapticType.WARNING)

func on_menu_navigation():
	trigger_haptic(HapticType.SELECTION)

func on_error():
	trigger_haptic(HapticType.WARNING)

# Settings management
func set_haptic_enabled(enabled: bool):
	haptic_enabled = enabled
	if GameData:
		GameData.set_setting("vibration", enabled)

func set_intensity(intensity: float):
	intensity_multiplier = clamp(intensity, 0.0, 2.0)

func get_haptic_enabled() -> bool:
	return haptic_enabled

# Pattern vibrations for special events
func trigger_success_pattern():
	trigger_haptic(HapticType.LIGHT)
	await get_tree().create_timer(0.05).timeout
	trigger_haptic(HapticType.MEDIUM)
	await get_tree().create_timer(0.05).timeout
	trigger_haptic(HapticType.SUCCESS)

func trigger_combo_pattern(combo_level: int):
	# Increasingly intense feedback for higher combos
	var base_type = HapticType.LIGHT
	if combo_level >= 4:
		base_type = HapticType.MEDIUM
	if combo_level >= 8:
		base_type = HapticType.HEAVY
	
	trigger_haptic(base_type)