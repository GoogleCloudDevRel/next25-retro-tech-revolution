shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

uniform float lineIntensity;
uniform float lineThickness;
uniform float linePower;
uniform float warpAmount;
uniform float lineSpeed;

vec2 outlineCurve(vec2 uv) {

	uv = (uv - 0.5) * 2.0;
	uv *= 1.1;

	uv.x *= 1.0 + pow((abs(uv.y) / 4.0), 2.5);
	uv.y *= 1.0 + pow((abs(uv.x) / 3.5), 2.5);

	uv = (uv / 2.0) + 0.5;
	uv = uv * 0.92 + 0.04;

	return uv;

}

vec2 scale(vec2 p, vec2 scale) {

    p -= 0.5;
    p /= scale;
    p += 0.5;

    return p;

}

void fragment() {
        vec2 uv = SCREEN_UV;

		vec2 st = uv;
	    st = scale( st, vec2( 1.00 ) );

	    vec2 curvedUV = mix( st, outlineCurve(st), warpAmount );

		vec3 col = texture( screen_texture, curvedUV ).rgb;

		vec2 scanlineUV = curvedUV;

    		scanlineUV.y -= TIME * 0.01 * lineSpeed;

		float intensity = lineIntensity;

    		float scanLines = clamp(intensity + intensity * cos(3.5 + scanlineUV.y * 1000. * lineThickness), 0.0, 1.0);

		float saturation = pow(scanLines, linePower);
		col = col * vec3(1.0 + 1.5 * saturation);

        COLOR = vec4(col, 1.0);
}