shader_type canvas_item;

// Parameters that can be adjusted in the Inspector
uniform vec4 glow_color : source_color = vec4(1.0, 1.0, 1.0, 0.5);
uniform float glow_intensity : hint_range(0.0, 5.0) = 2.0;
uniform float glow_size : hint_range(0.0, 10.0) = 3.0;
uniform float glow_threshold : hint_range(0.0, 1.0) = 0.1;
uniform float outer_glow_strength : hint_range(0.0, 2.0) = 1.0;
uniform float inner_glow_strength : hint_range(0.0, 2.0) = 0.5;

void fragment() {
    // Get the original texture color (the text)
    vec4 original_color = texture(TEXTURE, UV);

    // Initialize our final color with the original
    vec4 final_color = original_color;

    // Calculate outer glow
    float outer_glow = 0.0;
    for(float x = -glow_size; x <= glow_size; x += 1.0) {
        for(float y = -glow_size; y <= glow_size; y += 1.0) {
            // Skip calculations outside our radius to optimize
            if (x*x + y*y > glow_size*glow_size) continue;

            // Sample nearby pixels
            vec2 offset = vec2(x, y) * TEXTURE_PIXEL_SIZE;
            float sample = texture(TEXTURE, UV + offset).a;

            // Add to our glow based on distance
            float dist = length(vec2(x, y)) / glow_size;
            outer_glow += sample * (1.0 - dist) * outer_glow_strength;
        }
    }

    // Calculate inner glow (brighten the text itself)
    float inner_glow = original_color.a * inner_glow_strength;

    // Combine original color with glow effects
    if (original_color.a > glow_threshold) {
        // Apply inner glow directly to text
        final_color = mix(original_color, glow_color, inner_glow);
    } else {
        // Apply outer glow only where there's no text
        final_color = mix(final_color, glow_color, min(outer_glow * glow_intensity, 1.0) * (1.0 - original_color.a));
    }

    COLOR = final_color;
}