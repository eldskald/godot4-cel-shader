#include "base-cel-shader.gdshaderinc"

group_uniforms Anisotropy;
uniform float anisotropy_ratio: hint_range(-1,1) = 0.0;
uniform vec3 anisotropy_direction = vec3(0.0, -1.0, 0.0);
uniform float aniso_map_dir_ratio: hint_range(0,1) = 0.0;
uniform sampler2D anisotropy_flowmap: hint_anisotropy;
group_uniforms;

varying vec3 ANISOTROPY_DIR;
varying float ANISOTROPY_RATIO;

struct AnisotropyData {
	vec3 direction;
	float ratio;
};

AnisotropyData anisotropy_fragment(vec2 uv) {
	return AnisotropyData(
			mix(
					normalize(anisotropy_direction),
					texture(anisotropy_flowmap, uv).rgb * 2.0 - 1.0,
					aniso_map_dir_ratio
			),
			anisotropy_ratio * texture(anisotropy_flowmap, uv).a
	);
}

vec3 anisotropy_specular(
		vec3 light_color,
		vec3 specular_color,
		float specular_amount,
		vec3 normal,
		vec3 view,
		vec3 light,
		float attenuation,
		vec2 uv,
		vec3 aniso_dir,
		float aniso_ratio
) {
	vec3 half = normalize(view + light);
	float aniso = max(0, sin(dot(normalize(normal + aniso_dir), half) * PI));
	float spec = mix(dot(normal, half), aniso, aniso_ratio);
	float spec_gloss = pow(2.0, 8.0 * (1.0 - specular_amount));
	float spec_intensity = smoothstep(
			0.05,
			0.05 + specular_smoothness,
			pow(spec, spec_gloss * spec_gloss)
	);
	return light_color
			* specular_color
			* spec_intensity
			* is_lit(light, normal, attenuation);
}
