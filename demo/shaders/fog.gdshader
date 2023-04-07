shader_type fog;

uniform float base_density: hint_range(0, 1) = 0.8;
uniform vec3 base_color: source_color;
uniform float fade_out_height = 2.0;
uniform float fade_out_distance = 1.5;
uniform vec3 noise_amounts = vec3(0.4, 0.35, 0.25); // should add up to 1
uniform vec3 noise_scales = vec3(1.0, 2.0, 4.0);
uniform vec3 noise_velocity1 = vec3(0.5, 0.0, 0.0);
uniform vec3 noise_velocity2 = vec3(1, 0.0, -1);
uniform vec3 noise_velocity3 = vec3(0.0, 0.6, 0.3);

vec3 hash(vec3 p) {
	p = vec3(
			dot(p,vec3(127.1,311.7, 74.7)),
			dot(p,vec3(269.5,183.3,246.1)),
			dot(p,vec3(113.5,271.9,124.6))
	);
	return -1.0 + 2.0 * fract(sin(p) * 43758.5453123);
}

float noise(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	vec3 u = f*f*(3.0-2.0*f);
    return mix( mix( mix( dot( hash( i + vec3(0.0,0.0,0.0) ), f - vec3(0.0,0.0,0.0) ), 
                          dot( hash( i + vec3(1.0,0.0,0.0) ), f - vec3(1.0,0.0,0.0) ), u.x),
                     mix( dot( hash( i + vec3(0.0,1.0,0.0) ), f - vec3(0.0,1.0,0.0) ), 
                          dot( hash( i + vec3(1.0,1.0,0.0) ), f - vec3(1.0,1.0,0.0) ), u.x), u.y),
                mix( mix( dot( hash( i + vec3(0.0,0.0,1.0) ), f - vec3(0.0,0.0,1.0) ), 
                          dot( hash( i + vec3(1.0,0.0,1.0) ), f - vec3(1.0,0.0,1.0) ), u.x),
                     mix( dot( hash( i + vec3(0.0,1.0,1.0) ), f - vec3(0.0,1.0,1.0) ), 
                          dot( hash( i + vec3(1.0,1.0,1.0) ), f - vec3(1.0,1.0,1.0) ), u.x), u.y), u.z );
}

void fog() {
	vec3 base_pos = WORLD_POSITION * vec3(0.1, 0.5, 0.1);
	DENSITY = base_density;
	float noise1 = noise_amounts.x * noise(
			base_pos * noise_scales.x + TIME * noise_velocity1
	);
	float noise2 = noise_amounts.y * noise(
			base_pos * noise_scales.y + TIME * noise_velocity2
	);
	float noise3 = noise_amounts.z * noise(
			base_pos * noise_scales.z + TIME * noise_velocity3
	);
	DENSITY *= smoothstep(-0.1, 0.0, noise1 + noise2 + noise3);
	DENSITY *= 1.0 - smoothstep(
			fade_out_height,
			fade_out_height + fade_out_distance,
			WORLD_POSITION.y
	);
	EMISSION = base_color;
}
