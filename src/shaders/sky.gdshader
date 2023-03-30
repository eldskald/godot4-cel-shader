shader_type sky;
render_mode use_half_res_pass;

uniform sampler2D source_panorama : filter_linear, source_color, hint_default_black;
uniform bool add_clouds = true;
uniform bool clouds_below = false;
uniform float cloud_scale : hint_range(0.0, 1.0, 0.01) = 0.25;
uniform float speed : hint_range(0.0, 0.25, 0.001) = 0.002;
uniform float cloud_dark : hint_range(0.0, 1.0, 0.01) = 0.5;
uniform float cloud_light : hint_range(0.0, 1.0, 0.01) = 0.3;
uniform float cloud_cover : hint_range(0.0, 1.0, 0.01) = 0.2;
uniform float cloud_alpha : hint_range(0.0, 10.0, 0.01) = 8.0;
uniform float sky_tint : hint_range(0.0, 1.0, 0.001) = 0.5;
uniform float height_offset : hint_range(0.0, 1.0, 0.001) = 0.2;
uniform float sky_contribution : hint_range(0.0, 1.0, 0.1) = 0.5;

const mat2 m = mat2(vec2( 1.6, 1.2), vec2(-1.2, 1.6));

vec2 hash( vec2 p ) {
	p = vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)));
	return -1.0 + 2.0 * fract(sin(p) * 43758.5453123);
}

float noise( in vec2 p ) {
	const float K1 = 0.366025404; // (sqrt(3)-1)/2;
	const float K2 = 0.211324865; // (3-sqrt(3))/6;
	vec2 i = floor(p + (p.x + p.y)*K1);
	vec2 a = p - i + (i.x + i.y) * K2;
	vec2 o = (a.x > a.y) ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
	vec2 b = a - o + K2;
	vec2 c = a - 1.0 + 2.0 * K2;
	vec3 h = max(0.5 - vec3(dot(a, a), dot(b, b), dot(c, c)), 0.0 );
	vec3 n = h * h * h * h * vec3(
			dot(a, hash(i + 0.0)),
			dot(b, hash(i + o)),
			dot(c, hash(i + 1.0))
	);
	return dot(n, vec3(70.0));
}

float fbm(vec2 n) {
	float total = 0.0, amplitude = 0.1;
	for (int i = 0; i < 7; i++) {
		total += noise(n) * amplitude;
		n = m * n;
		amplitude *= 0.4;
	}
	return total;
}

void sky() {
	COLOR = texture(source_panorama, SKY_COORDS).rgb;
	if(AT_CUBEMAP_PASS){
		COLOR *= sky_contribution;
    }else if(add_clouds){
		vec3 normal = normalize(EYEDIR);
		vec3 plane_intersect = normal / (normal.y + height_offset);
		
		if(clouds_below){
			plane_intersect = normal / -(normal.y - height_offset);
		}
		
		vec2 p = plane_intersect.xz;
		p.y *= -1.0;
		vec2 uv = p;
		
		float time = TIME * speed;
		float q = fbm(uv * cloud_scale * 0.5);
		
		//ridged noise shape
		float r = 0.0;
		uv *= cloud_scale;
		uv -= q - time;
		float weight = 0.8;
		for(int i = 0; i < 8; i++){
			r += abs(weight*noise( uv ));
			uv = m*uv + time;
			weight *= 0.7;
		}
		
		//noise shape
		float f = 0.0;
		uv = p;
		uv *= cloud_scale;
		uv -= q - time;
		weight = 0.7;
		for(int i = 0; i < 8; i++){
			f += weight*noise( uv );
			uv = m*uv + time;
			weight *= 0.6;
		}
		
		f *= r + f;
		
		//noise colour
		float c = 0.0;
		time = TIME * speed * 2.0;
		uv = p;
		uv *= cloud_scale * 2.0;
		uv -= q - time;
		weight = 0.4;
		for(int i = 0; i < 7; i++){
			c += weight*noise( uv );
			uv = m*uv + time;
			weight *= 0.6;
		}
		
		//noise ridge colour
		float c1 = 0.0;
		time = TIME * speed * 3.0;
		uv = p;
		uv *= cloud_scale * 3.0;
		uv -= q - time;
		weight = 0.4;
		for (int i = 0; i < 7; i++){
			c1 += abs(weight * noise( uv ));
			uv = m * uv + time;
			weight *= 0.6;
		}
		
		c += c1;
		
		vec3 skycolour = COLOR;
		vec3 cloudcolour = vec3(1.1, 1.1, 0.9) * clamp(
				(cloud_dark + cloud_light * c),
				0.0,
				1.0
		);
		float horizon_fall_off = max(normal.y, 0.0);
		
		if(clouds_below){
			horizon_fall_off = max(-normal.y, 0.0);
		}
		
		f = cloud_cover + cloud_alpha * f * r;
		
		vec3 result = mix(
				skycolour,
				clamp(sky_tint * skycolour + cloudcolour, 0.0, 1.0),
				clamp(f + c, 0.0, 1.0) * horizon_fall_off
		);
		
		// Convert the color to black and white.
		COLOR = vec3((result.r + result.g + result.b) / 3.0);
	}
}