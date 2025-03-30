shader_type canvas_item;

// Chroma key color (e.g., green or blue)
uniform vec3 chroma_key_color : source_color = vec3(0.0, 1.0, 0.0);
uniform float fade_factor : hint_range(0.0,1.0);
uniform float range : hint_range(0.0,1.0);
uniform float fuzziness : hint_range(0.0,1.0);

void fragment() {
    vec3 color = texture(TEXTURE, UV).rgb;

    // Calculate the distance between the pixel color and the chroma key color
    float distance = length(color - chroma_key_color);

    // Discard or fade the pixel based on the distance
    if (distance < range) {
        // Remove the color
        discard;
    } else {
        // Fade the color
        COLOR = vec4(color, 1.0);
    }
}