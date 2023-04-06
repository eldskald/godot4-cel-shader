shader_type particles;

uniform vec4 color: source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float initial_linear_velocity_min;
uniform float initial_linear_velocity_max;
uniform float scale_min;
uniform float scale_max;
uniform float lifetime_randomness;
uniform vec3 emission_box_extents;

float rand_from_seed(inout uint seed) {
	int k;
	int s = int(seed);
	if (s == 0)
	s = 305420679;
	k = s / 127773;
	s = 16807 * (s - k * 127773) - 2836 * k;
	if (s < 0)
		s += 2147483647;
	seed = uint(s);
	return float(seed % uint(65536)) / 65535.0;
}

float rand_from_seed_m1_p1(inout uint seed) {
	return rand_from_seed(seed) * 2.0 - 1.0;
}

uint hash(uint x) {
	x = ((x >> uint(16)) ^ x) * uint(73244475);
	x = ((x >> uint(16)) ^ x) * uint(73244475);
	x = (x >> uint(16)) ^ x;
	return x;
}

void start() {
	uint alt_seed = hash(NUMBER + uint(1) + RANDOM_SEED);
	float scale_rand = rand_from_seed(alt_seed);
	if (RESTART_VELOCITY) {
		vec3 direction = normalize(vec3(
				rand_from_seed_m1_p1(alt_seed),
				rand_from_seed_m1_p1(alt_seed),
				rand_from_seed_m1_p1(alt_seed)
		));
		VELOCITY = direction * mix(
			initial_linear_velocity_min,
			initial_linear_velocity_max,
			rand_from_seed(alt_seed)
		);
	}
	COLOR = color;
	CUSTOM.x = scale_min + (scale_max - scale_min) * scale_rand;
	CUSTOM.y = 0.0;
	CUSTOM.w = (1.0 - lifetime_randomness * rand_from_seed(alt_seed));
	CUSTOM.z = rand_from_seed(alt_seed);
	if (RESTART_POSITION) {
		TRANSFORM[3].xyz = emission_box_extents * vec3(
				rand_from_seed_m1_p1(alt_seed),
				rand_from_seed_m1_p1(alt_seed),
				rand_from_seed_m1_p1(alt_seed)
		);
		if (RESTART_VELOCITY) {
			VELOCITY = (EMISSION_TRANSFORM * vec4(VELOCITY, 0.0)).xyz;
		}
		TRANSFORM = EMISSION_TRANSFORM * TRANSFORM;
	}
}

void process() {
	TRANSFORM[0].xyz = normalize(TRANSFORM[0].xyz) * CUSTOM.x;
	TRANSFORM[1].xyz = normalize(TRANSFORM[1].xyz) * CUSTOM.x;
	TRANSFORM[2].xyz = normalize(TRANSFORM[2].xyz) * CUSTOM.x;
	CUSTOM.y += DELTA / LIFETIME / CUSTOM.w;
	if (CUSTOM.y > 1.0) {
		ACTIVE = false;
	}
}
