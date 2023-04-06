#include "base-cel-shader.gdshaderinc"

group_uniforms Backlight;
uniform vec3 backlight : source_color;
uniform sampler2D backlight_texture : hint_default_white;
group_uniforms;

vec3 backlight_fragment(vec2 uv) {
	return backlight * texture(backlight_texture, uv).rgb;
}

vec3 backlight_diffuse(
		vec3 albedo,
		vec3 light_color,
		vec3 light,
		vec3 normal,
		float attenuation,
		vec3 backlight_color
) {
	float value = diffuse_sample(light, normal);
	return albedo * light_color * attenuation
			* (value + backlight_color * (1.0 - value));
}
