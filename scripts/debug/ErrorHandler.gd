extends Node

# Global error handler to display crashes on screen
class_name ErrorHandler

static var error_label: Label = null
static var error_panel: Panel = null

static func _static_init():
	# Connect to unhandled exception signal
	if OS.has_feature("debug"):
		print("[ErrorHandler] Debug build detected - error display enabled")

static func setup_error_display(scene_root: Node):
	# Create error display UI
	error_panel = Panel.new()
	error_panel.name = "ErrorPanel"
	error_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	error_panel.visible = false
	error_panel.modulate = Color(1, 1, 1, 0.95)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.8, 0, 0, 0.9)
	style.border_width_left = 4
	style.border_width_right = 4
	style.border_width_top = 4
	style.border_width_bottom = 4
	style.border_color = Color(1, 0, 0)
	error_panel.add_theme_stylebox_override("panel", style)
	
	error_label = Label.new()
	error_label.name = "ErrorLabel"
	error_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	error_label.add_theme_color_override("font_color", Color.WHITE)
	error_label.add_theme_font_size_override("font_size", 14)
	error_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	error_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	error_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	
	var margin_container = MarginContainer.new()
	margin_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin_container.add_theme_constant_override("margin_left", 20)
	margin_container.add_theme_constant_override("margin_right", 20)
	margin_container.add_theme_constant_override("margin_top", 20)
	margin_container.add_theme_constant_override("margin_bottom", 20)
	
	margin_container.add_child(error_label)
	error_panel.add_child(margin_container)
	
	# Add to root of scene tree with high z_index
	scene_root.add_child(error_panel)
	error_panel.z_index = 1000
	
	print("[ErrorHandler] Error display UI created")

static func show_error(error_message: String, stack_trace: String = ""):
	print("[ErrorHandler] ERROR: ", error_message)
	if stack_trace:
		print("[ErrorHandler] Stack trace: ", stack_trace)
	
	if error_label and error_panel:
		var display_text = "GAME ERROR:\n\n" + error_message
		if stack_trace:
			display_text += "\n\nStack Trace:\n" + stack_trace
		
		error_label.text = display_text
		error_panel.visible = true
		error_panel.z_index = 1000  # Ensure it's on top
		
		# Also log to Android logcat
		if OS.has_feature("android"):
			OS.alert(error_message, "TechnoBeat Error")

static func safe_call(object: Object, method: String, args: Array = []):
	if not object:
		show_error("Attempted to call " + method + " on null object")
		return null
		
	if not object.has_method(method):
		show_error("Object " + object.get_class() + " does not have method: " + method)
		return null
		
	return object.callv(method, args)