shader_type canvas_item;

uniform float border_width : hint_range(0.0, 0.5) = 0.1; // Width of the border as percentage of image size
uniform float border_softness : hint_range(0.0, 0.5) = 0.05; // Softness/feathering of the border

void fragment() {
    vec4 color = texture(TEXTURE, UV);

    // Calculate distance from edge
    vec2 center_dist = abs(UV - 0.5) * 2.0; // Distance from center (0-1 range)
    float max_dist = max(center_dist.x, center_dist.y); // Use max for rectangular border

    // Create smooth border transition
    float alpha_factor = 1.0 - smoothstep(1.0 - border_width - border_softness, 1.0 - border_width, max_dist);

    // Apply to alpha channel
    COLOR = vec4(color.rgb, color.a * alpha_factor);
}