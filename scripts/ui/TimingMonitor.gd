extends Control
class_name TimingMonitor

# Visual timing monitor that displays audio sync health

var health_label: Label
var fps_label: Label
var drift_label: Label
var warning_label: Label

var update_timer = 0.0
var update_interval = 0.25  # Update 4 times per second

func _ready():
	custom_minimum_size = Vector2(300, 120)
	
	# Create background
	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.7)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	
	# Create container
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 2)
	add_child(vbox)
	
	# Title
	var title = Label.new()
	title.text = "Audio Timing Monitor"
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color(1, 1, 1))
	vbox.add_child(title)
	
	# FPS
	fps_label = Label.new()
	fps_label.add_theme_font_size_override("font_size", 12)
	vbox.add_child(fps_label)
	
	# Drift
	drift_label = Label.new()
	drift_label.add_theme_font_size_override("font_size", 12)
	vbox.add_child(drift_label)
	
	# Health
	health_label = Label.new()
	health_label.add_theme_font_size_override("font_size", 12)
	vbox.add_child(health_label)
	
	# Warnings
	warning_label = Label.new()
	warning_label.add_theme_font_size_override("font_size", 12)
	warning_label.add_theme_color_override("font_color", Color(1, 0.5, 0))
	vbox.add_child(warning_label)

func _process(delta):
	update_timer += delta
	if update_timer >= update_interval:
		update_timer = 0.0
		update_display()

func update_display():
	if not AudioManager:
		return
		
	var health = AudioManager.get_timing_health()
	if health.is_empty():
		return
	
	# Update FPS
	fps_label.text = "FPS: %.1f" % health.average_fps
	if health.average_fps < 30:
		fps_label.add_theme_color_override("font_color", Color(1, 0, 0))
	elif health.average_fps < 50:
		fps_label.add_theme_color_override("font_color", Color(1, 1, 0))
	else:
		fps_label.add_theme_color_override("font_color", Color(0, 1, 0))
	
	# Update drift
	drift_label.text = "Drift: %.1fms (%.2fms/beat)" % [health.total_drift_ms, health.drift_per_beat_ms]
	if abs(health.drift_per_beat_ms) > 5.0:
		drift_label.add_theme_color_override("font_color", Color(1, 0, 0))
	elif abs(health.drift_per_beat_ms) > 2.0:
		drift_label.add_theme_color_override("font_color", Color(1, 1, 0))
	else:
		drift_label.add_theme_color_override("font_color", Color(0, 1, 0))
	
	# Update health
	var is_healthy = AudioManager.is_timing_healthy()
	health_label.text = "Sync: %s" % ("HEALTHY" if is_healthy else "UNHEALTHY")
	health_label.add_theme_color_override("font_color", Color(0, 1, 0) if is_healthy else Color(1, 0, 0))
	
	# Update warnings
	var warnings = []
	if health.dropped_frames > 0:
		warnings.append("Drops: %d" % health.dropped_frames)
	if health.drift_warnings > 0:
		warnings.append("Warn: %d" % health.drift_warnings)
	if health.drift_criticals > 0:
		warnings.append("Crit: %d" % health.drift_criticals)
	
	warning_label.text = " | ".join(warnings) if warnings.size() > 0 else ""