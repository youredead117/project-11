shader_type spatial;

render_mode unshaded;

uniform sampler2D hud_viewport;

void fragment() {
	vec4 hud_tex = texture(hud_viewport, UV);
	ALBEDO.r += hud_tex.r;
	ALBEDO.g += hud_tex.g;
	ALBEDO.b += hud_tex.b;
	//ALPHA = 1.0 - ((ALBEDO.r + ALBEDO.g + ALBEDO.b) / 3.0);
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
