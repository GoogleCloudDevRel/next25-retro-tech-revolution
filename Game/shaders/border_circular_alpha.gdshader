shader_type canvas_item;

uniform float border_width : hint_range(0.0, 0.5) = 0.1;
uniform float border_softness : hint_range(0.0, 0.5) = 0.05;

void fragment() {
    vec4 color = texture(TEXTURE, UV);

    // Calculate distance from center (0-1 range)
    vec2 center_dist = UV - 0.5;

    // For circular border (uses distance from center)
    float dist = length(center_dist) * 2.0;

    // Create smooth border transition
    float alpha_factor = 1.0 - smoothstep(1.0 - border_width - border_softness, 1.0 - border_width, dist);

    // Apply to alpha channel
    COLOR = vec4(color.rgb, color.a * alpha_factor);
}
