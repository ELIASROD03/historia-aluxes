shader_type canvas_item;
// Viento para la capa de hierbas de enfrente (HierbasFrente.tscn). A diferencia
// de balanceo_viento, que mueve el sprite entero, aquí cada columna de pixeles
// se dobla por su cuenta: la raíz (abajo) queda fija y las puntas se mecen con
// ondas que recorren la imagen, como ráfagas pasando sobre el pasto.

uniform float fuerza = 4.0;      // desplazamiento máximo de las puntas, en pixeles
uniform float velocidad = 1.3;
// Qué tan alto llegan las plantas, como fracción de la imagen desde abajo.
uniform float altura_plantas = 0.4;

// En fragment() COLOR ya viene multiplicado por la textura sin desplazar;
// el tinte (modulate) se guarda aquí para aplicarlo a la textura desplazada.
varying vec4 tinte;

void vertex() {
	tinte = COLOR;
}

void fragment() {
	float alto = clamp((1.0 - UV.y) / altura_plantas, 0.0, 1.0);
	float x = UV.x / TEXTURE_PIXEL_SIZE.x;
	float onda = sin(TIME * velocidad + x * 0.015) + 0.4 * sin(TIME * velocidad * 2.7 + x * 0.06);
	// En pixeles enteros para que no se emborrone el pixel art
	float desp = round(onda * fuerza * alto * alto);
	COLOR = texture(TEXTURE, UV - vec2(desp * TEXTURE_PIXEL_SIZE.x, 0.0)) * tinte;
}
