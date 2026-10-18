shader_type canvas_item;
render_mode unshaded;

// Sample the original generated atlas on a coarse, hard-edged pixel grid.
// Source PNGs remain intact; this is a runtime rendering choice.
uniform float source_pixel_step = 8.0;
uniform float flatten_strength = 0.0;
varying vec4 canvas_tint;

void vertex() {
	canvas_tint = COLOR;
}

void fragment() {
	vec2 pixels = vec2(textureSize(TEXTURE, 0));
	vec2 sample_at = (floor(UV * pixels / source_pixel_step) + 0.5) * source_pixel_step / pixels;
	vec4 texel = texture(TEXTURE, sample_at);
	texel.rgb = mix(texel.rgb, vec3(0.08, 0.065, 0.075), flatten_strength);
	texel.a = step(0.5, texel.a);
	COLOR = texel * canvas_tint;
}
