group_uniforms NormalMap;
uniform float normal_scale : hint_range(-16,16) = 1.0;
uniform sampler2D normal_map : hint_normal;
group_uniforms;

struct NormalData {
	vec3 vector;
	vec3 map;
	float depth;
};

NormalData normal_map_fragment(
		vec2 uv,
		vec3 normal,
		vec3 tangent,
		vec3 binormal,
) {
	vec3 map = texture(normal_map, uv).rgb;
	vec3 vector = map;
	vector.xy = vector.xy * 2.0 - 1.0;
	vector.z = sqrt(max(0.0, 1.0 - dot(vector.xy, vector.xy)));
	vec3 ref_normal = normalize(mix(
			normal,
			tangent * vector.x + binormal * vector.y + normal * vector.z,
			normal_scale
	));
	return NormalData(vector, map, normal_scale);
}
