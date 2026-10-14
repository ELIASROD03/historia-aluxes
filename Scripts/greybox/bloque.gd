@tool
class_name Bloque
extends Node2D
## Bloque provisional de greyboxing: un rectángulo de color con su nombre
## ("CATEDRAL", "BARRICADA MEXICA"...) que marca dónde irá un elemento del
## escenario mientras no exista el arte. Se ve igual en el editor y en el juego.
##
## El origen del nodo es el CENTRO DE LA BASE del rectángulo: pon su posición
## sobre el piso y el bloque crece hacia arriba.
##
## Cuando llegue el arte, reemplaza el bloque por el Sprite2D real en esa misma
## posición y bórralo.

@export var texto: String = "BLOQUE":
	set(v):
		texto = v
		queue_redraw()
@export var tamano: Vector2 = Vector2(120, 80):
	set(v):
		tamano = v
		queue_redraw()
@export var color: Color = Color(0.55, 0.5, 0.45):
	set(v):
		color = v
		queue_redraw()
@export var color_texto: Color = Color(1, 1, 1, 0.9):
	set(v):
		color_texto = v
		queue_redraw()
@export_range(6, 32) var tamano_letra: int = 10:
	set(v):
		tamano_letra = v
		queue_redraw()


func _draw() -> void:
	var rect := Rect2(-tamano.x / 2.0, -tamano.y, tamano.x, tamano.y)
	draw_rect(rect, color)
	draw_rect(rect, color.darkened(0.45), false, 2.0)

	if texto == "":
		return
	var fuente := ThemeDB.fallback_font
	var alto_texto := fuente.get_multiline_string_size(texto, HORIZONTAL_ALIGNMENT_CENTER,
		tamano.x - 8, tamano_letra).y
	var y := rect.position.y + (tamano.y - alto_texto) / 2.0 + fuente.get_ascent(tamano_letra)
	draw_multiline_string(fuente, Vector2(rect.position.x + 4, y), texto,
		HORIZONTAL_ALIGNMENT_CENTER, tamano.x - 8, tamano_letra, -1, color_texto)
