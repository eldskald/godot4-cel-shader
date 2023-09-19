shader_type spatial;

#define USE_ALPHA 0
#define USE_ALPHA_CUTOFF 0
#define USE_EMISSION 0
#define USE_REFLECTIONS 0
#define USE_NORMAL_MAP 0
#define USE_OCCLUSION 0
#define USE_ANISOTROPY 0
#define USE_BACKLIGHT 0
#define USE_REFRACTION 0

#if USE_ALPHA
render_mode depth_draw_always;
#endif

#include "includes/base-cel-shader.gdshaderinc"

#if USE_EMISSION
#include "includes/emission.gdshaderinc"
#endif

#if USE_REFLECTIONS
#include "includes/reflections.gdshaderinc"
#endif

#if USE_NORMAL_MAP
#include "includes/normal-map.gdshaderinc"
#endif

#if USE_OCCLUSION
#include "includes/occlusion.gdshaderinc"
#endif

#if USE_ANISOTROPY
#include "includes/anisotropy.gdshaderinc"
#endif

#if USE_BACKLIGHT
#include "includes/backlight.gdshaderinc"
#endif

#if USE_REFRACTION
#include "includes/refraction.gdshaderinc"
#elif !USE_REFRACTION && USE_ALPHA
#include "includes/transparency.gdshaderinc"
#endif

group_uniforms BaseProperties;
#if USE_ALPHA_CUTOFF
uniform float alpha_cutoff: hint_range(0.0, 1.0) = 0.5;
#endif
uniform vec4 color: source_color = vec4(0.7, 0.12, 0.86, 1.0);
uniform sampler2D base_texture: source_color;
uniform vec4 specular: source_color = vec4(0.3, 0.3, 0.3, 0.5);
uniform sampler2D specular_texture: hint_default_white;
uniform vec4 fresnel: source_color = vec4(0.2, 0.2, 0.2, 0.3);
uniform sampler2D fresnel_texture: hint_default_white;
group_uniforms;

varying vec3 SPECULAR_COLOR;
varying float SPECULAR_STRENGTH;
varying vec3 FRESNEL_COLOR;
varying float FRESNEL_STRENGTH;

group_uniforms Tiling;
uniform vec2 uv_scale = vec2(1,1);
uniform vec2 uv_offset = vec2(0,0);
group_uniforms;


void vertex() {
	UV = UV * uv_scale.xy + uv_offset.xy;
}

void fragment() {
	ALBEDO = color.rgb * texture(base_texture, UV).rgb;
#if USE_ALPHA
	float alpha = color.a * texture(base_texture, UV).a;
	ALBEDO *= alpha;
#elif USE_ALPHA_CUTOFF
	ALPHA = color.a * texture(base_texture, UV).a;
	ALPHA_SCISSOR_THRESHOLD = color.a * texture(base_texture, UV).a;
#endif
	
#if USE_REFRACTION && USE_ALPHA
	EMISSION += refraction_fragment(alpha, NORMAL, SCREEN_UV, FRAGCOORD.z);
#elif !USE_REFRACTION && USE_ALPHA
	EMISSION += transparency_fragment(alpha, SCREEN_UV);
#endif
	
	SPECULAR_COLOR = specular.rgb * texture(specular_texture, UV).rgb;
	SPECULAR_STRENGTH = specular.a * texture(specular_texture, UV).a;
	FRESNEL_COLOR = fresnel.rgb * texture(fresnel_texture, UV).rgb;
	FRESNEL_STRENGTH = fresnel.a * texture(fresnel_texture, UV).a;
	
#if USE_EMISSION
	EMISSION += emission_fragment(UV);
#endif
	
#if USE_REFLECTIONS
	Surface surf = reflections_fragment(UV);
	METALLIC = surf.metallic;
	ROUGHNESS = surf.roughness;
#endif
	
#if USE_NORMAL_MAP
	NormalData normal = normal_map_fragment(UV, NORMAL, TANGENT, BINORMAL);
	NORMAL = normal.vector;
	NORMAL_MAP = normal.map;
	NORMAL_MAP_DEPTH = normal.depth;
#endif
	
#if USE_OCCLUSION
	OcclusionData occlusion = occlusion_fragment(UV);
	AO = occlusion.ao;
	AO_LIGHT_AFFECT = occlusion.ao_light_affect;
#endif
	
#if USE_ANISOTROPY
	AnisotropyData aniso = anisotropy_fragment(UV);
	ANISOTROPY_DIR = aniso.direction;
	ANISOTROPY_RATIO = aniso.ratio;
#endif
	
#if USE_BACKLIGHT
	BACKLIGHT = backlight_fragment(UV);
#endif
}

void light() {
#if USE_BACKLIGHT
	DIFFUSE_LIGHT += backlight_diffuse(
			ALBEDO,
			LIGHT_COLOR,
			LIGHT,
			NORMAL,
			ATTENUATION,
			BACKLIGHT
	);
#else
	DIFFUSE_LIGHT += diffuse_light(
			ALBEDO,
			LIGHT_COLOR,
			LIGHT,
			NORMAL,
			ATTENUATION
	);
#endif
	
#if USE_ANISOTROPY
	SPECULAR_LIGHT += anisotropy_specular(
			LIGHT_COLOR,
			SPECULAR_COLOR,
			SPECULAR_STRENGTH,
			NORMAL,
			VIEW,
			LIGHT,
			ATTENUATION,
			UV,
			ANISOTROPY_DIR,
			ANISOTROPY_RATIO
	);
#else
	SPECULAR_LIGHT += specular_light(
			LIGHT_COLOR,
			SPECULAR_COLOR,
			SPECULAR_STRENGTH,
			NORMAL,
			VIEW,
			LIGHT,
			ATTENUATION
	);
#endif

	SPECULAR_LIGHT += fresnel_light(
			LIGHT_COLOR,
			FRESNEL_COLOR,
			FRESNEL_STRENGTH,
			NORMAL,
			VIEW,
			LIGHT,
			ATTENUATION
	);
}
