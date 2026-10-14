extends Node2D

@onready var limites_mapa = $LimitesCamara

func _ready() -> void:
	# Buscamos al jugador en la escena actual
	var player = find_child("Player", true, false)
	if player:
		var camara = player.get_node("Camera2D")
		if camara:
			camara.limit_left = int(limites_mapa.global_position.x)
			camara.limit_top = int(limites_mapa.global_position.y)
			camara.limit_right = int(limites_mapa.global_position.x + limites_mapa.size.x)
			camara.limit_bottom = int(limites_mapa.global_position.y + limites_mapa.size.y)

	# El diálogo del laboratorio (lo que pasa ANTES de viajar al capítulo que toca)
	# sale de "dialogo_laboratorio" en capitulos.json. Se ve una sola vez por
	# partida, y se marca al lanzarlo (invariante de eventos_completados).
	var cuadro_dialogo = find_child("CuadroDialogo", true, false)
	if cuadro_dialogo and cuadro_dialogo.has_method("iniciar_dialogo"):
		var id_dialogo := str(Global.capitulo_actual().get("dialogo_laboratorio", ""))
		if id_dialogo != "" and not Global.eventos_completados.get(id_dialogo, false):
			cuadro_dialogo.iniciar_dialogo(id_dialogo)
			Global.eventos_completados[id_dialogo] = true
