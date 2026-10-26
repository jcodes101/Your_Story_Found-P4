shader_type canvas_item;

// Full-world darkness overlay. Everything is black except:
//  - a small ambient circle around the player (always visible surroundings)
//  - a cone of light toward the mouse that fades with distance (flashlight)

uniform vec2 player_pos = vec2(0.0, 0.0);
uniform vec2 aim_dir = vec2(1.0, 0.0);
uniform float cone_half_angle = 0.42;
uniform float light_range = 430.0;
uniform float ambient_radius = 95.0;
uniform float darkness = 0.97;

varying vec2 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	vec2 d = world_pos - player_pos;
	float dist = length(d);

	float ambient = 1.0 - smoothstep(ambient_radius * 0.45, ambient_radius, dist);

	float cone = 0.0;
	if (dist > 0.001) {
		float ang = acos(clamp(dot(d / dist, aim_dir), -1.0, 1.0));
		float edge = 1.0 - smoothstep(cone_half_angle * 0.55, cone_half_angle, ang);
		float fade = 1.0 - smoothstep(0.0, light_range, dist);
		cone = edge * fade;
	}

	float light = clamp(max(ambient, cone), 0.0, 1.0);
	COLOR = vec4(0.0, 0.0, 0.02, darkness * (1.0 - light));
}
