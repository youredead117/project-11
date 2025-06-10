shader_type spatial;
render_mode unshaded, depth_test_disabled, blend_mix, cull_disabled, depth_prepass_alpha;


uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear;
uniform sampler2D gradient_red;
uniform sampler2D gradient_green;
uniform sampler2D gradient_blue;

uniform int moblur_iterations = 20;
uniform sampler2D depth : hint_depth_texture, filter_linear_mipmap;
uniform sampler2D motion_vec_vp : filter_nearest;

uniform float darker = 1.0;

uniform vec2 uv_test;

void fragment() {
	ALBEDO = texture(SCREEN_TEXTURE, vec2(FRAGCOORD.x, FRAGCOORD.y) / VIEWPORT_SIZE).xyz;
	vec3 movec_color = texture(motion_vec_vp, vec2(FRAGCOORD.x, FRAGCOORD.y) / (VIEWPORT_SIZE * vec2(2.0, 2.0))).rgb;
	vec3 movec_color_test = texture(motion_vec_vp, uv_test).rgb;
	ALBEDO = movec_color;
	//ALBEDO *= movec_color_test;
	if (ALBEDO.r <= 1.0 && ALBEDO.g <= 1.0 && ALBEDO.b <= 1.0){
		ALBEDO.r *= texture(gradient_red, vec2(clamp(ALBEDO.r, 0.0, 1.0), 0.0)).r;
		ALBEDO.g *= texture(gradient_green, vec2(clamp(ALBEDO.g, 0.0, 1.0), 0.0)).g;
		ALBEDO.b *= texture(gradient_blue, vec2(clamp(ALBEDO.b, 0.0, 1.0), 0.0)).b;
	}
	ALBEDO -= vec3(darker, darker, darker);
}