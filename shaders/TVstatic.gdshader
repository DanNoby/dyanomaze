shader_type canvas_item;

uniform float static_intensity : hint_range(0.0, 1.0) = 0.15;
uniform float scanline_intensity : hint_range(0.0, 1.0) = 0.05;
uniform float vignette_scale : hint_range(0.0, 3.0) = 1.5;

// Pseudo-random noise generator
float random(vec2 uv) {
    return fract(sin(dot(uv.xy, vec2(12.9898,78.233))) * 43758.5453123);
}

void fragment() {
    // We keep the standard UV so it perfectly fits your flat rectangular monitor
    
    // 1. Generate Animated Static Noise
    float tv_noise = random(UV * 100.0 + fract(TIME));
    
    // 2. Generate Scanlines
    float scanlines = sin(UV.y * 800.0) * scanline_intensity;
    
    // 3. Calculate Vignette (The dark, moody corners)
    float vignette = distance(UV, vec2(0.5));
    vignette = smoothstep(0.5, 0.5 - (0.5 / vignette_scale), vignette);
    
    // 4. Apply the original, thick mixing math!
    vec4 base_color = COLOR; 
    
    // This 'mix' function is what gives the static that heavy, authentic TV feel
    vec4 static_layer = vec4(vec3(tv_noise), 1.0);
    vec4 final_color = mix(base_color, static_layer, static_intensity);
    
    // Apply scanlines and shadows
    final_color.rgb -= scanlines;
    final_color.rgb *= vignette;
    
    COLOR = final_color;
}