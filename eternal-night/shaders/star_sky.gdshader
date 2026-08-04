shader_type sky;

uniform vec3 sky_top_color : source_color = vec3(0.015, 0.025, 0.055);
uniform vec3 sky_horizon_color : source_color = vec3(0.04, 0.06, 0.12);
uniform vec3 ground_horizon_color : source_color = vec3(0.02, 0.025, 0.04);
uniform vec3 ground_bottom_color : source_color = vec3(0.01, 0.012, 0.02);
uniform float star_density : hint_range(0.0, 1.0) = 0.18;
uniform float twinkle_speed : hint_range(0.0, 10.0) = 1.8;
uniform float star_brightness : hint_range(0.0, 2.0) = 1.2;

float hash(vec3 p) {
	return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453123);
}

float noise(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);

	float n = mix(
		mix(
			mix(hash(i + vec3(0.0, 0.0, 0.0)), hash(i + vec3(1.0, 0.0, 0.0)), f.x),
			mix(hash(i + vec3(0.0, 1.0, 0.0)), hash(i + vec3(1.0, 1.0, 0.0)), f.x),
			f.y
		),
		mix(
			mix(hash(i + vec3(0.0, 0.0, 1.0)), hash(i + vec3(1.0, 0.0, 1.0)), f.x),
			mix(hash(i + vec3(0.0, 1.0, 1.0)), hash(i + vec3(1.0, 1.0, 1.0)), f.x),
			f.y
		),
		f.z
	);
	return n;
}

void sky() {
	vec3 dir = normalize(EYEDIR);
	float horizon_blend = clamp(dir.y * 0.5 + 0.5, 0.0, 1.0);
	vec3 sky_color = mix(sky_horizon_color, sky_top_color, horizon_blend);
	vec3 ground_color = mix(ground_bottom_color, ground_horizon_color, horizon_blend);
	vec3 col = mix(ground_color, sky_color, step(0.0, dir.y));

	float star_scale = 350.0;
	vec3 star_pos = dir * star_scale;
	float star_hash = hash(floor(star_pos));
	float star_noise = noise(star_pos * 0.5 + vec3(TIME * 0.05));

	float density_threshold = 1.0 - star_density * 0.05;
	if (dir.y > -0.05 && star_hash > density_threshold) {
		float twinkle = sin(TIME * twinkle_speed * (star_hash * 2.0 + 0.5) + star_hash * 10.0) * 0.5 + 0.5;
		twinkle = twinkle * 0.6 + 0.4;
		float size = smoothstep(0.992, 1.0, star_hash);
		float brightness = size * twinkle * star_brightness * star_noise;
		col += vec3(brightness);
	}

	COLOR = col;
}
