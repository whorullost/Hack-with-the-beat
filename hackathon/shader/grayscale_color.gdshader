shader_type canvas_item;
render_mode blend_premul_alpha; 

// --- TEXTURE INPUTS ---
uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;

// --- EFFECT PARAMETERS ---
uniform float color_strength : hint_range(0.0, 1.0) = 0.7;      // Color intensity in bleed areas
uniform float grayscale_strength : hint_range(0.0, 1.0) = 0.9;  // Overall grayscale intensity

// --- BLEED EVENT DATA ---
uniform vec4 bleed_events[64];  // Array of bleed events (position.xy, radius.z, unused.w)
uniform int num_events;         // Number of active events

// --- CAMERA TRANSFORMATION DATA ---
// These parameters allow conversion from screen UV coordinates to world coordinates
uniform vec2 camera_world_pos;  // Camera's world position
uniform vec2 camera_zoom;       // Camera zoom level
uniform float camera_rotation;  // Camera rotation
uniform vec2 camera_offset;     // Camera offset
uniform vec2 viewport_size;     // Screen resolution

// --- CONSTANTS ---
const vec3 GRAYSCALE_WEIGHTS = vec3(0.299, 0.587, 0.114);  // Standard luminance weights


vec2 screen_uv_to_world_pos(vec2 screen_uv) {
    // Convert normalized UV to actual pixel coordinates
    vec2 screen_pixel_coords = screen_uv * viewport_size;
    
    // Center coordinates (0,0 at screen center instead of top-left)
    vec2 centered_screen_coords = screen_pixel_coords - (viewport_size / 2.0);
    
    // Compensate for camera offset
    vec2 offset_compensated_coords = centered_screen_coords - camera_offset;
    
    // Apply zoom transformation (higher zoom = smaller world area visible)
    vec2 zoomed_coords = offset_compensated_coords / camera_zoom;
    
    // Apply inverse rotation to match world space
    float cos_neg_angle = cos(-camera_rotation);
    float sin_neg_angle = sin(-camera_rotation);
    
    vec2 unrotated_coords;
    unrotated_coords.x = zoomed_coords.x * cos_neg_angle - zoomed_coords.y * sin_neg_angle;
    unrotated_coords.y = zoomed_coords.x * sin_neg_angle + zoomed_coords.y * cos_neg_angle;

    // Translate to final world position
    vec2 world_pos = camera_world_pos + unrotated_coords;

    return world_pos;
}

/**
 * MAIN FRAGMENT FUNCTION
 * Processes each screen pixel to determine final color.
 * 
 * Algorithm:
 * 1. Get original screen color
 * 2. Convert screen position to world coordinates
 * 3. Check distance to all active bleed events
 * 4. Calculate color mask based on proximity to events
 * 5. Blend between grayscale and original color based on mask
 */

void fragment() {
    // Get the original screen color at this pixel
    vec4 screen_color = texture(screen_texture, SCREEN_UV);
    
    // Convert this pixel's screen position to world coordinates
    vec2 world_pos = screen_uv_to_world_pos(SCREEN_UV); 

    float total_mask_alpha = 0.0;  // Accumulates color reveal strength
    bool is_debug_pixel = false;   // For debugging bleed event centers
    
    // Check proximity to all active bleed events
    for (int i = 0; i < num_events; i++) {
        vec4 event_data = bleed_events[i];
        vec2 event_pos = event_data.xy;    // World position of event
        float radius = event_data.z;       // Current radius of event

        // Skip inactive events
        if (radius <= 0.0) {
            continue;
        }

        float dist = distance(world_pos, event_pos);
        
        // DELETE LATER - debuging purposes 
        // Show bright green dot at exact center of bleed event - helps verify that world coordinate conversion is working correctly
        /*
		if (dist < 8.0) {
            COLOR = vec4(0.0, 1.0, 0.0, 1.0); // Bright green
            is_debug_pixel = true;
            break;
        }
		*/ 
        
        // Calculate color reveal strength based on distance
        // Pixels closer to event center show more color
        float alpha = 1.0 - (dist / radius);          // Linear falloff
        alpha = smoothstep(0.0, 1.0, alpha);         // Smooth edges
        total_mask_alpha = max(total_mask_alpha, alpha);  // Combine multiple events
    }
    
    // Apply the final color effect (unless this is a debug pixel)
    if (!is_debug_pixel) {
        // Convert original color to grayscale using standard weights
        float gray = dot(screen_color.rgb, GRAYSCALE_WEIGHTS);
        vec3 gray_color = vec3(gray);

        // Blend between grayscale and color based on mask strength
        vec3 masked_color_effect = mix(gray_color, screen_color.rgb, total_mask_alpha * color_strength);
        
        // Apply overall grayscale strength
        vec3 final_color = mix(screen_color.rgb, masked_color_effect, grayscale_strength);

        COLOR = vec4(final_color, screen_color.a);
    }
}