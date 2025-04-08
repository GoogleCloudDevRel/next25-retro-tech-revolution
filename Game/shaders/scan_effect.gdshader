shader_type canvas_item;

// Texture input
//uniform sampler2D TEXTURE;

// Glow parameters
uniform vec3 glow_color : source_color = vec3(1.0, 0.5, 0.2);
uniform float glow_intensity : hint_range(0.0, 2.0) = 1.0;
uniform float pulse_speed : hint_range(0.1, 5.0) = 1.0;
uniform float pulse_amplitude : hint_range(0.0, 1.0) = 0.5;
uniform float glow_threshold : hint_range(0.0, 1.0) = 0.1;
uniform float softness : hint_range(0.0, 1.0) = 0.3;

void fragment() {
    // Sample the texture
    vec4 tex_color = texture(TEXTURE, UV);
    
    // Create a pulsing effect based on time
    float pulse = pulse_amplitude * sin(TIME * pulse_speed * 3.14159) + (1.0 - pulse_amplitude);
    
    // Calculate glow intensity with pulse
    float intensity = glow_intensity * pulse;
    
    // Create the glow effect with soft edges
    vec3 glow = glow_color * intensity;
    
    // Only apply glow to non-transparent areas with a threshold
    // The softness creates a more gradual transition
    float alpha_mask = smoothstep(glow_threshold - softness, glow_threshold + softness, tex_color.a);
    
    // Mix the original color with the glow based on the mask
    vec3 final_color = mix(tex_color.rgb, tex_color.rgb + glow, alpha_mask);
    
    // Keep the original alpha for transparency
    COLOR = vec4(final_color, tex_color.a);
}