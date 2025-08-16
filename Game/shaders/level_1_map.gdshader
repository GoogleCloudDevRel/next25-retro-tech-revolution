shader_type canvas_item;

// Player or user position in world coordinates
uniform vec2 player_position;

// Maximum visibility distance around the player
uniform float visibility_radius = 300.0;

// How sharp the transition is between visible and hidden areas
uniform float edge_softness = 50.0;

// Optional: Use a pattern/noise texture for more interesting effects
uniform sampler2D noise_texture : filter_linear_mipmap;
uniform float noise_influence = 0.2;

// Transform between world coordinates and UV coordinates
uniform vec2 world_size = vec2(1024.0, 600.0);

uniform bool affect_children = true;

void fragment() {
    // Get the original texture color
    vec4 original_color = texture(TEXTURE, UV);

    // Calculate the world position of this fragment
    vec2 world_position = UV * world_size;

	// For containers, we can use SCREEN_UV to get screen position
    // This helps when shader is applied to a parent node
    vec2 position_to_use = affect_children ? (SCREEN_UV * world_size) : world_position;

    // Calculate distance from player to this fragment
    float distance_to_player = distance(world_position, player_position);

    // Calculate visibility factor (1.0 = fully visible, 0.0 = hidden)
    float visibility = 1.0 - smoothstep(visibility_radius - edge_softness,
                                        visibility_radius,
                                        distance_to_player);

    // Optional: Add some noise to make the edge less uniform
    if (noise_influence > 0.0) {
        float noise = texture(noise_texture, UV * 5.0).r; // Scale UV for smaller noise pattern
        visibility = mix(visibility, visibility * noise, noise_influence);
    }

    // Apply the visibility to the alpha channel - this is the corrected line
    vec4 final_color = vec4(original_color.rgb, original_color.a * visibility);

    // Assign to COLOR in Godot's expected way
    COLOR = final_color;
}