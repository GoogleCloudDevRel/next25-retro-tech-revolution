shader_type canvas_item;
render_mode unshaded;

// Adjustable parameters
uniform float scan_line_count : hint_range(0, 1080) = 200.0;
uniform float scan_line_intensity : hint_range(0.0, 1.0) = 0.3;
uniform float noise_intensity : hint_range(0.0, 1.0) = 0.05;
uniform float curvature : hint_range(0.0, 1.0) = 0.2;
uniform float vignette_intensity : hint_range(0.0, 1.0) = 0.2;
uniform float brightness : hint_range(0.0, 2.0) = 1.2;
uniform float flicker_intensity : hint_range(0.0, 1.0) = 0.03;
uniform float rgb_shift : hint_range(0.0, 5.0) = 0.5;

uniform sampler2D SCREEN_TEXTURE: hint_screen_texture, filter_linear_mipmap;

// Random function for noise generation
float random(vec2 uv) {
    return fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453);
}

// Distort the UV coordinates to create screen curvature
vec2 curve_uv(vec2 uv) {
    uv = uv * 2.0 - 1.0;
    vec2 offset = abs(uv.yx) / vec2(6.0, 4.0);
    uv = uv + uv * offset * offset * curvature;
    uv = uv * 0.5 + 0.5;
    return uv;
}

void fragment() {
    // Apply screen curvature
    vec2 curved_uv = curve_uv(SCREEN_UV);

    // Check if we're outside the screen after curving
    if (curved_uv.x < 0.0 || curved_uv.x > 1.0 || curved_uv.y < 0.0 || curved_uv.y > 1.0) {
        COLOR = vec4(0.0, 0.0, 0.0, 1.0);

    }

    // Create scanlines
    float scan_line = sin(curved_uv.y * scan_line_count * 3.14159);
    scan_line = (1.0 - scan_line_intensity) + scan_line_intensity * (0.5 + 0.5 * scan_line);

    // RGB shift
    float r = texture(SCREEN_TEXTURE, vec2(curved_uv.x + rgb_shift / 1000.0, curved_uv.y)).r;
    float g = texture(SCREEN_TEXTURE, curved_uv).g;
    float b = texture(SCREEN_TEXTURE, vec2(curved_uv.x - rgb_shift / 1000.0, curved_uv.y)).b;

    // Combine RGB channels
    vec4 color = vec4(r, g, b, texture(SCREEN_TEXTURE, curved_uv).a);

    // Add noise
    float noise = random(curved_uv * TIME);
    color.rgb += noise_intensity * (noise - 0.5);

    // Add flicker effect
    float flicker = random(vec2(TIME * 0.1, 0.0));
    color.rgb *= 1.0 - flicker_intensity + flicker_intensity * flicker;

    // Apply scanlines
    color.rgb *= scan_line;

    // Apply vignette (darkening around edges)
    vec2 vignette_uv = curved_uv * (1.0 - curved_uv.yx);
    float vignette = pow(vignette_uv.x * vignette_uv.y * 15.0, vignette_intensity);
    color.rgb *= vignette;

    // Adjust brightness
    color.rgb *= brightness;

    COLOR = color;
}