group_uniforms Reflections;
uniform float metallic : hint_range(0,1) = 0.0;
uniform float roughness : hint_range(0,1) = 1.0;
uniform sampler2D texture_surface : hint_default_white;
group_uniforms;

struct Surface {
	float metallic;
	float roughness;
};

Surface reflections_fragment(vec2 uv) {
	return Surface(
		metallic * texture(texture_surface, uv).r,
		roughness * texture(texture_surface, uv).g
	);
}
