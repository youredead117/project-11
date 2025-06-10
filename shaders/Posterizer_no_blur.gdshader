shader_type spatial;
render_mode unshaded, depth_test_disabled, blend_mix, cull_disabled, depth_prepass_alpha;


uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear;
uniform sampler2D gradient_red;
uniform sampler2D gradient_green;
uniform sampler2D gradient_blue;

uniform sampler2D saved_frame;

void fragment() {
	ALBEDO = texture(SCREEN_TEXTURE, vec2(FRAGCOORD.x, FRAGCOORD.y) / VIEWPORT_SIZE).xyz;
	ALPHA = texture(SCREEN_TEXTURE, vec2(FRAGCOORD.x, FRAGCOORD.y) / VIEWPORT_SIZE).a;
    if (ALPHA < 0.1) {
        discard;
    }
    vec2 screen_uv = (FRAGCOORD.xy / VIEWPORT_SIZE.xy);

	float dist = length((screen_uv - vec2(0.5, 0.5)) * vec2(abs(sin(TIME * 1.6) / 2.0) + 0.5, abs(cos(TIME * 1.3) / 2.0) + 0.5)) * 10.0;

	float rawdist = length((screen_uv - vec2(0.5, 0.5)));

	vec2 final_uv = ((screen_uv - vec2(0.5, 0.5)) / vec2(dist, dist)) + vec2(0.5, 0.5);
	final_uv.x = clamp(final_uv.x, 0.0, 1.0);
	final_uv.y = clamp(final_uv.y, 0.0, 1.0);
	if (ALBEDO.r <= 1.0 && ALBEDO.g <= 1.0 && ALBEDO.b <= 1.0){
		ALBEDO.r *= texture(gradient_red, vec2(clamp(ALBEDO.r, 0.0, 1.0), 0.0)).r;
		ALBEDO.g *= texture(gradient_green, vec2(clamp(ALBEDO.g, 0.0, 1.0), 0.0)).g;
		ALBEDO.b *= texture(gradient_blue, vec2(clamp(ALBEDO.b, 0.0, 1.0), 0.0)).b;
	}
	//ALBEDO = texture(depth, screen_uv).rgb;
	//ALBEDO = moblur_noise_value.rgb * moblur_noise_mask_value;
}