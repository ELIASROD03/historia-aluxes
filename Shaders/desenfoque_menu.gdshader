shader_type canvas_item;

// Difumina lo que ya se dibujo detras de este nodo. Se usa como fondo del menu
// de seleccion de dificultad del rompecabezas.
// Godot copia el back buffer solo por usar hint_screen_texture, no hace falta
// poner un BackBufferCopy a mano.

uniform sampler2D pantalla : hint_screen_texture, repeat_disable, filter_linear;

// Que tan lejos se separan las muestras (en pixeles de pantalla).
uniform float radio : hint_range(0.0, 8.0) = 2.5;
// Color que se mezcla encima para oscurecer y que resalten los botones.
// El alpha es la fuerza de la mezcla, no la transparencia final.
uniform vec4 tinte : source_color = vec4(0.06, 0.04, 0.03, 0.45);

void fragment() {
	vec2 paso = SCREEN_PIXEL_SIZE * radio;
	vec3 suma = vec3(0.0);
	float total = 0.0;

	// Rejilla de 5x5 con peso segun la distancia: da un desenfoque suave
	// y es barato de sobra para una pantalla de menu.
	for (int x = -2; x <= 2; x++) {
		for (int y = -2; y <= 2; y++) {
			vec2 desp = vec2(float(x), float(y));
			float peso = 1.0 / (1.0 + dot(desp, desp));
			suma += texture(pantalla, SCREEN_UV + desp * paso).rgb * peso;
			total += peso;
		}
	}

	COLOR = vec4(mix(suma / total, tinte.rgb, tinte.a), 1.0);
}
