shader_type canvas_item;

// Your perfect glitch settings
uniform float glitch_speed = 0.08;
uniform float glitch_size = 0.01;

// The Slicer Controls
uniform float letter_count = 5.0;
uniform float spread_amount : hint_range(0.0, 0.1) = 0.02;

void fragment() {
	vec2 shifted_uv = UV;
	
	// 1. Cut the image into vertical strips
	float slice = floor(UV.x * letter_count);
	
	// 2. Calculate an outward push from the center
	float center_push = slice - (letter_count / 2.0);
	
	// Apply the push to the UV coordinates
	shifted_uv.x -= center_push * spread_amount;
	
	// 3. Apply your glitch effect to the newly separated slices!
	vec2 shift = vec2(sin(TIME * glitch_speed + shifted_uv.y * 30.0) * glitch_size, 0.0);
	
	float a_red = texture(TEXTURE, shifted_uv - shift).a;
	float a_blue = texture(TEXTURE, shifted_uv + shift).a;
	float a_main = texture(TEXTURE, shifted_uv).a;
	
	vec3 glitch_color = vec3(a_red, a_main * 0.2, a_blue);
	float final_alpha = max(max(a_red, a_blue), a_main);
	
	// Hide the bleeding edges where the texture wraps around
	if (shifted_uv.x < 0.0 || shifted_uv.x > 1.0) {
		final_alpha = 0.0;
	}
	
	COLOR = vec4(glitch_color, final_alpha);
}