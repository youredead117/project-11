shader_type spatial;

render_mode cull_back;

uniform sampler2D noise_movement;

uniform sampler2D noise_colour;

uniform sampler2D normal_tex;

uniform float speed_scale;
uniform float speed_scale_big;

uniform float height;
uniform float height_big_noise;

uniform vec2 size_mesh;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;

float greyscale(vec3 col) {
	return (col.r + col.g + col.b) / 3.0;
}

void vertex() {
	//vec2 _uv = vec2(VERTEX.x + TIME * speed_scale, VERTEX.z + TIME * speed_scale);
	//vec2 _uv1 = vec2((VERTEX.x + TIME) * speed_scale_big, (VERTEX.z + TIME) * speed_scale_big);
	//VERTEX.y = (height * greyscale(texture(noise_movement, _uv).rgb)) + (height_big_noise * greyscale(texture(noise_movement, _uv1).rgb));
}

void fragment() {
	vec2 _uv = vec2((UV.x * size_mesh.x) + TIME * speed_scale, (UV.y * size_mesh.y) + TIME * speed_scale);
	float x_disp = (sin(UV.x * 3.0 + TIME));
	float y_disp = (sin(UV.y * 5.0 + TIME - 3.14));
	vec2 uv_2 = vec2(UV.x + TIME * 0.08, UV.y + TIME * 0.1);
	vec3 tex_movement = texture(noise_movement, uv_2).rgb;
	_uv.x += y_disp * y_disp / 7.0;
	_uv.y += x_disp * x_disp / 7.0;
	_uv.x += tex_movement.r / 4.5;
	_uv.y += tex_movement.g / 4.5;
	ROUGHNESS = 0.15;
	NORMAL_MAP = texture(normal_tex, uv_2).rgb;
	ALBEDO = texture(noise_colour, _uv).rgb;
	float ALPHA_ = 0.5;
}
