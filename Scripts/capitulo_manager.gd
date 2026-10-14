class_name CapituloManager
extends Node2D

## Manager de los niveles de historia.
##
## Antes habia un script casi identico por capitulo (tenoch_manager.gd y
## tenoch1520_manager.gd, iguales salvo cinco valores). Ahora todos los niveles
## usan este y lo UNICO que se configura por escena es `numero_capitulo`; los
## dialogos, el año y el titulo salen de capitulos.json.

## Que capitulo es este nivel. Debe coincidir con el "numero" de capitulos.json.
@export var numero_capitulo: int = 1

@onready var cuadro_dialogo = find_child("CuadroDialogo", true, false)
@onready var limites_mapa = find_child("LimitesCamara", true, false)

var datos_capitulo: Dictionary = {}


func _ready() -> void:
	datos_capitulo = Global.obtener_capitulo(numero_capitulo)
	if datos_capitulo.is_empty():
		push_error("Este nivel dice ser el capitulo %d, pero no existe en capitulos.json." % numero_capitulo)

	if cuadro_dialogo:
		if not cuadro_dialogo.is_connected("dialogo_terminado", Callable(self, "_on_dialogo_terminado")):
			cuadro_dialogo.connect("dialogo_terminado", Callable(self, "_on_dialogo_terminado"))
		_lanzar_dialogo_inicial()

	_ajustar_camara()


## El dialogo de entrada se lanza una sola vez por partida.
func _lanzar_dialogo_inicial() -> void:
	var id_dialogo := str(datos_capitulo.get("dialogo_inicio", ""))
	if id_dialogo == "" or Global.eventos_completados.get(id_dialogo, false):
		return
	if cuadro_dialogo.has_method("iniciar_dialogo"):
		cuadro_dialogo.iniciar_dialogo(id_dialogo)
		Global.eventos_completados[id_dialogo] = true


func _ajustar_camara() -> void:
	if not limites_mapa:
		return
	var player = find_child("Player", true, false)
	if not player:
		return
	var camara = player.get_node_or_null("Camera2D")
	if not camara:
		return
	camara.limit_left = int(limites_mapa.global_position.x)
	camara.limit_top = int(limites_mapa.global_position.y)
	camara.limit_right = int(limites_mapa.global_position.x + limites_mapa.size.x)
	camara.limit_bottom = int(limites_mapa.global_position.y + limites_mapa.size.y)


func _on_dialogo_terminado(id_dialogo: String) -> void:
	var id_final := str(datos_capitulo.get("dialogo_final", ""))
	if id_final != "" and id_dialogo == id_final:
		terminar_capitulo()


## Da por completado el capitulo, avanza el progreso y va a la pantalla negra.
## Es publica por si algun evento del nivel (un minijuego, una cinematica) tiene
## que terminarlo sin pasar por el dialogo final.
func terminar_capitulo() -> void:
	Global.eventos_completados["capitulo_%d_completado" % numero_capitulo] = true

	# Solo avanza si el jugador venia justo en este capitulo: asi rejugarlo no
	# adelanta la historia de mas.
	if Global.progreso_historia == numero_capitulo:
		Global.avanzar_capitulo()

	# Normalmente se regresa al laboratorio; el último capítulo lleva al epílogo
	# ("escena_al_terminar" en capitulos.json).
	var destino := str(datos_capitulo.get("escena_al_terminar", Global.ESCENA_LABORATORIO))
	if not ResourceLoader.exists(destino):
		push_error("escena_al_terminar del capitulo %d no existe: '%s'." % [numero_capitulo, destino])
		destino = Global.ESCENA_LABORATORIO
	Global.preparar_capitulo_completado(numero_capitulo, destino)
	SceneTransition.change_scene(Global.ESCENA_TRANSICION)
