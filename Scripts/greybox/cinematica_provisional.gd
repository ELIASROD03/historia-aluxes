class_name CinematicaProvisional
extends Node
## Atiende los eventos "cinematica_*" de los diálogos mientras no existe la
## cinemática real: muestra un letrero a pantalla completa con lo que pasaría
## ("Chaac abre un portal y escapa") y luego deja seguir el diálogo.
##
## Sin alguien que responda a un "cinematica_*", el cuadro de diálogo se queda
## escondido esperando y el jugador se queda atorado: por eso este nodo atiende
## TAMBIÉN los eventos que no tiene en `textos`, con un letrero genérico.
##
## Cuando una cinemática exista de verdad, quita su entrada de `textos` y agrega
## su id a `ignorar`, para que este nodo no le gane.
##
## También sirve para marcar un MINIJUEGO que aún no existe: se usa un evento
## "cinematica_*" con un texto que empiece con "[ MINIJUEGO PENDIENTE ]". Cuando el
## minijuego exista, en dialogos.json se cambia ese evento por "minijuego_<clave>_<nivel>"
## y se registra la escena en MINIJUEGOS de dialogo_manager.gd.

## evento -> lo que se muestra mientras no esté hecha la cinemática.
@export var textos: Dictionary = {}
## Eventos que ya atiende otro script (no se tocan).
@export var ignorar: PackedStringArray = []
@export var duracion: float = 3.0

var _cuadro_dialogo: Node


func _ready() -> void:
	_cuadro_dialogo = get_parent().find_child("CuadroDialogo", true, false)
	if _cuadro_dialogo:
		_cuadro_dialogo.evento_cinematica.connect(_on_evento_cinematica)


func _on_evento_cinematica(evento: String) -> void:
	if evento in ignorar:
		return
	var texto: String = textos.get(evento, evento.trim_prefix("cinematica_").replace("_", " "))

	var capa := CanvasLayer.new()
	capa.layer = 60
	var fondo := ColorRect.new()
	fondo.color = Color(0, 0, 0, 0.85)
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	fondo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	capa.add_child(fondo)
	var letrero := Label.new()
	# Si el texto ya trae su propio encabezado entre corchetes (p. ej.
	# "[ MINIJUEGO PENDIENTE ]"), se respeta; si no, se le pone el de cinemática.
	letrero.text = texto if texto.begins_with("[") else "[ CINEMÁTICA PENDIENTE ]\n\n" + texto
	letrero.set_anchors_preset(Control.PRESET_FULL_RECT)
	letrero.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	letrero.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	letrero.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	letrero.add_theme_font_size_override("font_size", 16)
	letrero.add_theme_color_override("font_color", Color(1, 0.93, 0.75))
	fondo.add_child(letrero)
	add_child(capa)

	fondo.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(fondo, "modulate:a", 1.0, 0.3)
	tween.tween_interval(duracion)
	tween.tween_property(fondo, "modulate:a", 0.0, 0.3)
	await tween.finished
	capa.queue_free()
	if _cuadro_dialogo:
		_cuadro_dialogo.continuar_cinematica()
