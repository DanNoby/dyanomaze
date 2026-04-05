shader_type canvas_item;

uniform float noise_density = 100.0;
uniform float speed = 1.5;
uniform vec4 dust_color : source_color = vec4(0.85, 0.75, 0.55, 1.0); 
uniform float opacity = 0.35;

float random(vec2 uv) {
    return fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
    vec2 moving_uv = UV + vec2(TIME * speed, TIME * speed * 0.15);
    vec2 grid_uv = floor(moving_uv * noise_density) / noise_density;
    
    float noise = random(grid_uv);
    
    if (noise > 0.97) {
        COLOR = vec4(dust_color.rgb, dust_color.a * opacity);
    } else {
        COLOR = vec4(0.0, 0.0, 0.0, 0.0);
    }
}