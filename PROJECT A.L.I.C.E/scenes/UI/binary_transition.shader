shader_type canvas_item;

// Screen transition: the picture breaks up into flickering binary digits (0 and 1).
// progress 0.0 = the scene is fully visible, 1.1 = the whole screen is digits.
// Every cell of the grid turns into a digit at its own moment, so it dissolves bit by bit.

uniform float progress : hint_range(0.0, 1.1) = 0.0;
uniform vec2 cells = vec2(64.0, 25.0);                       // how many digits fit across and down
uniform vec4 digit_color : hint_color = vec4(0.25, 1.0, 0.55, 1.0);
uniform vec4 back_color : hint_color = vec4(0.01, 0.03, 0.025, 1.0);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

// Digits are 3 x 5 pixels, one bit per pixel, row by row from the top left.
// 31599 draws a 0 and 29850 draws a 1.
float glyph_bit(float code, float index) {
	return mod(floor(code / exp2(index)), 2.0);
}

void fragment() {
	vec2 grid = UV * cells;
	vec2 cell = floor(grid);
	vec2 local = fract(grid);

	// when this cell turns into a digit: random, with a slight sweep from left to right
	float t = mix(hash(cell), cell.x / cells.x, 0.25);

	if (t >= progress) {
		COLOR = vec4(0.0);   // still the scene underneath
	} else {
		// each digit flickers between 0 and 1 at its own speed
		float rate = 4.0 + 6.0 * hash(cell + vec2(3.1, 1.7));
		float digit = step(0.5, hash(cell + vec2(floor(TIME * rate), 5.3)));

		float on = 0.0;
		if (local.x > 0.22 && local.x < 0.78 && local.y > 0.12 && local.y < 0.88) {
			float px = floor((local.x - 0.22) / 0.56 * 3.0);
			float py = floor((local.y - 0.12) / 0.76 * 5.0);
			float code = mix(31599.0, 29850.0, digit);
			on = glyph_bit(code, py * 3.0 + px);
		}

		float fresh = 1.0 - clamp((progress - t) * 5.0, 0.0, 1.0);   // newly changed digits flash white
		float glow = mix(0.45, 1.0, hash(cell + vec2(7.7, 2.2)));
		vec3 ink = mix(digit_color.rgb * glow, vec3(1.0), fresh);
		COLOR = vec4(mix(back_color.rgb, ink, on), 1.0);
	}
}
