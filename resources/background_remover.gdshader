shader_type canvas_item;

uniform vec4 key_color : source_color = vec4(0.12, 0.12, 0.12, 1.0);
uniform float threshold : hint_range(0.0, 1.0) = 0.1;
uniform float softness : hint_range(0.0, 1.0) = 0.05;

void fragment() {
    vec4 col = texture(TEXTURE, UV);
    float dist = distance(col.rgb, key_color.rgb);
    
    // Smooth transition for transparency
    float alpha = smoothstep(threshold, threshold + softness, dist);
    
    // Discard pixels that are very close to the key color
    if (alpha < 0.1) {
        discard;
    }
    
    COLOR = vec4(col.rgb, col.a * alpha);
}
