shader_type canvas_item;

uniform float grid_size : hint_range(10.0, 100.0) = 64.0;
uniform float line_thickness : hint_range(0.5, 5.0) = 1.0;
uniform vec4 grid_color : source_color = vec4(0.0, 0.5, 0.5, 0.3);
uniform vec4 bg_color : source_color = vec4(0.0, 0.0, 0.1, 1.0);
uniform float pulse_strength : hint_range(0.0, 1.0) = 0.3;
uniform float wave_speed : hint_range(0.0, 5.0) = 1.0;
uniform float wave_amplitude : hint_range(0.0, 20.0) = 5.0;
uniform vec2 camera_position = vec2(0.0, 0.0);
uniform float multiplier : hint_range(1.0, 5.0) = 1.0;
uniform float parallax_factor : hint_range(0.0, 1.0) = 0.2;

void fragment() {
    vec2 uv = FRAGCOORD.xy;
    
    // Convert screen coordinates to world coordinates
    // SCREEN_PIXEL_SIZE gives us the viewport size
    vec2 screen_center = vec2(0.5) / SCREEN_PIXEL_SIZE;
    vec2 world_pos = (uv - screen_center) + camera_position;
    
    // Apply parallax effect (subtle offset for depth)
    world_pos -= camera_position * parallax_factor;
    
    // Adjust grid size based on multiplier (subtle increase)
    float dynamic_grid_size = grid_size + (multiplier - 1.0);
    
    // Create grid dots at tile corners
    // The dots should appear at world coordinates (0,0), (64,0), (0,64), etc.
    vec2 grid_pos = mod(world_pos, dynamic_grid_size);
    
    // Create dots at grid intersections instead of lines
    float dot_size = line_thickness * 2.0;
    float dist_to_corner = length(grid_pos);
    float dist_to_corner_x = length(vec2(grid_pos.x - dynamic_grid_size, grid_pos.y));
    float dist_to_corner_y = length(vec2(grid_pos.x, grid_pos.y - dynamic_grid_size));
    float dist_to_corner_xy = length(grid_pos - vec2(dynamic_grid_size));
    
    // Find minimum distance to any corner
    float min_dist = min(min(dist_to_corner, dist_to_corner_x), min(dist_to_corner_y, dist_to_corner_xy));
    
    // Create dot
    float grid = 1.0 - smoothstep(0.0, dot_size, min_dist);
    
    // Add wave distortion based on world position
    float wave = sin(world_pos.y * 0.01 + TIME * wave_speed) * wave_amplitude;
    world_pos.x += wave;
    
    // Pulse effect
    float pulse = 1.0 + pulse_strength * sin(TIME * 2.0);
    
    // Calculate distance from camera center for radial effects
    float dist = length(world_pos - camera_position) / 500.0;
    float radial_fade = 1.0 - smoothstep(0.5, 1.5, dist);
    
    // Combine effects
    vec4 final_color = mix(bg_color, grid_color, grid * pulse * radial_fade);
    
    // Add subtle gradient
    final_color.rgb += vec3(0.0, 0.0, 0.1) * (1.0 - uv.y / 1280.0);
    
    COLOR = final_color;
}