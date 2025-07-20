class_name TextureGenerator
extends RefCounted

static func create_smooth_gradient_texture(size: Vector2i, center_color: Color, edge_color: Color) -> ImageTexture:
	var image = Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	
	var center = Vector2(size.x / 2.0, size.y / 2.0)
	var max_dist = center.length()
	
	for y in range(size.y):
		for x in range(size.x):
			var pos = Vector2(x, y)
			var dist = pos.distance_to(center) / max_dist
			dist = smoothstep(0.0, 1.0, dist)
			
			var color = center_color.lerp(edge_color, dist)
			image.set_pixel(x, y, color)
	
	return ImageTexture.create_from_image(image)

static func create_rounded_rect_texture(size: Vector2i, color: Color, corner_radius: int) -> ImageTexture:
	var image = Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	
	for y in range(size.y):
		for x in range(size.x):
			var pixel_color = Color.TRANSPARENT
			
			# Check if pixel is inside rounded rectangle
			var in_rect = false
			
			# Main rectangle area
			if x >= corner_radius and x < size.x - corner_radius:
				if y >= 0 and y < size.y:
					in_rect = true
			elif y >= corner_radius and y < size.y - corner_radius:
				if x >= 0 and x < size.x:
					in_rect = true
			
			# Check corners
			if not in_rect:
				# Top-left corner
				if x < corner_radius and y < corner_radius:
					var dx = x - corner_radius
					var dy = y - corner_radius
					if dx * dx + dy * dy <= corner_radius * corner_radius:
						in_rect = true
				# Top-right corner
				elif x >= size.x - corner_radius and y < corner_radius:
					var dx = x - (size.x - corner_radius - 1)
					var dy = y - corner_radius
					if dx * dx + dy * dy <= corner_radius * corner_radius:
						in_rect = true
				# Bottom-left corner
				elif x < corner_radius and y >= size.y - corner_radius:
					var dx = x - corner_radius
					var dy = y - (size.y - corner_radius - 1)
					if dx * dx + dy * dy <= corner_radius * corner_radius:
						in_rect = true
				# Bottom-right corner
				elif x >= size.x - corner_radius and y >= size.y - corner_radius:
					var dx = x - (size.x - corner_radius - 1)
					var dy = y - (size.y - corner_radius - 1)
					if dx * dx + dy * dy <= corner_radius * corner_radius:
						in_rect = true
			
			if in_rect:
				# Add soft edge
				var edge_dist = min(
					min(x, size.x - 1 - x),
					min(y, size.y - 1 - y)
				)
				var alpha = smoothstep(0, 3, edge_dist)
				pixel_color = Color(color.r, color.g, color.b, color.a * alpha)
			
			image.set_pixel(x, y, pixel_color)
	
	# Apply gaussian blur for smoother edges
	# Simple box blur approximation
	var blurred = Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	for y in range(1, size.y - 1):
		for x in range(1, size.x - 1):
			var sum_color = Color.TRANSPARENT
			var count = 0
			for dy in range(-1, 2):
				for dx in range(-1, 2):
					sum_color += image.get_pixel(x + dx, y + dy)
					count += 1
			blurred.set_pixel(x, y, sum_color / count)
	
	return ImageTexture.create_from_image(blurred)