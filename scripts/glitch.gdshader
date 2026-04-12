shader_type canvas_item;

uniform float glitch_speed = 0.01;
uniform float glitch_size = 0.003;
uniform float brightness_multiplier : hint_range(1.0, 5.0) = 1.5;

uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;

void fragment() {
	vec2 shift = vec2(sin(TIME * glitch_speed + SCREEN_UV.y * 30.0) * glitch_size, 0.0);
	
	float r = texture(screen_texture, SCREEN_UV - shift).r;
	float g = texture(screen_texture, SCREEN_UV).g;
	float b = texture(screen_texture, SCREEN_UV + shift).b;
	float a = texture(screen_texture, SCREEN_UV).a;
	
	COLOR = vec4(r * brightness_multiplier, g * brightness_multiplier, b * brightness_multiplier, a);
}