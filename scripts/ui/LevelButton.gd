extends Button
class_name LevelButton

# ============================================
# SYNTHWAVE LEVEL BUTTON
# ============================================

@onready var star_container = $StarContainer
@onready var star1 = $StarContainer/Star1
@onready var star2 = $StarContainer/Star2
@onready var star3 = $StarContainer/Star3

var level_number: int = 1
var is_unlocked: bool = false
var is_completed: bool = false
var star_count: int = 0

# Synthwave colors
var cyan_color = Color("#94fbe6")
var magenta_color = Color("#fb94dc") 
var yellow_color = Color("#dcfb94")
var locked_color = Color(0.3, 0.3, 0.3, 0.5)

func _ready():
	setup_button()

func setup_button():
	# Set button text
	text = str(level_number)
	
	# Update visual state
	update_visual_state()
	
	# Connect hover effects
	mouse_entered.connect(_on_hover_enter)
	mouse_exited.connect(_on_hover_exit)

func configure(level_num: int, unlocked: bool, completed: bool, stars: int = 0):
	level_number = level_num
	is_unlocked = unlocked
	is_completed = completed
	star_count = stars
	
	if is_inside_tree():
		setup_button()

func update_visual_state():
	# Create synthwave styling
	var style_normal = StyleBoxFlat.new()
	var style_hover = StyleBoxFlat.new()
	var style_pressed = StyleBoxFlat.new()
	
	# Set corner radius for all styles
	for style in [style_normal, style_hover, style_pressed]:
		style.corner_radius_top_left = 10
		style.corner_radius_top_right = 10
		style.corner_radius_bottom_left = 10
		style.corner_radius_bottom_right = 10
		style.border_width_left = 2
		style.border_width_top = 2
		style.border_width_right = 2
		style.border_width_bottom = 2
	
	if is_completed:
		# Completed level - cyan glow
		style_normal.bg_color = Color(cyan_color.r, cyan_color.g, cyan_color.b, 0.3)
		style_normal.border_color = cyan_color
		style_hover.bg_color = Color(cyan_color.r, cyan_color.g, cyan_color.b, 0.5)
		style_hover.border_color = cyan_color
		style_pressed.bg_color = Color(cyan_color.r, cyan_color.g, cyan_color.b, 0.7)
		style_pressed.border_color = cyan_color
		modulate = Color.WHITE
		disabled = false
	elif is_unlocked:
		# Unlocked but not completed - yellow
		style_normal.bg_color = Color(yellow_color.r, yellow_color.g, yellow_color.b, 0.2)
		style_normal.border_color = yellow_color
		style_hover.bg_color = Color(yellow_color.r, yellow_color.g, yellow_color.b, 0.4)
		style_hover.border_color = yellow_color
		style_pressed.bg_color = Color(yellow_color.r, yellow_color.g, yellow_color.b, 0.6)
		style_pressed.border_color = yellow_color
		modulate = Color.WHITE
		disabled = false
	else:
		# Locked level - dim
		style_normal.bg_color = Color(0.1, 0.1, 0.1, 0.5)
		style_normal.border_color = locked_color
		style_hover.bg_color = Color(0.15, 0.15, 0.15, 0.5)
		style_hover.border_color = locked_color
		style_pressed.bg_color = Color(0.1, 0.1, 0.1, 0.5)
		style_pressed.border_color = locked_color
		modulate = Color(0.5, 0.5, 0.5, 0.7)
		disabled = true
	
	# Apply styles
	add_theme_stylebox_override("normal", style_normal)
	add_theme_stylebox_override("hover", style_hover)
	add_theme_stylebox_override("pressed", style_pressed)
	
	# Update star display
	update_star_display()

func update_star_display():
	if not star_container:
		return
	
	var stars = [star1, star2, star3]
	
	for i in range(3):
		if stars[i]:
			if i < star_count:
				stars[i].text = "★"  # Filled star
				stars[i].modulate = yellow_color
			else:
				stars[i].text = "☆"  # Empty star
				stars[i].modulate = Color(0.4, 0.4, 0.4, 0.6)

func _on_hover_enter():
	if not disabled:
		# Add subtle glow effect
		create_tween().tween_property(self, "scale", Vector2(1.05, 1.05), 0.1)

func _on_hover_exit():
	if not disabled:
		# Return to normal scale
		create_tween().tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)

# Glow animation for special events
func animate_unlock():
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Scale animation
	tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.3)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.3).set_delay(0.3)
	
	# Glow animation
	tween.tween_property(self, "modulate", Color(2.0, 2.0, 2.0, 1.0), 0.3)
	tween.tween_property(self, "modulate", Color.WHITE, 0.3).set_delay(0.3)

func animate_completion():
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Celebration animation
	for i in range(3):
		tween.tween_property(self, "rotation", PI/8, 0.1).set_delay(i * 0.1)
		tween.tween_property(self, "rotation", -PI/8, 0.1).set_delay(i * 0.1 + 0.1)
		tween.tween_property(self, "rotation", 0, 0.1).set_delay(i * 0.1 + 0.2)