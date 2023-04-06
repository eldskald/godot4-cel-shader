group_uniforms Emission;
uniform vec4 emission : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float emission_energy = 1.0;
uniform sampler2D emission_texture : hint_default_black;
group_uniforms;

vec3 emission_fragment(vec2 uv) {
	return (emission.rgb + texture(emission_texture, uv).rgb) * emission_energy;
}
