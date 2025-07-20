extends Node2D

const GRID_SIZE = 64

func _draw():
	# Draw grid lines - light lines for each cell, thick lines every 10
	var grid_area = Rect2(-1000, -1000, 200 * GRID_SIZE, 200 * GRID_SIZE)  # Large area for grid
	
	# Draw vertical lines
	for x in range(-50, 150):
		var line_x = x * GRID_SIZE
		var color = Color(0.3, 0.3, 0.3, 0.3)  # Light gray
		var thickness = 1.0
		
		if x % 10 == 0:
			# Thicker line every 10 cells
			color = Color(0.5, 0.5, 0.5, 0.5)
			thickness = 2.0
		
		draw_line(Vector2(line_x, grid_area.position.y), Vector2(line_x, grid_area.position.y + grid_area.size.y), color, thickness)
	
	# Draw horizontal lines
	for y in range(-50, 150):
		var line_y = y * GRID_SIZE
		var color = Color(0.3, 0.3, 0.3, 0.3)  # Light gray
		var thickness = 1.0
		
		if y % 10 == 0:
			# Thicker line every 10 cells
			color = Color(0.5, 0.5, 0.5, 0.5)
			thickness = 2.0
		
		draw_line(Vector2(grid_area.position.x, line_y), Vector2(grid_area.position.x + grid_area.size.x, line_y), color, thickness)