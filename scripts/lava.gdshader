shader_type spatial;

uniform sampler2D noise_tex;
uniform sampler2D color_ramp;
uniform float spike_height = 4.0;
uniform float spike_sharpness = 8.0; // Higher number = fewer, sharper spikes
uniform vec2 flow_speed = vec2(0.05, 0.05);
uniform float emission_energy = 3.0;

void vertex() {
	// 1. Calculate moving UVs (replaces your old GDScript!)
	vec2 moving_uv = UV + (TIME * flow_speed);
	
	// 2. Read the noise texture
	float noise_val = texture(noise_tex, moving_uv).r;
	
	// 3. MATH MAGIC: pow() flattens the bottom of the noise and sharpens the peaks
	float spike = pow(noise_val, spike_sharpness);
	
	// 4. Push the geometry upwards
	VERTEX.y += spike * spike_height;
}

void fragment() {
	// Same moving UVs for the color
	vec2 moving_uv = UV + (TIME * flow_speed);
	float noise_val = texture(noise_tex, moving_uv).r;
	
	// Apply your custom gradient colors and make it glow
	vec3 color = texture(color_ramp, vec2(noise_val, 0.0)).rgb;
	ALBEDO = color;
	EMISSION = color * emission_energy;
}