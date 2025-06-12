shader_type spatial;
render_mode unshaded, depth_test_disabled, blend_mix, cull_disabled, depth_prepass_alpha;


uniform sampler2D SCREEN_TEXTURE;
uniform sampler2D gradient_red_3;
uniform sampler2D gradient_green_3;
uniform sampler2D gradient_blue_3;
uniform sampler2D hud_viewport : filter_nearest;
uniform float darker = 0.0;

void fragment() {
	ALBEDO = texture(SCREEN_TEXTURE, vec2(FRAGCOORD.x, FRAGCOORD.y) / VIEWPORT_SIZE).xyz;
	float div = darker;
	if (ALBEDO.r <= 1.0){
		ALBEDO.r *= texture(gradient_red_3, vec2(clamp(ALBEDO.r * ALBEDO.r / div, 0.0, 1.0), 0.0)).r;
		}
	if (ALBEDO.g <= 1.0){
		ALBEDO.g *= texture(gradient_green_3, vec2(clamp(ALBEDO.g * ALBEDO.g / div, 0.0, 1.0), 0.0)).g;
	}
	if (ALBEDO.b <= 1.0){
		ALBEDO.b *= texture(gradient_blue_3, vec2(clamp(ALBEDO.b * ALBEDO.b / div, 0.0, 1.0), 0.0)).b;
		}
	ALBEDO.r = clamp(ALBEDO.r * div, 0.0, 1.0);
	ALBEDO.g = clamp(ALBEDO.g * div, 0.0, 1.0);
	ALBEDO.b = clamp(ALBEDO.b * div, 0.0, 1.0);

	vec4 hud_tex = texture(hud_viewport, vec2(FRAGCOORD.x, FRAGCOORD.y) / VIEWPORT_SIZE);
	ALBEDO.r += hud_tex.r * 0.8;
	ALBEDO.g += hud_tex.g;
	ALBEDO.b += hud_tex.b;
	ALPHA = texture(SCREEN_TEXTURE, vec2(FRAGCOORD.x, FRAGCOORD.y) / VIEWPORT_SIZE).a;
	ALPHA += (ALBEDO.r + clamp(ALBEDO.g, 0.0, 1.0) + clamp(ALBEDO.b, 0.0, 1.0)) / 3.0;
	//ALPHA *= ALPHA * ALPHA * 6.0;
	ALPHA = clamp(ALPHA, 0.0, 1.0);
}