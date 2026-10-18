shader_type canvas_item;
render_mode unshaded;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
void fragment() {
 float mask = texture(TEXTURE, UV).a;
 vec3 background = texture(screen_texture, SCREEN_UV).rgb;
 COLOR = vec4(vec3(1.0) - background, mask);
}
