extends Control

## Pantalla negra de transicion.
##
## OJO: a pesar del nombre del archivo NO es exclusiva del capitulo 1. La usan
## todos los capitulos, tanto para el letrero de entrada ("Capitulo N / subtitulo")
## como para el de salida ("Capitulo N / ¡COMPLETADO!"). Los textos y el destino
## se dejan en Global antes de venir aqui (ver Global.preparar_entrada_capitulo
## y Global.preparar_capitulo_completado).

const ESPERA := 4.0


func _ready() -> void:
	var cap = find_child("CapituloLabel", true, false)
	var sub = find_child("SubtituloLabel", true, false)

	# Si Global viene vacio se queda el texto que trae la escena como respaldo
	if cap and Global.titulo_pantalla != "":
		cap.text = Global.titulo_pantalla
	if sub and Global.subtitulo_pantalla != "":
		sub.text = Global.subtitulo_pantalla

	await get_tree().create_timer(ESPERA).timeout

	# Esta pantalla no tiene ningun boton, asi que un destino invalido dejaria al
	# jugador encerrado aqui para siempre. Antes que eso, al menu principal.
	var destino: String = Global.destino_pantalla
	if destino == "" or not ResourceLoader.exists(destino):
		push_error("destino_pantalla invalido ('%s'), regresando al menu principal." % destino)
		destino = Global.ESCENA_MENU

	SceneTransition.change_scene(destino)
