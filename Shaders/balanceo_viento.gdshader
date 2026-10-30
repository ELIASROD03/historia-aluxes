shader_type canvas_item;
// Balanceo de viento para árboles y pasto: la parte de arriba del sprite se
// mece y la base queda fija. Cada planta usa su posición como desfase para que
// no se muevan todas al mismo tiempo.

uniform float fuerza = 2.0;
uniform float velocidad = 1.5;

void vertex() {
	float fase = MODEL_MATRIX[3].x * 0.05;
	VERTEX.x += sin(TIME * velocidad + fase) * fuerza * (1.0 - UV.y);
}
