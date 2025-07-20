shader_type canvas_item;

// Beat sync parameters
uniform float beat_pulse : hint_range(0.0, 1.0) = 0.0;
uniform float beat_time : hint_range(0.0, 1.0) = 0.0;

// Color parameters
uniform vec4 base_color : source_color = vec4(0.29, 0.08, 0.55, 1.0); // Deep purple
uniform vec4 glow_color : source_color = vec4(0.0, 0.74, 0.83, 1.0); // Cyan
uniform vec4 accent_color : source_color = vec4(0.91, 0.12, 0.39, 1.0); // Magenta

// Effect parameters
uniform float glow_intensity : hint_range(0.0, 2.0) = 0.8;
uniform float edge_softness : hint_range(0.0, 0.2) = 0.1;
uniform float pattern_scale : hint_range(1.0, 10.0) = 4.0;
uniform float flow_speed : hint_range(0.0, 2.0) = 0.5;

// Creates smooth rounded rectangle SDF
float rounded_box_sdf(vec2 center_pos, vec2 size, float radius) {
    vec2 q = abs(center_pos) - size + radius;
    return min(max(q.x, q.y), 0.0) + length(max(q, 0.0)) - radius;
}

// Hexagonal pattern for internal texture
float hexagon_pattern(vec2 p) {
    vec2 h = vec2(1.0, sqrt(3.0));
    vec2 a = mod(p, h) - h * 0.5;
    vec2 b = mod(p - h * 0.5, h) - h * 0.5;
    return min(dot(a, a), dot(b, b));
}

void fragment() {
    vec2 uv = UV;
    vec2 center = vec2(0.5);
    vec2 pos = uv - center;
    
    // Create rounded rectangle shape
    float dist = rounded_box_sdf(pos, vec2(0.45), 0.08);
    float shape = 1.0 - smoothstep(0.0, edge_softness, dist);
    
    // Inner glow gradient
    float inner_glow = 1.0 - smoothstep(0.0, 0.3, abs(dist));
    
    // Animated hexagonal pattern
    vec2 pattern_uv = uv * pattern_scale + vec2(TIME * flow_speed, 0.0);
    float pattern = hexagon_pattern(pattern_uv);
    pattern = 1.0 - smoothstep(0.1, 0.3, pattern);
    
    // Edge glow effect
    float edge_glow = smoothstep(0.02, 0.0, abs(dist)) * 0.5;
    
    // Beat-reactive pulse
    float pulse = beat_pulse * 0.3 + 1.0;
    
    // Energy flow lines
    float flow_line1 = sin(uv.x * 20.0 - TIME * 2.0) * 0.5 + 0.5;
    float flow_line2 = sin(uv.y * 15.0 + TIME * 1.5) * 0.5 + 0.5;
    float flow = (flow_line1 * flow_line2) * 0.2 * shape;
    
    // Combine base color with effects
    vec3 col = base_color.rgb;
    
    // Add gradient from center
    float gradient = length(pos) * 2.0;
    col = mix(col, col * 0.7, gradient);
    
    // Add pattern
    col = mix(col, accent_color.rgb, pattern * 0.2 * shape);
    
    // Add inner glow
    col = mix(col, glow_color.rgb, inner_glow * glow_intensity * 0.5);
    
    // Add edge glow
    col += glow_color.rgb * edge_glow * glow_intensity * pulse;
    
    // Add flow effect
    col += glow_color.rgb * flow * pulse;
    
    // Bloom effect simulation
    float bloom = smoothstep(0.1, -0.1, dist);
    col += glow_color.rgb * bloom * 0.3 * pulse;
    
    // Output
    COLOR.rgb = col;
    COLOR.a = shape + bloom * 0.5;
    
    // Add subtle outer glow for bloom
    if (dist > 0.0 && dist < 0.2) {
        float outer_glow = 1.0 - smoothstep(0.0, 0.2, dist);
        COLOR.rgb = glow_color.rgb * outer_glow * 0.3 * pulse;
        COLOR.a = outer_glow * 0.3 * pulse;
    }
}