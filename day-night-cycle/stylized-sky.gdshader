shader_type sky;
render_mode use_half_res_pass;

// Base Sky Settings
group_uniforms sky_base;

uniform vec3 bottom_color : source_color = vec3(0.5, 0.7, 1.0);
uniform vec3 night_sky_color : source_color = vec3(0.04, 0.07, 0.15);
uniform vec3 twilight_color : source_color = vec3(0.1, 0.1, 0.3); // Upper sky color during twilight

// Rayleigh Scattering
group_uniforms rayleigh;

uniform float rayleigh_strength : hint_range(0.0, 10.0, 0.1) = 2.0;
uniform float rayleigh_falloff : hint_range(1.0, 8.0, 0.1) = 4.0;
uniform vec3 rayleigh_coeff : source_color = vec3(0.5, 0.7, 1.0);
uniform float air_mass_shift : hint_range(0.0, 2.0, 0.01) = 1.0; // Controls atmospheric light extinction

// Sun
group_uniforms sun;

uniform vec3 sun_tint : source_color;
uniform sampler2D sun_sampler : repeat_disable, filter_linear_mipmap;
uniform float sun_scale : hint_range(0.1, 10.0, 0.1) = 1.0;
uniform float sun_intensity : hint_range(1.0, 3.0, 0.1) = 1.0;

// Sunset/Sunrise Settings
group_uniforms sunset;

uniform vec3 sunset_color : source_color = vec3(1.0, 0.45, 0.15);
uniform float sunset_intensity : hint_range(0.0, 2.0, 0.01) = 1.0;
uniform float sunset_width : hint_range(0.01, 0.5, 0.01) = 0.08; // Duration of sunset/sunrise
uniform float sunset_view_width : hint_range(0.01, 1.0, 0.01) = 0.25; // Angular width of sunset glow
uniform float sunset_offset : hint_range(-0.5, 0.5, 0.01) = 0.0; // Timing offset for sunset

// Time of Day Transitions
group_uniforms time_transitions;

uniform float night_transition_width : hint_range(0.01, 0.25, 0.01) = 0.12;

// Moon
group_uniforms moon;

uniform vec3 moon_tint : source_color;
uniform sampler2D moon_sampler : repeat_disable, filter_linear_mipmap;
uniform float moon_scale : hint_range(0.1, 10.0, 0.1) = 1.0;
uniform float moon_intensity : hint_range(1.0, 3.0, 0.1) = 1.0;

// Stars
group_uniforms stars;

uniform float stars_intensity : hint_range(0.0, 5.0, 0.1) = 0.0;

// Shooting Stars
group_uniforms shooting_stars;

uniform float shooting_stars_intensity : hint_range(0.0, 10.0, 0.1) = 0.0;
uniform sampler2D shooting_star_sampler : filter_linear, repeat_disable;
uniform vec3 shooting_star_tint : source_color;

// Volumetric Clouds
group_uniforms clouds;

uniform sampler2D cloud_shape_sampler : filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D cloud_noise_sampler : filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D cloud_curves;
uniform int clouds_samples : hint_range(8, 32, 8) = 16;
uniform int shadow_sample : hint_range(1, 4, 1) = 4;
uniform float clouds_density : hint_range(0.0, 1.0, 0.1) = 0.5;
uniform float clouds_scale : hint_range(0.5, 1.5, 0.1) = 1.0;
uniform float clouds_smoothness : hint_range(0.01, 0.1, 0.01) = 0.035;
uniform float clouds_shadow_intensity : hint_range(0.1, 10.0, 0.1) = 1.0;
uniform float clouds_self_shadow : hint_range(0.0, 1.0, 0.05) = 0.5; // Self-shadowing amount

// Cloud Colors
group_uniforms clouds_colors;

uniform vec3 clouds_light_color : source_color; // Legacy - will be calculated dynamically
uniform vec3 clouds_day_color : source_color = vec3(1.0, 1.0, 1.0);
uniform vec3 clouds_sunset_color : source_color = vec3(1.0, 0.8, 0.5);
uniform vec3 clouds_night_color : source_color = vec3(0.15, 0.2, 0.4);
uniform vec3 clouds_moon_color : source_color = vec3(0.3, 0.4, 0.6);

// High Clouds
group_uniforms high_clouds;

uniform sampler2D high_clouds_sampler;
uniform float high_clouds_density : hint_range(0.0, 1.0, 0.05) = 0.0;

float rand(float n){return fract(sin(n) * 43758.5453123);}

// Voronoi method credit:
// The MIT License
// Copyright © 2013 Inigo Quilez
// https://www.shadertoy.com/view/ldl3Dl

vec3 hash( vec3 x ){
	x = vec3( dot(x,vec3(127.1,311.7, 74.7)),
			  dot(x,vec3(269.5,183.3,246.1)),
			  dot(x,vec3(113.5,271.9,124.6)));
	return fract(sin(x)*43758.5453123);
}

vec3 voronoi( in vec3 x ){
	vec3 p = floor( x );
	vec3 f = fract( x );

	float id = 0.0;
	vec2 res = vec2( 100.0 );
	for( int k=-1; k<=1; k++ )
	for( int j=-1; j<=1; j++ )
	for( int i=-1; i<=1; i++ ) {
		vec3 b = vec3( float(i), float(j), float(k) );
		vec3 r = vec3( b ) - f + hash( p + b );
		float d = dot( r, r );
		if( d < res.x ) {
			id = dot( p+b, vec3(1.0,57.0,113.0 ) );
			res = vec2( d, res.x );
		} else if( d < res.y ) {
			res.y = d;
		}
    }
    return vec3( sqrt( res ), abs(id) );
}

// https://stackoverflow.com/questions/18558910/direction-vector-to-rotation-matrix

mat3 direction_to_matrix(vec3 direction) {
	vec3 x_axis = normalize(cross(vec3(0.0, 1.0, 0.0), direction));
	vec3 y_axis = normalize(cross(direction, x_axis));
	return mat3(vec3(x_axis.x, y_axis.x, direction.x),
				vec3(x_axis.y, y_axis.y, direction.y),
				vec3(x_axis.z, y_axis.z, direction.z));
}

float cloud_density(vec3 p, float progress){
	float t_o = TIME * 0.001;
	float t_o_small = TIME * -0.005;
	float noise = texture(cloud_noise_sampler, p.xy * 4.0 + t_o_small).x * 0.1 + 0.9;
	float clouds_shape = texture(cloud_shape_sampler, (p.xy + t_o) * clouds_scale).x;
	float height_curve = texture(cloud_curves, vec2(progress, 0.0)).x;
	float base_density = 1.0 - clouds_density;

	return smoothstep(
		base_density - clouds_smoothness,
		base_density + clouds_smoothness,
		clouds_shape * noise * height_curve
	);
}

vec2 cloud_ray_march(vec3 direction, vec3 sun_direction){
	float density = 0.0;
	float light = 0.0;
	float height = 0.03;
	vec3 sample_point = vec3(0.0, 0.0, 2.0);
	int loop_offset = clouds_samples * 3;

	// Main cloud density sampling
	for(int i = loop_offset; i < clouds_samples + loop_offset; i++) {
		float progress = float(i) / float(clouds_samples);
		sample_point = direction * height * progress;
		float point_density = cloud_density(sample_point, progress);
		density += point_density;

		// Light sampling for self-shadowing
		float point_light = 0.0;
		for(int f = 0; f < shadow_sample; f++){
			float shadow_progress = float(f) / float(shadow_sample);
			vec3 shadow_offset = sun_direction * height * shadow_progress;
			point_light += cloud_density(sample_point + shadow_offset, progress);
		}
		light += point_light;
	}

	return vec2(clamp(density, 0.0, 1.0), light / float(shadow_sample * clouds_samples));
}

vec3 random_direction(float seed){
	float phi = rand(seed) * PI;
	float costheta = rand(seed + 100.0) * 2.0 - 1.0;
	float theta = acos(costheta);
	return vec3( sin(theta) * cos(phi), (theta) * sin(phi), cos(theta) );
}

float get_shooting_star(vec3 eyedir){
	float shooting_star = 0.0;
	for(int i = 0; i < 4; i++){
		float base_rand = rand(float(i));
		float time = TIME + base_rand * 2.0;
		float duration = 0.5 + base_rand;
		float seed = floor(time / duration) * duration + base_rand;
		float progress = mod(time, duration) / duration;
		float rand_value = rand(seed + 100.0);
		float rand_scale = base_rand * 10.0;
		float a = rand_value * 0.8;
		mat3 angle = mat3(vec3(cos(a), -sin(a), 0.0), vec3(sin(a), cos(a), 0.0), vec3(0.0, 0.0, 1.0));
		vec3 shooting_dir = direction_to_matrix(random_direction(seed)) * angle * eyedir;
		vec2 shooting_uv = ((shooting_dir.xy + vec2(0.0, progress * 0.4)) * (8.0 + rand_scale)) + vec2(0.5);

		float shooting_mask = ceil(
			clamp(shooting_uv.x * (1.0 - shooting_uv.x), 0.0, 1.0) *
			clamp(shooting_uv.y * (1.0 - shooting_uv.y), 0.0, 1.0)
			) * ceil(shooting_dir.z);

		shooting_star = clamp(
			shooting_star + texture(shooting_star_sampler, shooting_uv).x
			* sin(progress * PI)
			* shooting_mask * rand_value,
		0.0, 1.0);
	}
	return clamp(shooting_star, 0.0, 1.0);
}

void sky() {

	float horizon_mask = abs(EYEDIR.y);
	float bottom_mask = smoothstep(0.5, 0.45, SKY_COORDS.y);

	// Use EYEDIR to calculate sun direction instead of SKY_MATRIX
	vec3 sun_dir = EYEDIR;
	float sun_dot = dot(sun_dir, normalize(LIGHT0_DIRECTION));

	// Calculate sun UV coordinates based on eye direction relative to light direction
	vec3 sun_right = normalize(cross(vec3(0.0, 1.0, 0.0), normalize(LIGHT0_DIRECTION)));
	vec3 sun_up = normalize(cross(normalize(LIGHT0_DIRECTION), sun_right));

	// Project eye direction onto the plane perpendicular to light direction
	vec3 sun_proj = sun_dir - normalize(LIGHT0_DIRECTION) * sun_dot;
	vec2 sun_uv = vec2(
		dot(sun_proj, sun_right),
		dot(sun_proj, sun_up)
	) * sun_scale + vec2(0.5);

	// Improved visibility with wider transition range for better visibility
	float sun_visibility = smoothstep(-0.25, 0.05, sun_dot);

	// Create texture mask with visibility factor (less aggressive clamping)
	float sun_mask = smoothstep(0.0, 0.3, clamp(sun_uv.x * (1.0 - sun_uv.x), 0.0, 1.0) *
		clamp(sun_uv.y * (1.0 - sun_uv.y), 0.0, 1.0)) * sun_visibility;

	vec4 sun_color = texture(sun_sampler, sun_uv);

	// Moon is the second directional light
	// Simple moon direction calculation using the same approach
	float moon_dot = dot(EYEDIR, normalize(LIGHT1_DIRECTION));

	// Calculate moon UV coordinates
	vec3 moon_right = normalize(cross(vec3(0.0, 1.0, 0.0), normalize(LIGHT1_DIRECTION)));
	vec3 moon_up = normalize(cross(normalize(LIGHT1_DIRECTION), moon_right));

	// Project eye direction onto the plane perpendicular to moon direction
	vec3 moon_proj = EYEDIR - normalize(LIGHT1_DIRECTION) * moon_dot;
	vec2 moon_uv = vec2(
		dot(moon_proj, moon_right),
		dot(moon_proj, moon_up)
	) * moon_scale + vec2(0.5);
	// Improved moon visibility with wider transition range
	float moon_visibility = smoothstep(-0.25, 0.05, moon_dot);

	// Create texture mask with enhanced visibility factor
	float moon_mask = smoothstep(0.0, 0.3, clamp(moon_uv.x * (1.0 - moon_uv.x), 0.0, 1.0) *
		clamp(moon_uv.y * (1.0 - moon_uv.y), 0.0, 1.0)) * moon_visibility;

	vec4 moon_color = texture(moon_sampler, moon_uv);

		// Enhanced night/day transition with twilight
	float sun_elevation = LIGHT0_DIRECTION.y;

	// Calculate air mass using Young's approximation for better atmospheric scattering
	float zenith_angle = acos(max(0.001, sun_elevation));
	float air_mass = 1.0 / (cos(zenith_angle) + 0.15 * pow(93.885 - zenith_angle * 180.0/PI, -1.253) * air_mass_shift);
	air_mass = clamp(air_mass, 1.0, 38.0); // Limit range (38.0 = extreme horizon)

	// Improved day-night transition with extended twilight period
	float night_factor = smoothstep(-night_transition_width, night_transition_width, sun_elevation);
	float twilight_factor = smoothstep(-0.2, 0.1, sun_elevation);

	// Enhanced Rayleigh scattering with air mass-based extinction
	float mu = dot(normalize(EYEDIR), normalize(LIGHT0_DIRECTION));

	// Phase function with improved forward scattering
	float phase = 0.75 * (1.0 + pow(clamp(mu, 0.0, 1.0), rayleigh_falloff));

	// Apply extinction based on air mass calculation
	float extinction_factor = exp(-0.1 * air_mass);
	vec3 rayleigh_color = rayleigh_coeff * phase * rayleigh_strength * extinction_factor;

	// Ambient minimum for dark areas
	rayleigh_color = max(rayleigh_color, vec3(0.01, 0.02, 0.04));

	// Enhanced sunset/sunrise glow with better color shifting and daytime influence
	// Gaussian distribution for sunset intensity based on sun elevation with wider range
	float sunset_width_daytime = sunset_width * 2.0; // Wider distribution for visibility during day
	float sunset_elevation = exp(-pow((sun_elevation - sunset_offset) / sunset_width_daytime, 2.0));

	// View angle dependency with improved non-linear falloff
	float view_angle = 1.0 - dot(normalize(EYEDIR), normalize(LIGHT0_DIRECTION));
	float view_sunset = exp(-pow(view_angle / sunset_view_width, 1.5));

	// Combined sunset glow factor with increased daytime influence
	// Removed the (1.0 - night_factor) to allow sunset colors to appear even during full daylight
	float sunset_glow = sunset_elevation * view_sunset * sunset_intensity * 1.5;

	// Red shift at low sun angles based on air mass (wavelength-dependent scattering)
	vec3 shifted_color = mix(sunset_color, vec3(1.0, 0.2, 0.05), clamp(air_mass/10.0, 0.0, 1.0));
	vec3 sunset = shifted_color * sunset_glow;

	// Horizon to zenith gradient with soft blend and improved sunset visibility
	float horizon_blend = smoothstep(-0.15, 0.35, EYEDIR.y);

	// Adjust the sunset contribution based on viewing angle for more apparent sunset
	float sunset_sky_factor = max(sunset_glow, sunset_elevation * 0.5);
	vec3 base_sky = mix(sunset, rayleigh_color, horizon_blend * (1.0 - sunset_sky_factor * 0.5));

	// Add bottom color for lower sky areas
	float bottom_sky_blend = smoothstep(-0.2, 0.1, EYEDIR.y);
	base_sky = mix(bottom_color, base_sky, bottom_sky_blend);

	// Twilight color added to zenith during transition periods
	float zenith_blend = smoothstep(0.3, 0.7, EYEDIR.y);
	float twilight_blend = (1.0 - twilight_factor) * (1.0 - night_factor);
	base_sky = mix(base_sky, mix(base_sky, twilight_color, zenith_blend), twilight_blend * 0.7);

	// Minimum ambient light to avoid completely dark areas
	vec3 min_ambient = mix(vec3(0.01, 0.02, 0.04), vec3(0.04, 0.07, 0.12), night_factor);
	vec3 sky_color = base_sky + min_ambient; // Adding prevents dark bands

	// Night sky transition with sunset blend
	float sunset_night_blend = smoothstep(0.1, 0.6, night_factor);
	sky_color = mix(sunset, sky_color, sunset_night_blend);

	// Preserve horizon glow during night
	float night_horizon_preserve = smoothstep(-0.1, 0.1, EYEDIR.y);
	float night_blend_factor = mix(night_factor * 0.85, night_factor, night_horizon_preserve);
	sky_color = mix(night_sky_color, sky_color, night_blend_factor);

	// Stars

	// Stars visibility with zenith-to-horizon progression and sun angle dependency
	float star_elevation_factor = 1.0 - smoothstep(-0.1, 0.15, sun_elevation);
	float zenith_factor = smoothstep(0.1, 0.5, EYEDIR.y);

	// Add sun proximity factor - reduce star visibility when looking near the sun
	float sun_angle = dot(normalize(EYEDIR), normalize(LIGHT0_DIRECTION));
	float sun_proximity = 1.0 - smoothstep(0.0, 0.7, sun_angle); // Higher values = more stars suppressed near sun

	// Combine factors - stars appear at zenith first and avoid sun's vicinity
	float stars_visibility = star_elevation_factor * mix(0.5, 1.0, zenith_factor) * sun_proximity;

	if(stars_intensity > 0.0 && stars_visibility > 0.01){
		vec2 stars = voronoi(EYEDIR * 25.0).xz;

		// Height-based twinkling (stronger near horizon)
		float twinkle_intensity = mix(0.05, 0.02, zenith_factor);
		float star_mask = smoothstep(0.025 + ((1.0 + sin(TIME + stars.y)) / 2.0) * twinkle_intensity, 0.0, stars.x);

		// Apply visibility factor with sunset/sunrise gradient
		float sunset_stars_fade = smoothstep(0.0, 0.3, stars_visibility); // Sharper cutoff during transition
		star_mask *= sunset_stars_fade * stars_visibility;

		// Adjust star brightness based on sky background (dimmer against bright sky)
		float sky_luminance = dot(sky_color, vec3(0.299, 0.587, 0.114));
		float brightness_adjust = 1.0 - smoothstep(0.0, 0.2, sky_luminance);

		sky_color += star_mask * stars_intensity * brightness_adjust;
	}

	// Add shooting stars

	if(shooting_stars_intensity > 0.0){
		sky_color += get_shooting_star(EYEDIR) * shooting_stars_intensity * shooting_star_tint;
	}

	// Create a sun halo/glow effect
	float sun_halo_size = 20.0 * sun_scale; // Controls the size of the halo, scaled with sun size
	float sun_halo_intensity = sun_intensity * 0.5; // Reduced intensity for subtler effect
	float sun_halo_falloff = 3.0; // Increased falloff for quicker fade out
	
	// Calculate sun halo based on view angle to sun
	float sun_angle_for_halo = 1.0 - max(0.0, dot(normalize(EYEDIR), normalize(LIGHT0_DIRECTION)));
	float sun_halo = sun_halo_intensity * exp(-sun_angle_for_halo * sun_halo_size * sun_halo_falloff);
	
	// Add the halo around the sun with appropriate color that matches the sun/sunset
	vec3 sun_halo_color = mix(sunset_color, sun_tint, 0.5) * 0.6; // Further reduced color intensity
	sky_color += sun_halo * sun_halo_color * sun_visibility * smoothstep(-0.1, 0.2, sun_dot);
	
	// Add sun with enhanced brightness (increased from 2.0 to 3.0)
	float enhanced_sun_intensity = sun_intensity * 3.0; // Triple the base intensity
	float enhanced_sun_alpha = min(1.0, sun_color.a * 1.8); // Boost alpha further
	sky_color = mix(sky_color, sun_color.rgb * enhanced_sun_intensity * sun_tint, enhanced_sun_alpha * sun_mask * bottom_mask);

	// Create a moon halo/glow effect
	float moon_halo_size = 15.0 * moon_scale; // Controls the size of the halo, scaled with moon size
	float moon_halo_intensity = moon_intensity * 0.4; // Reduced intensity for subtler effect
	float moon_halo_falloff = 3.5; // Increased falloff for quicker fade out
	
	// Calculate moon halo based on view angle to moon
	float moon_angle_for_halo = 1.0 - max(0.0, dot(normalize(EYEDIR), normalize(LIGHT1_DIRECTION)));
	float moon_halo = moon_halo_intensity * exp(-moon_angle_for_halo * moon_halo_size * moon_halo_falloff);
	
	// Add the halo around the moon with a slight blue tint
	vec3 moon_halo_color = vec3(0.8, 0.9, 1.0) * moon_tint * 0.8; // Reduced color intensity
	sky_color += moon_halo * moon_halo_color * moon_visibility * smoothstep(-0.1, 0.2, moon_dot);
	
	// Add moon with enhanced brightness (increased from 2.0 to 3.0)
	float enhanced_moon_intensity = moon_intensity * 3.0; // Triple the base intensity
	float enhanced_moon_alpha = min(1.0, moon_color.a * 1.8); // Boost alpha further
	sky_color = mix(sky_color, moon_color.rgb * enhanced_moon_intensity * moon_tint, enhanced_moon_alpha * moon_mask * bottom_mask);

	// Dynamic cloud coloring based on time of day and viewing direction
	vec3 dynamic_cloud_color;
	float sun_vertical_dot = max(0.0, dot(normalize(vec3(0.0, 1.0, 0.0)), normalize(LIGHT0_DIRECTION)));
	float moon_vertical_dot = max(0.0, dot(normalize(vec3(0.0, 1.0, 0.0)), normalize(LIGHT1_DIRECTION)));

	// Time of day transition factors
	float cloud_day_factor = smoothstep(-0.15, 0.15, sun_elevation);

	// Modify sunset factor to consider view angle - clouds facing away from sunset are darker
	float cloud_view_sunset = dot(normalize(EYEDIR), normalize(LIGHT0_DIRECTION));
	float sunset_direction_factor = smoothstep(-0.5, 0.8, cloud_view_sunset);

	// Adjust sunset factor based on view direction
	float cloud_sunset_factor = sunset_elevation * sunset_intensity * sunset_direction_factor;

	// Light source contributions
	vec3 sun_light_contribution = clouds_day_color * sun_vertical_dot;
	vec3 sunset_light_contribution = clouds_sunset_color * cloud_sunset_factor;
	vec3 moon_light_contribution = clouds_moon_color * moon_vertical_dot * (1.0 - cloud_day_factor);

	// Multi-stage blending between day, sunset and night with directional awareness
	dynamic_cloud_color = mix(
		mix(clouds_night_color, sunset_light_contribution, cloud_sunset_factor * 2.0),
		mix(sunset_light_contribution, sun_light_contribution, cloud_day_factor),
		cloud_day_factor
	);

	// Add moon lighting at night
	dynamic_cloud_color += moon_light_contribution * (1.0 - cloud_day_factor);

	// Ensure minimum brightness
	dynamic_cloud_color = max(dynamic_cloud_color, clouds_night_color * 0.5);
	// High altitude cirrus/wispy clouds
	if(high_clouds_density > 0.0){
		vec2 high_clouds_uv = (EYEDIR.xz / clamp(EYEDIR.y, 0.0, 1.0)) * 0.25 + TIME * 0.001;
		float high_clouds_mask = texture(high_clouds_sampler, high_clouds_uv).x;
		sky_color = mix(sky_color, dynamic_cloud_color,
			smoothstep(0.0, 1.0, high_clouds_mask) * horizon_mask * bottom_mask * high_clouds_density);
	}

	// Volumetric clouds rendering
	if (AT_HALF_RES_PASS) {
		vec3 clouds_direction = vec3(EYEDIR.xz / clamp(EYEDIR.y, 0.0, 1.0), 1.0);
		vec2 clouds = EYEDIR.y > 0.0 ? cloud_ray_march(clouds_direction, LIGHT0_DIRECTION) : vec2(0.0);

		// Apply self-shadowing for volumetric appearance
		float light_factor = exp(-clouds.y * clouds_shadow_intensity);
		vec3 shadowed_cloud_color = mix(dynamic_cloud_color * 0.4, dynamic_cloud_color, light_factor);

		// Final cloud color with ambient light
		COLOR = mix(bottom_color * extinction_factor, shadowed_cloud_color, clouds_self_shadow);
		ALPHA = (1.0 - exp(-clouds.x * horizon_mask * bottom_mask * 10.0));

	} else {
		COLOR.rgb = mix(sky_color, HALF_RES_COLOR.rgb, HALF_RES_COLOR.a);
	}
}
