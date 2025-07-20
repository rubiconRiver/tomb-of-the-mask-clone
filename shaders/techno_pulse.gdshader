shader_type canvas_item;

uniform float pulse_strength : hint_range(0.0, 1.0) = 0.15;
uniform float glow_strength : hint_range(0.0, 2.0) = 0.5;
uniform vec4 glow_color : source_color = vec4(0.0, 1.0, 1.0, 1.0);
uniform float time_offset : hint_range(0.0, 1.0) = 0.0;
uniform float scanline_speed : hint_range(0.0, 5.0) = 2.0;
uniform float scanline_opacity : hint_range(0.0, 1.0) = 0.1;

void fragment() {
    vec4 base_color = texture(TEXTURE, UV);
    
    // Pulsing effect based on beat
    float pulse = 1.0 + pulse_strength * sin(TIME * 6.28318);
    
    // Glow effect
    vec4 glow = glow_color * glow_strength * pulse;
    
    // Scanline effect
    float scanline = sin((UV.y + TIME * scanline_speed) * 100.0) * scanline_opacity;
    
    // Edge detection for enhanced glow
    float edge = 0.0;
    if (base_color.a > 0.01) {
        vec2 texel_size = 1.0 / vec2(textureSize(TEXTURE, 0));
        float neighbors = 0.0;
        for (int x = -1; x <= 1; x++) {
            for (int y = -1; y <= 1; y++) {
                if (x != 0 || y != 0) {
                    neighbors += texture(TEXTURE, UV + vec2(float(x), float(y)) * texel_size).a;
                }
            }
        }
        if (neighbors < 8.0 * base_color.a) {
            edge = 1.0;
        }
    }
    
    // Combine effects
    COLOR = base_color;
    COLOR.rgb *= pulse;
    COLOR.rgb += glow.rgb * base_color.a * (0.5 + edge * 0.5);
    COLOR.rgb += vec3(scanline);
    
    // Add subtle chromatic aberration on edges
    if (edge > 0.5) {
        vec2 offset = vec2(0.002, 0.0) * pulse;
        float r = texture(TEXTURE, UV - offset).r;
        float b = texture(TEXTURE, UV + offset).b;
        COLOR.r = mix(COLOR.r, r, 0.3);
        COLOR.b = mix(COLOR.b, b, 0.3);
    }
}