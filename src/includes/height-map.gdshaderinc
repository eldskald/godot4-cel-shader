group_uniforms HeightMap;
uniform float height_scale: hint_range(-16.0, 16.0) = 5.0;
uniform int min_layers = 8;
uniform int max_layers = 32;
uniform vec2 height_flip = vec2(1, 1);
uniform sampler2D height_map: hint_default_black, filter_linear, repeat_enable;
group_uniforms;

vec2 height_map_fragment(vec2 uv, vec3 vertex, vec3 tangent, vec3 binormal, vec3 normal) {
	vec2 base_uv = uv;
	{
		vec3 view_dir = normalize(normalize(-vertex) * mat3(tangent * height_flip.x, -binormal * height_flip.y, normal));
		float num_layers = mix(float(max_layers),float(min_layers), abs(dot(vec3(0.0, 0.0, 1.0), view_dir)));
		float layer_depth = 1.0 / num_layers;
		vec2 P = view_dir.xy * height_scale * 0.01;
		vec2 delta = P / num_layers;
		vec2 ofs = base_uv;
		float depth = 1.0 - texture(height_map, ofs).r;
		float current_depth = 0.0;
		while(current_depth < depth) {
		    ofs -= delta;
		    depth = 1.0 - texture(height_map, ofs).r;
		    current_depth += layer_depth;
		}
		vec2 prev_ofs = ofs + delta;
		float after_depth  = depth - current_depth;
		float before_depth = (1.0 - texture(height_map, prev_ofs).r  ) - current_depth + layer_depth;
		float weight = after_depth / (after_depth - before_depth);
		ofs = mix(ofs,prev_ofs,weight);
		base_uv = ofs;
		return base_uv;
	}
}