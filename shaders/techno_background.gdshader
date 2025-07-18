shader_type canvas_item;

uniform float grid_size : hint_range(10.0, 100.0) = 64.0;
uniform float line_thickness : hint_range(0.5, 5.0) = 1.0;
uniform vec4 grid_color : source_color = vec4(0.0, 0.5, 0.5, 0.3);
uniform vec4 bg_color : source_color = vec4(0.0, 0.0, 0.1, 1.0);
uniform float pulse_strength : hint_range(0.0, 1.0) = 0.3;
uniform float wave_speed : hint_range(0.0, 5.0) = 1.0;
uniform float wave_amplitude : hint_range(0.0, 20.0) = 5.0;

void fragment() {
    vec2 uv = FRAGCOORD.xy;
    
    // Create grid lines
    vec2 grid_uv = mod(uv, grid_size) / grid_size;
    float grid_x = smoothstep(0.0, line_thickness / grid_size, grid_uv.x) * 
                   smoothstep(0.0, line_thickness / grid_size, 1.0 - grid_uv.x);
    float grid_y = smoothstep(0.0, line_thickness / grid_size, grid_uv.y) * 
                   smoothstep(0.0, line_thickness / grid_size, 1.0 - grid_uv.y);
    float grid = 1.0 - max(grid_x, grid_y);
    
    // Add wave distortion
    float wave = sin(uv.y * 0.01 + TIME * wave_speed) * wave_amplitude;
    uv.x += wave;
    
    // Pulse effect
    float pulse = 1.0 + pulse_strength * sin(TIME * 2.0);
    
    // Calculate distance from center for radial effects
    vec2 center = vec2(360.0, 640.0); // Design resolution center
    float dist = length(uv - center) / 500.0;
    float radial_fade = 1.0 - smoothstep(0.5, 1.5, dist);
    
    // Combine effects
    vec4 final_color = mix(bg_color, grid_color, grid * pulse * radial_fade);
    
    // Add subtle gradient
    final_color.rgb += vec3(0.0, 0.0, 0.1) * (1.0 - uv.y / 1280.0);
    
    COLOR = final_color;
}