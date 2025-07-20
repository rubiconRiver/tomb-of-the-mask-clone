shader_type canvas_item;

// Core colors
uniform vec4 core_color : source_color = vec4(0.0, 1.0, 0.8, 1.0); // Cyan core
uniform vec4 inner_glow_color : source_color = vec4(0.0, 0.8, 1.0, 1.0); // Bright blue
uniform vec4 outer_glow_color : source_color = vec4(1.0, 1.0, 1.0, 1.0); // White

// Effect parameters
uniform float core_size : hint_range(0.1, 0.5) = 0.25;
uniform float inner_glow_size : hint_range(0.3, 0.7) = 0.5;
uniform float outer_glow_size : hint_range(0.5, 1.0) = 0.8;
uniform float pulse_strength : hint_range(0.0, 0.5) = 0.2;
uniform float rotation_speed : hint_range(0.0, 5.0) = 1.0;
uniform float energy_flow_speed : hint_range(0.0, 5.0) = 2.0;

// Beat sync
uniform float beat_pulse : hint_range(0.0, 1.0) = 0.0;

float circle_sdf(vec2 pos, float radius) {
    return length(pos) - radius;
}

// Rotating energy pattern
float energy_pattern(vec2 pos, float time) {
    float angle = atan(pos.y, pos.x);
    float dist = length(pos);
    
    // Spiral arms
    float spiral = sin(angle * 3.0 - time * rotation_speed + dist * 10.0) * 0.5 + 0.5;
    
    // Radial waves
    float waves = sin(dist * 20.0 - time * energy_flow_speed) * 0.5 + 0.5;
    
    return spiral * waves;
}

void fragment() {
    vec2 uv = UV;
    vec2 center = vec2(0.5);
    vec2 pos = uv - center;
    
    // Aspect ratio correction
    pos.x *= 1.0;
    
    float dist = length(pos);
    
    // Dynamic sizing based on beat
    float pulse = 1.0 + beat_pulse * pulse_strength;
    
    // Create layered orb effect
    float core = 1.0 - smoothstep(0.0, 0.02, circle_sdf(pos, core_size * pulse));
    float inner_glow = 1.0 - smoothstep(0.0, 0.1, circle_sdf(pos, inner_glow_size * pulse));
    float outer_glow = 1.0 - smoothstep(0.0, 0.2, circle_sdf(pos, outer_glow_size * pulse));
    
    // Energy pattern
    float energy = energy_pattern(pos, TIME);
    energy *= inner_glow * (1.0 - core);
    
    // Combine layers
    vec3 color = vec3(0.0);
    
    // Outer glow (additive)
    color += outer_glow_color.rgb * outer_glow * 0.3 * pulse;
    
    // Inner glow
    color += inner_glow_color.rgb * inner_glow * 0.6;
    
    // Energy flow
    color += core_color.rgb * energy * 0.4;
    
    // Bright core
    color += core_color.rgb * core * 2.0;
    
    // Add bloom-like effect
    float bloom = exp(-dist * 3.0) * 0.5;
    color += outer_glow_color.rgb * bloom * pulse;
    
    // Alpha
    float alpha = max(max(core, inner_glow * 0.8), outer_glow * 0.3);
    alpha = max(alpha, bloom * 0.5);
    
    COLOR.rgb = color;
    COLOR.a = alpha;
}