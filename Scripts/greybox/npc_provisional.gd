@tool
class_name NpcProvisional
extends Node2D
## Personaje provisional de greyboxing. Si tiene `textura` dibuja ese sprite
## (animado si es una tira de cuadros); si no, una silueta de color. Encima va
## su nombre, para saber quién es mientras no exista el arte.
##
## Cómo habla (al correr el juego se arma solo, sin Area2D ni CollisionShape a mano):
##  - `id_burbuja` (burbujas.json): burbuja sobre la cabeza, como los NPC de
##    Tenoch.tscn. Es lo normal para la gente del nivel.
##  - `id_dialogo` (dialogos.json): el cuadro de diálogo grande. Solo para los
##    aluxes y para quien lanza un minijuego desde el diálogo (Palabras impostoras).
##
## El origen del nodo son los PIES del personaje: ponlo sobre el piso.

@export var nombre: String = "NPC":
	set(v):
		nombre = v
		queue_redraw()
@export var mostrar_nombre: bool = true:
	set(v):
		mostrar_nombre = v
		queue_redraw()

@export_group("Apariencia")
## Vacío = silueta de color.
@export var textura: Texture2D:
	set(v):
		textura = v
		_cuadro = 0
		_rect_listo = false
		queue_redraw()
@export_range(1, 32) var hframes: int = 1:
	set(v):
		hframes = v
		_rect_listo = false
		queue_redraw()
@export_range(1, 32) var vframes: int = 1:
	set(v):
		vframes = v
		_rect_listo = false
		queue_redraw()
@export var fps: float = 8.0
## Tamaño del dibujo (no del nombre). Los aluxes son bajitos: ~0.75.
@export_range(0.25, 3.0, 0.01) var escala: float = 1.0:
	set(v):
		escala = v
		queue_redraw()
@export var voltear: bool = false:
	set(v):
		voltear = v
		queue_redraw()
## Corrección fina hacia arriba (negativo) o abajo. Normalmente no hace falta: los
## pies se detectan solos a partir de la parte no transparente del sprite.
@export var ajuste_y: float = 0.0:
	set(v):
		ajuste_y = v
		queue_redraw()
@export var color_silueta: Color = Color(0.35, 0.35, 0.4):
	set(v):
		color_silueta = v
		queue_redraw()
@export var tamano_silueta: Vector2 = Vector2(18, 40):
	set(v):
		tamano_silueta = v
		queue_redraw()
## Halo detrás del personaje (alfa 0 = sin halo). Sirve para marcar a un alux
## escondido, p. ej. el brillo rojo de Chaac.
@export var resplandor: Color = Color(1, 0, 0, 0):
	set(v):
		resplandor = v
		queue_redraw()

@export_group("Burbuja")
## Id de burbujas.json. Puede tener un texto o una lista de textos.
@export var id_burbuja: String = "":
	set(v):
		id_burbuja = v
		queue_redraw()
## true = sale el letrero "Hablar" y la burbuja aparece al pulsar acción.
## false = la burbuja sale sola al acercarse.
@export var burbuja_requiere_interaccion: bool = true
## Segundos que dura cada frase de la burbuja.
@export var burbuja_segundos: float = 4.0

@export_group("Diálogo")
@export var id_dialogo: String = ""
@export var requiere_interaccion: bool = true
@export var texto_interaccion: String = "Hablar"
## false = se puede volver a hablar con él cuantas veces se quiera.
@export var un_solo_uso: bool = false
@export var variantes_por_capitulo: bool = false

const ESCENA_BURBUJA := preload("res://Scenes/BurbujaMundo.tscn")
## Radio en que la burbuja detecta al jugador. La escena BurbujaMundo trae 200 px:
## con varios NPC juntos se activarían todos a la vez.
const RADIO_BURBUJA := 40.0

var _cuadro := 0
var _tiempo := 0.0
var _rect_cache := Rect2()
var _rect_listo := false


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	if id_burbuja != "":
		_crear_burbuja()
	if id_dialogo == "":
		return
	var zona := ZonaDialogo.new()
	zona.name = "ZonaDialogo"
	zona.id_dialogo = id_dialogo
	zona.requiere_interaccion = requiere_interaccion
	zona.texto_interaccion = texto_interaccion
	zona.un_solo_uso = un_solo_uso
	zona.variantes_por_capitulo = variantes_por_capitulo
	var forma := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(48, 48)
	forma.shape = rect
	zona.add_child(forma)
	# El letrero "Hablar" de ZonaDialogo sale 35 px arriba de la zona: así queda
	# sobre la cabeza y no encima de la cara.
	zona.position = Vector2(0, -_alto() + 10)
	add_child(zona)


func _crear_burbuja() -> void:
	var burbuja := ESCENA_BURBUJA.instantiate()
	burbuja.id_dialogo = id_burbuja
	burbuja.requiere_interaccion = burbuja_requiere_interaccion
	burbuja.tiempo_visible = burbuja_segundos
	# Sobre la cabeza, como en Tenoch (allí va a ~60 px de los pies).
	burbuja.position = Vector2(0, -_alto())
	var circulo := CircleShape2D.new()
	circulo.radius = RADIO_BURBUJA
	burbuja.get_node("CollisionShape2D").shape = circulo
	burbuja.get_node("CollisionShape2D").position = Vector2(0, _alto() / 2.0)
	add_child(burbuja)


func _process(delta: float) -> void:
	# Solo se anima en el juego: en el editor se queda quieto en su primer cuadro,
	# como un Sprite2D normal.
	if Engine.is_editor_hint():
		return
	var total := hframes * vframes
	if textura == null or total <= 1 or fps <= 0.0:
		return
	_tiempo += delta
	if _tiempo >= 1.0 / fps:
		_tiempo = 0.0
		_cuadro = (_cuadro + 1) % total
		queue_redraw()


## Tamaño de un cuadro de la hoja de sprites.
func _tam_cuadro() -> Vector2:
	return Vector2(textura.get_width() / float(hframes), textura.get_height() / float(vframes))


## Parte NO transparente del primer cuadro, en coordenadas del cuadro. Muchas hojas
## traen aire debajo de los pies (SoldadoNpc: ~32 px); con esto los pies quedan
## justo sobre el origen del nodo, sea cual sea el sprite.
func _rect_visible() -> Rect2:
	if _rect_listo:
		return _rect_cache
	var tam := _tam_cuadro()
	_rect_cache = Rect2(Vector2.ZERO, tam)
	var imagen := textura.get_image()
	if imagen:
		if imagen.is_compressed():
			imagen.decompress()
		var usado := imagen.get_region(Rect2i(0, 0, int(tam.x), int(tam.y))).get_used_rect()
		if usado.size.y > 0:
			_rect_cache = Rect2(usado)
	_rect_listo = true
	return _rect_cache


## Alto de lo que se ve del personaje, ya escalado, en píxeles del nivel.
func _alto() -> float:
	return _alto_sin_escala() * escala


func _alto_sin_escala() -> float:
	if textura:
		return _rect_visible().size.y
	return tamano_silueta.y


func _draw() -> void:
	# El personaje se dibuja escalado; el nombre no (si no, la letra se vería
	# borrosa, ver trampa 7 de resumen_cambios.md).
	# Voltear con la escala negativa del transform: un Rect2 de ancho negativo NO
	# voltea en su lugar (lo corre a un lado).
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(-escala if voltear else escala, escala))
	var alto := _alto_sin_escala()
	if resplandor.a > 0.0:
		var centro := Vector2(0, ajuste_y - alto / 2.0)
		for i in 4:
			var c := resplandor
			c.a = resplandor.a * (0.25 + 0.2 * i)
			draw_circle(centro, alto * (0.75 - 0.12 * i), c)

	if textura:
		var tam := _tam_cuadro()
		var pies := _rect_visible().end.y
		var origen := Vector2((_cuadro % hframes) * tam.x, (_cuadro / hframes) * tam.y)
		var destino := Rect2(-tam.x / 2.0, -pies + ajuste_y, tam.x, tam.y)
		draw_texture_rect_region(textura, destino, Rect2(origen, tam))
	else:
		var s := tamano_silueta
		draw_rect(Rect2(-s.x / 2.0, -s.y + s.x + ajuste_y, s.x, s.y - s.x), color_silueta)
		draw_circle(Vector2(0, -s.y + s.x / 2.0 + ajuste_y), s.x / 2.0, color_silueta)

	draw_set_transform(Vector2.ZERO)
	if mostrar_nombre and nombre != "":
		var fuente := ThemeDB.fallback_font
		var ancho := 140.0
		var renglones := nombre.count("\n") + 1
		var alto_renglon := fuente.get_height(8)
		# La base del último renglón queda 4 px sobre la cabeza (y más arriba si hay
		# burbuja, para no taparse con su letrero "Hablar").
		var extra := 16.0 if id_burbuja != "" else 0.0
		var pos := Vector2(-ancho / 2.0,
			-_alto() - 4 - extra + ajuste_y * escala - alto_renglon * (renglones - 1))
		draw_multiline_string_outline(fuente, pos, nombre, HORIZONTAL_ALIGNMENT_CENTER,
			ancho, 8, -1, 3, Color(0, 0, 0, 0.8))
		draw_multiline_string(fuente, pos, nombre, HORIZONTAL_ALIGNMENT_CENTER,
			ancho, 8, -1, Color(1, 1, 0.85))
