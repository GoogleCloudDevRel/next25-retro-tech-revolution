shader_type canvas_item;

uniform float border_width_pixels : hint_range(1.0, 100.0) = 10.0; // Border width in pixels
uniform float corner_radius : hint_range(0.0, 0.5) = 0.2; // Corner roundness (relative)
uniform float border_softness : hint_range(0.0, 0.1) = 0.02; // Border softness (relative)
uniform int gradient_direction = 0; // 0 = diagonal, 1 = left-to-right, 2 = top-to-bottom, 3 = circular

// Multiple color stops for gradient (up to 5 colors)
uniform vec4 gradient_color1 : source_color = vec4(1.0, 0.0, 0.0, 1.0);
uniform vec4 gradient_color2 : source_color = vec4(0.0, 1.0, 0.0, 1.0);
uniform vec4 gradient_color3 : source_color = vec4(0.0, 0.0, 1.0, 1.0);
uniform vec4 gradient_color4 : source_color = vec4(1.0, 1.0, 0.0, 1.0);
uniform vec4 gradient_color5 : source_color = vec4(0.0, 1.0, 1.0, 1.0);

// Position of each color stop (0.0 to 1.0)
uniform float color_pos1 : hint_range(0.0, 1.0) = 0.0;
uniform float color_pos2 : hint_range(0.0, 1.0) = 0.25;
uniform float color_pos3 : hint_range(0.0, 1.0) = 0.5;
uniform float color_pos4 : hint_range(0.0, 1.0) = 0.75;
uniform float color_pos5 : hint_range(0.0, 1.0) = 1.0;

// Number of active color stops (2-5)
uniform int color_count : hint_range(2, 5) = 3;

float rounded_rectangle(vec2 pixel_pos, vec2 rect_size, vec2 rect_center, float radius_pixels) {
    // Calculate distance in pixels
    vec2 d = abs(pixel_pos - rect_center) - rect_size * 0.5 + radius_pixels;
    return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0) - radius_pixels;
}

// Function to get color from multi-stop gradient
vec4 get_gradient_color(float t) {
    // Default to first color
    vec4 color = gradient_color1;

    if (color_count >= 2 && t >= color_pos1 && t < color_pos2) {
        float factor = (t - color_pos1) / (color_pos2 - color_pos1);
        color = mix(gradient_color1, gradient_color2, factor);
    }
    if (color_count >= 3 && t >= color_pos2 && t < color_pos3) {
        float factor = (t - color_pos2) / (color_pos3 - color_pos2);
        color = mix(gradient_color2, gradient_color3, factor);
    }
    if (color_count >= 4 && t >= color_pos3 && t < color_pos4) {
        float factor = (t - color_pos3) / (color_pos4 - color_pos3);
        color = mix(gradient_color3, gradient_color4, factor);
    }
    if (color_count >= 5 && t >= color_pos4 && t <= color_pos5) {
        float factor = (t - color_pos4) / (color_pos5 - color_pos4);
        color = mix(gradient_color4, gradient_color5, factor);
    }

    return color;
}

void fragment() {
    vec4 texture_color = texture(TEXTURE, UV);

    // Get actual pixel coordinates and dimensions
    vec2 texture_pixel_size = 1.0 / TEXTURE_PIXEL_SIZE;
    vec2 pixel_pos = UV * texture_pixel_size;
    vec2 center = texture_pixel_size * 0.5;

    // Calculate corner radius in pixels based on the smaller dimension
    float radius_pixels = min(texture_pixel_size.x, texture_pixel_size.y) * corner_radius;

    // Calculate inner rectangle size (subtracting border width in pixels)
    vec2 inner_size = texture_pixel_size - 2.0 * vec2(border_width_pixels);

    // Calculate distances in pixels
    float inner_dist = rounded_rectangle(pixel_pos, inner_size, center, radius_pixels);
    float outer_dist = rounded_rectangle(pixel_pos, texture_pixel_size, center, radius_pixels);

    // Convert softness to pixels
    float softness_pixels = min(texture_pixel_size.x, texture_pixel_size.y) * border_softness;

    // Determine gradient position based on selected direction
    float gradient_pos;
    if (gradient_direction == 0) {
        // Diagonal gradient (top-left to bottom-right)
        gradient_pos = ((1.0 - UV.y) + UV.x) * 0.5;
		//gradient_pos = ( UV.y + UV.x) * 0.5;
    } else if (gradient_direction == 1) {
        // Left-to-right gradient
        gradient_pos = UV.x;
    } else if (gradient_direction == 2) {
        // Top-to-bottom gradient
        gradient_pos = UV.y;
    } else if (gradient_direction == 3) {
        // Circular gradient
        gradient_pos = length(UV - vec2(0.5)) * 2.0;
    } else {
        // Diagonal gradient as fallback
        gradient_pos = (UV.x + UV.y) * 0.5;
    }

    // Get border color from multi-stop gradient
    vec4 border_color = get_gradient_color(gradient_pos);

    // Determine region and calculate color
    vec4 final_color;
    float final_alpha = 1.0;

    if (inner_dist < -softness_pixels) {
        // Inside the inner rectangle - use original texture
        final_color = texture_color;
        final_alpha = texture_color.a;
    } else if (inner_dist < softness_pixels) {
        // Transition between inner and border
        float blend = smoothstep(-softness_pixels, softness_pixels, inner_dist);
        final_color = mix(texture_color, border_color, blend);
        final_alpha = mix(texture_color.a, border_color.a * texture_color.a, blend);
    } else if (outer_dist < -softness_pixels) {
        // Fully in border area - use gradient
        final_color = border_color;
        final_alpha = border_color.a * texture_color.a;
    } else if (outer_dist < softness_pixels) {
        // Transition to outside
        float blend = smoothstep(-softness_pixels, softness_pixels, outer_dist);
        final_color = border_color;
        final_alpha = border_color.a * texture_color.a * (1.0 - blend);
    } else {
        // Outside - completely transparent
        final_color = vec4(0.0);
        final_alpha = 0.0;
    }

    COLOR = vec4(final_color.rgb, final_alpha);
}