shader_type spatial;

uniform vec4 color: source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform sampler2D noise_texture: hint_default_black;
uniform float noise_scale = 1.0;
uniform vec2 noise_speed = vec2(0.0, 0.0);
uniform float softness: hint_range(0, 10) = 0;
uniform float fade_in: hint_range(0, 1) = 0.1;
uniform float fade_out: hint_range(0, 1) = 0.9;
uniform float near_fade = 1;
uniform float far_fade = 100;

uniform sampler2D DEPTH_TEX :
		hint_depth_texture,
		repeat_disable,
		filter_linear_mipmap;

varying float PHASE;
varying float SCALE;
varying vec2 RANDOM;

float random (vec2 st) {
	return fract(sin(dot(st.xy, vec2(12.9898,78.233))) * 43758.5453123);
}

float linearize(float depth, vec2 screen_uv, mat4 inv_proj_mat) {
	vec3 ndc = vec3(screen_uv * 2.0 - 1.0, depth);
	vec4 view = inv_proj_mat * vec4(ndc, 1.0);
	return -view.z / view.w;
}

void vertex() {
	PHASE = INSTANCE_CUSTOM.y;
	SCALE = INSTANCE_CUSTOM.x;
	RANDOM = vec2(random(vec2(float(INSTANCE_ID))), INSTANCE_CUSTOM.z);
	
	// Billboard mode
	mat4 mat_world = mat4(
			normalize(INV_VIEW_MATRIX[0]),
			normalize(INV_VIEW_MATRIX[1]),
			normalize(INV_VIEW_MATRIX[2]),
			MODEL_MATRIX[3]
	);
	mat_world = mat_world * mat4(
			vec4(INSTANCE_CUSTOM.x, 0.0, 0.0, 0.0),
			vec4(0.0, INSTANCE_CUSTOM.x, 0.0, 0.0),
			vec4(0.0, 0.0, INSTANCE_CUSTOM.x, 0.0),
			vec4(0.0, 0.0, 0.0, 1.0)
	);
	MODELVIEW_MATRIX = VIEW_MATRIX * mat_world;
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
}

void fragment() {
	float radius = length(UV * 2.0 - vec2(1.0));
	float mask = clamp(1.0 - smoothstep(0.0, 1.0, radius), 0.0, 1.0);
	vec2 noise_uv = (UV + RANDOM) * SCALE / noise_scale + TIME * noise_speed;
	float noise = texture(noise_texture, noise_uv).x;
	
	ALBEDO = color.rgb * COLOR.rgb;
	ALPHA = COLOR.a * color.a * mask * noise;
	
	// Fade in and out based on particle lifetime
	ALPHA *= smoothstep(0, fade_in, PHASE);
	ALPHA *= 1.0 - smoothstep(fade_out, 1, PHASE);

	// Fade when too close to geometry (soft particles)
	float z_depth = texture(DEPTH_TEX, SCREEN_UV).x;
	z_depth = linearize(z_depth, SCREEN_UV, INV_PROJECTION_MATRIX);
	float z_pos = linearize(FRAGCOORD.z, SCREEN_UV, INV_PROJECTION_MATRIX);
	ALPHA *= smoothstep(0.0, softness, z_depth - z_pos);

	// Fade in and out based on camera distance
	ALPHA *= smoothstep(near_fade / 2.0, near_fade, z_pos);
	ALPHA *= 1.0 - smoothstep(far_fade, far_fade + near_fade, z_pos);
}

void light() {
	DIFFUSE_LIGHT = LIGHT_COLOR * ALBEDO;
}
