shader_type spatial;

render_mode cull_disabled, unshaded;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear;
uniform sampler2D overlay_tex;
uniform float alpha_value = 0.3;

void fragment() {
	ALBEDO = texture(SCREEN_TEXTURE, vec2(FRAGCOORD.x, FRAGCOORD.y) / VIEWPORT_SIZE).xyz;
	ALBEDO.r *= 1.5;
	ALBEDO.g *= 1.5;
	ALBEDO.b *= 1.5;
    vec2 screen_uv = (FRAGCOORD.xy / VIEWPORT_SIZE.xy);
	screen_uv.x += TIME * 1.94;
	screen_uv.y += sin(TIME * 7.4);
	vec3 overlay = texture(overlay_tex, screen_uv).rgb;
	ALBEDO.r += overlay.r * 3.0;
	ALBEDO.g += overlay.g * 3.0;
	ALBEDO.b += overlay.b * 3.0;
	ALPHA = alpha_value;
}
