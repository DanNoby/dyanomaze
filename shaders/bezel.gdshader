shader_type canvas_item;

uniform float pixel_size : hint_range(1.0, 16.0) = 4.0;
uniform float color_crunch : hint_range(2.0, 32.0) = 8.0;
uniform float brightness : hint_range(0.0, 2.0) = 1.0;

void fragment() {

    vec2 tex_size = vec2(textureSize(TEXTURE, 0));
    vec2 pixelated_uv = floor(UV * tex_size / pixel_size) / (tex_size / pixel_size);

    vec4 tex_color = texture(TEXTURE, pixelated_uv);
    
    tex_color.rgb = floor(tex_color.rgb * color_crunch + 0.5) / color_crunch;
    
    tex_color.rgb *= brightness;
    
    COLOR = tex_color;
}