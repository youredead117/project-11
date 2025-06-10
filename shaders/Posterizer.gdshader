shader_type spatial;
render_mode unshaded, depth_test_disabled, blend_mix, cull_disabled, alpha_to_coverage;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear;
uniform sampler2D gradient_red;
uniform sampler2D gradient_green;
uniform sampler2D gradient_blue;
uniform sampler2D gradient_dead_2;

uniform int moblur_iterations = 20;
uniform float straight_speed = 0.0;
uniform float side_speed = 0.0;
uniform float vertical_speed = 0.0;

uniform sampler2D moblur_noise;
uniform sampler2D moblur_noise_up;
uniform sampler2D moblur_noise_side;
uniform sampler2D moblur_noise_mask;
uniform sampler2D moblur_noise_mask_2;
uniform sampler2D depth : hint_depth_texture, filter_linear_mipmap;

uniform float darker = 1.0;

uniform bool dead = false;

float get_sign(float x) {
	return x < 0.0 ? -1.0 : 1.0;
}

float cbrt(float x) {
    return sign(x) * pow(abs(x), 1.0 / 3.0);
}

float grayscale(vec3 col) {
	return (col.r + col.g + col.b) / 3.0;
}

bool within_uv(vec2 uv_) {
	return uv_.x < 1.0 && uv_.x > 0.0 && uv_.y < 1.0 && uv_.y > 0.0;
}

void fragment() {
	vec2 screen_uv = FRAGCOORD.xy / VIEWPORT_SIZE.xy;
	vec3 base_color = texture(SCREEN_TEXTURE, screen_uv).rgb;
	ALBEDO = base_color;
	
	if (!dead){
		// Distance modulation (time-based radial distortion)
		vec2 screen_center = vec2(0.5);
		float time1 = abs(sin(TIME * 1.6)) * 0.5 + 0.5;
		float time2 = abs(cos(TIME * 1.3)) * 0.5 + 0.5;
		float dist = 1.0 / (length((screen_uv - screen_center) * vec2(time1, time2)) * 10.0);

		time1 = abs(sin(TIME * 1.2)) * 0.5 + 0.5;
		time2 = abs(cos(TIME * 0.9)) * 0.5 + 0.5;
		float dist_2 = 1.0 / (length((screen_uv - screen_center) * vec2(time1, time2)) * 10.0);

		float rawdist = length(screen_uv - screen_center);

		vec2 final_uv = (screen_uv - screen_center) / dist + screen_center;
		final_uv = clamp(final_uv, vec2(0.0), vec2(1.0));

		vec2 final_uv_2 = (screen_uv - screen_center) / dist_2 + screen_center;
		final_uv_2 = clamp(final_uv_2, vec2(0.0), vec2(1.0));

		// Sample noise/mask textures
		float noise_val      = texture(moblur_noise, final_uv).r;
		float noise_up_val   = texture(moblur_noise_up, final_uv).r;
		float noise_side_val = texture(moblur_noise_side, final_uv).r;
		float mask_val       = texture(moblur_noise_mask, vec2(rawdist, 0.0)).r;
		float mask_val_2     = texture(moblur_noise_mask_2, vec2(rawdist, 0.0)).r;
		float mask_val_3     = texture(moblur_noise_mask_2, vec2(0.0, rawdist)).r;

		float depth_val = texture(depth, screen_uv).r;
		float depth_mult = sqrt(depth_val) * 100.0;

		float acc = 1.0;

		// Radial motion blur (forward/backward)
		for (int i = 0; i <= moblur_iterations; i++) {
			float mult = 0.01 * straight_speed * mask_val * depth_mult * sqrt(grayscale(ALBEDO));
			acc += mult;

			float i_sq = float(i);
			float fade = i_sq * 0.2 / 40.0;
			float enlarge = 1.0 - fade * noise_val / (0.05 / mult);

			vec2 from_center = FRAGCOORD.xy - (VIEWPORT_SIZE * 0.5);
			vec2 offset_uv = (from_center * enlarge + VIEWPORT_SIZE * 0.5) / VIEWPORT_SIZE;
			
			if (within_uv(offset_uv)){
				ALBEDO += texture(SCREEN_TEXTURE, offset_uv).rgb * mult;
			}
		}

		// Side and vertical motion blur
		for (int i = 0; i <= moblur_iterations; i++) {
			float mult_x = 0.1 * side_speed * depth_mult * sqrt(grayscale(ALBEDO)) * mask_val_2;
			float mult_y = 0.1 * vertical_speed * depth_mult * sqrt(grayscale(ALBEDO)) * mask_val_3;
			float mult_avg = (abs(mult_x) + abs(mult_y)) * 0.5;
			acc += mult_avg;

			float enlargex = 1.0 - float(i) / (0.1 / mult_x);
			float enlargey = 1.0 - float(i) / (0.1 / mult_y);

			vec2 from_center = FRAGCOORD.xy - (VIEWPORT_SIZE * 0.5);
			vec2 from_center_uv = from_center / VIEWPORT_SIZE;

			if (screen_uv.x <= 0.5) enlargex *= -1.0;
			if (screen_uv.y <= 0.5) enlargey *= -1.0;

			vec2 offset = from_center + vec2(
				enlargex * get_sign(from_center_uv.x),
				enlargey * get_sign(from_center_uv.y)
			) / clamp(length(from_center), 0.05, 1.0);

			vec2 offset_uv = (offset + VIEWPORT_SIZE * 0.5) / VIEWPORT_SIZE;
			
			if (within_uv(offset_uv)){
				ALBEDO += texture(SCREEN_TEXTURE, offset_uv).rgb * mult_avg;
			}
		}

		// Normalize accumulated color
		acc *= 0.6;
		ALBEDO /= vec3(acc);
	}
	// Apply gradient color mapping
	if (all(lessThanEqual(ALBEDO.rgb, vec3(1.0)))) {
		ALBEDO.r *= texture(gradient_red,   vec2(clamp(ALBEDO.r, 0.0, 1.0), 0.0)).r;
		ALBEDO.g *= texture(gradient_green, vec2(clamp(ALBEDO.g, 0.0, 1.0), 0.0)).g;
		ALBEDO.b *= texture(gradient_blue,  vec2(clamp(ALBEDO.b, 0.0, 1.0), 0.0)).b;
	}
	if (dead){
		float gray = clamp(grayscale(ALBEDO * 1.6 + 0.15 + vec3(0.1)), 0.0, 1.0);
		ALBEDO.r = gray;
		ALBEDO.g = gray;
		ALBEDO.b = gray;
		ALBEDO *= texture(gradient_dead_2, vec2(gray)).rgb;
	}
	// Final darkening
	ALBEDO -= vec3(darker);
	
	//depth debugging
	//ALBEDO = vec3(0.0, 0.0, 0.0);
	//ALBEDO.r = depth_mult;
}
