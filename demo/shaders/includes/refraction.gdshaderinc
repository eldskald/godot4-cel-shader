group_uniforms Refraction;
uniform float refraction : hint_range(-16, 16) = 0.05;
uniform float blurriness : hint_range(0.0, 1.0) = 0.0;
group_uniforms;

uniform sampler2D screen_texture :
		hint_screen_texture,
		repeat_disable,
		filter_linear_mipmap;

uniform sampler2D depth_texture :
		hint_depth_texture,
		repeat_disable,
		filter_linear_mipmap;

vec3 refraction_fragment(
		float alpha,
		vec3 normal,
		vec2 screen_uv,
		float depth
) {
	float amount = 1.0 - alpha;
	vec2 offset = screen_uv - normal.xy * refraction;
	float image_depth = texture(depth_texture, offset).r;
	return image_depth < depth
			? textureLod(
					screen_texture,
					screen_uv,
					blurriness * 8.0
			).rgb * amount
			: textureLod(
					screen_texture,
					offset,
					blurriness * 8.0
			).rgb * amount;
}
