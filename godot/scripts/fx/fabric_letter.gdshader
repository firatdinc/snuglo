shader_type canvas_item;
// Kumaş harf: Label glifleri. Dolgu (beyaz font_color) → kumaş dokusu + kabarık gölgeleme;
// kontür (macenta işaret rengi) → krem keçe kenar. Dokular yerel uzayda örneklenir.
uniform sampler2D fabric : filter_linear_mipmap, repeat_enable;
uniform float tile = 220.0;        // dokunun yerel uzaydaki tekrar boyu (px)
uniform vec2 offset = vec2(0.0);
uniform float top = 0.0;           // harf gövdesinin üst/alt sınırı (yerel y) — kabarıklık ışığı
uniform float bottom = 100.0;
uniform vec4 rim : source_color = vec4(0.98, 0.93, 0.85, 1.0);
varying vec2 local;

void vertex() {
	local = VERTEX;
}

void fragment() {
	vec4 c = COLOR;
	float a = c.a;
	// macenta işaret: r yüksek, g düşük → kontür
	bool outline = c.r > 0.5 && c.g < 0.5;
	float t = clamp((local.y - top) / max(bottom - top, 1.0), 0.0, 1.0);
	if (outline) {
		vec3 felt = rim.rgb * mix(1.04, 0.86, t);
		COLOR = vec4(felt, a);
	} else {
		vec3 fab = texture(fabric, local / tile + offset).rgb;
		// kabarık yastık: üstte parlak, altta koyulaşan; ortada hafif parlama bandı
		float shade = mix(1.18, 0.78, smoothstep(0.0, 1.0, t));
		shade += 0.10 * exp(-pow((t - 0.22) * 6.0, 2.0));
		COLOR = vec4(fab * shade, a);
	}
}
