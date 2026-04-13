shader_type canvas_item;

// Controls how chunky the pixels are (1.0 = native image, 4.0 = PS1 style)
uniform float pixel_size : hint_range(1.0, 16.0) = 4.0;

// Controls how many colors are allowed (lower = more retro/banded colors)
uniform float color_crunch : hint_range(2.0, 32.0) = 8.0;

// Optional: tweak if the image is too dark or bright
uniform float brightness : hint_range(0.0, 2.0) = 1.0;

void fragment() {
    // 1. Pixelate the UV coordinates
    vec2 tex_size = vec2(textureSize(TEXTURE, 0));
    vec2 pixelated_uv = floor(UV * tex_size / pixel_size) / (tex_size / pixel_size);
    
    // Read the image using our chunky coordinates
    vec4 tex_color = texture(TEXTURE, pixelated_uv);
    
    // 2. Posterize (Crunch the colors)
    // This forces the smooth gradients of a photo into harsh, retro color bands
    tex_color.rgb = floor(tex_color.rgb * color_crunch + 0.5) / color_crunch;
    
    // 3. Apply Brightness
    tex_color.rgb *= brightness;
    
    COLOR = tex_color;
}