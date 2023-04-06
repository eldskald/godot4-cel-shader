group_uniforms Occlusion;
uniform float ao_light_affect: hint_range(0,1) = 0.0;
uniform sampler2D ao_map : hint_default_white;
group_uniforms;

struct OcclusionData {
	float ao;
	float ao_light_affect;
};

OcclusionData occlusion_fragment(vec2 uv) {
	return OcclusionData(
			texture(ao_map, uv).r,
			ao_light_affect
	);
}
