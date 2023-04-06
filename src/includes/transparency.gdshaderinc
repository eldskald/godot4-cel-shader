uniform sampler2D screen_texture :
		hint_screen_texture,
		repeat_disable,
		filter_linear_mipmap;

vec3 transparency_fragment(float alpha, vec2 screen_uv) {
	return (1.0 - alpha) * texture(screen_texture, screen_uv).rgb;
}
