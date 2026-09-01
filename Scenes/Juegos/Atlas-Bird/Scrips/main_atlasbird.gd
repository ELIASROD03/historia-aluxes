extends Node2D

## Atlas-Bird: Atlas persigue a Balaam esquivando columnas.
##
## El cronometro NO es un limite de tiempo, es la distancia que falta para
## alcanzar a Balaam: llegar a 0 es GANAR. El turbo resta segundos y el hechizo
## de Balaam los suma. Se pierde al quedarse sin las 3 vidas.
##
## Todos los numeros salen de atlasbird.json para poder ajustarlos sin abrir
## Godot; si el archivo falta se usan los valores por defecto de este script.

signal juego_completado

const RUTA_CONFIG := "res://atlasbird.json"
const ESCENA_LIBRO := "res://Scenes/LibroHistoria.tscn"

const ANCHO := 640.0
const ALTO := 360.0
const X_SPAWN := 700.0
## Cuanto se respeta del techo y del suelo al sortear el centro del hueco.
const MARGEN_HUECO := 42.0

enum Estado { INICIO, JUGANDO, AVISO, DERROTA, VICTORIA }

@export var pipe_scene: PackedScene
@export var item_scene: PackedScene

@export_group("Sacudida al chocar")
## Pixeles que se mueve la pantalla al perder una vida. El escudo sacude menos.
@export var sacudida_fuerza: float = 7.0
@export var sacudida_duracion: float = 0.28

## Lo asigna DialogoManager al abrirlo desde dialogos.json. Este minijuego no
## tiene niveles, pero la interfaz comun de minijuegos pide la variable.
var nivel_a_cargar: String = ""
## true cuando se entro desde el Libro de Historia (esta escena ES la escena
## actual) y false cuando lo abrio un dialogo encima de un nivel.
var modo_libre: bool = false

var cfg: Dictionary = {}
var estado: int = Estado.INICIO

var tiempo_restante: float = 90.0
var tiempo_juego: float = 0.0
var vidas: int = 3
var escudo: bool = false
var velocidad_actual: float = 110.0
var hueco_actual: float = 118.0
var _reloj_balaam: float = 0.0
var _sacudida_restante: float = 0.0
var _sacudida_total: float = 0.0
var _sacudida_actual: float = 0.0

@onready var atlas: CharacterBody2D = $atlas
@onready var balaam: Sprite2D = $Balaam
@onready var fondo_a: Sprite2D = $Fondo/Bosque1
@onready var fondo_b: Sprite2D = $Fondo/Bosque2
@onready var contenedor: Node2D = $Contenedor
@onready var timer_pipes: Timer = $TimerPipes
@onready var timer_eventos: Timer = $TimerEventos
## El HUD se ajusta en la ESCENA, no aqui: mover o escalar HUD/Vidas y
## HUD/Cronometro reacomoda todo el grupo. El codigo solo prende y apaga.
@onready var corazones: Array = [$HUD/Vidas/Vida1, $HUD/Vidas/Vida2, $HUD/Vidas/Vida3]
@onready var icono_escudo: Sprite2D = $HUD/Escudo
@onready var label_tiempo: Label = $HUD/Cronometro/LabelTiempo
@onready var aviso: Node2D = $Aviso
@onready var aviso_texto: Label = $Aviso/Texto
@onready var mensaje: Label = $MensajeFlotante
@onready var panel_inicio: Node2D = $PanelInicio
@onready var panel_derrota: Node2D = $PanelDerrota
@onready var panel_victoria: Node2D = $PanelVictoria


func _ready() -> void:
	add_to_group("mundo_ab")
	modo_libre = (get_parent() == get_tree().root)

	_cargar_config()
	atlas.configurar(cfg.get("atlas", {}))
	atlas.toco_suelo.connect(_on_toco_suelo)

	timer_pipes.timeout.connect(_generar_columna)
	timer_eventos.timeout.connect(_lanzar_evento_balaam)

	$PanelInicio/BtnJugar.pressed.connect(_iniciar_partida)

	# La pantalla de inicio no tenía ninguna salida: entrando desde el Libro de
	# Historia el jugador quedaba obligado a jugar una ronda entera para poder
	# volver. Solo se ofrece en modo libre; abierto desde un diálogo, saltárselo
	# de entrada dejaría la historia sin el minijuego.
	var btn_salir_inicio: Button = $PanelInicio.get_node_or_null("BtnSalirInicio")
	if btn_salir_inicio:
		btn_salir_inicio.visible = modo_libre
		if modo_libre:
			btn_salir_inicio.pressed.connect(_salir)
	$PanelDerrota/BtnReintentar.pressed.connect(_reiniciar)
	$PanelDerrota/BtnSalir.pressed.connect(_salir)
	$PanelVictoria/BtnContinuar.pressed.connect(_salir)

	aviso.hide()
	mensaje.hide()
	panel_derrota.hide()
	panel_victoria.hide()
	panel_inicio.show()

	_preparar_partida()


func _cargar_config() -> void:
	cfg = {}
	if not FileAccess.file_exists(RUTA_CONFIG):
		push_warning("No se encontro %s; Atlas-Bird usa sus valores por defecto." % RUTA_CONFIG)
		return
	var archivo := FileAccess.open(RUTA_CONFIG, FileAccess.READ)
	var json := JSON.new()
	if json.parse(archivo.get_as_text()) == OK and typeof(json.data) == TYPE_DICTIONARY:
		cfg = json.data
	else:
		push_warning("atlasbird.json tiene un error de formato; se usan los valores por defecto.")


## Lee cfg["seccion"]["clave"] con valor de respaldo.
func _ajuste(seccion: String, clave: String, defecto):
	var bloque = cfg.get(seccion, {})
	if typeof(bloque) == TYPE_DICTIONARY:
		return bloque.get(clave, defecto)
	return defecto


# ---------------------------------------------------------------- ciclo de vida

func _preparar_partida() -> void:
	estado = Estado.INICIO
	tiempo_restante = float(cfg.get("tiempo_inicial", 90.0))
	tiempo_juego = 0.0
	vidas = int(cfg.get("vidas_iniciales", 3))
	escudo = false
	velocidad_actual = float(_ajuste("pipes", "velocidad_inicial", 110.0))
	hueco_actual = float(_ajuste("pipes", "hueco_inicial", 118.0))

	timer_pipes.stop()
	timer_eventos.stop()
	_detener_sacudida()
	_limpiar_moviles()
	atlas.reiniciar()
	_actualizar_hud()


func _iniciar_partida() -> void:
	panel_inicio.hide()
	estado = Estado.JUGANDO
	atlas.activo = true
	timer_pipes.wait_time = float(_ajuste("pipes", "intervalo_inicial", 2.2))
	timer_pipes.start()
	_programar_evento(float(_ajuste("eventos_balaam", "primer_evento", 20.0)))


func _reiniciar() -> void:
	panel_derrota.hide()
	_preparar_partida()
	_iniciar_partida()


func _salir() -> void:
	if modo_libre:
		SceneTransition.change_scene(ESCENA_LIBRO)
	else:
		juego_completado.emit()


func _limpiar_moviles() -> void:
	for nodo in get_tree().get_nodes_in_group("moviles_ab"):
		nodo.queue_free()


# ------------------------------------------------------------------ cada cuadro

func _process(delta: float) -> void:
	_mover_fondo(delta)
	_mover_balaam(delta)
	_actualizar_sacudida(delta)   # antes del return: debe seguir aunque no se juegue

	if estado != Estado.JUGANDO:
		return

	tiempo_juego += delta
	tiempo_restante -= delta
	_actualizar_dificultad()
	_actualizar_reloj()

	if tiempo_restante <= 0.0:
		_victoria()


func _mover_fondo(delta: float) -> void:
	var v: float = velocidad_actual * 0.35 if estado == Estado.JUGANDO else 22.0
	var ancho: float = fondo_a.texture.get_width() * fondo_a.scale.x
	for s in [fondo_a, fondo_b]:
		s.position.x -= v * delta
		if s.position.x <= -ancho:
			s.position.x += ancho * 2.0


func _mover_balaam(delta: float) -> void:
	_reloj_balaam += delta
	balaam.position.y = 150.0 + sin(_reloj_balaam * 1.6) * 60.0
	balaam.position.x = 566.0 + sin(_reloj_balaam * 0.7) * 12.0


## La velocidad, el intervalo y el hueco interpolan durante segundos_rampa de
## juego real, asi el minijuego se va acelerando solo aunque Balaam sume tiempo.
func _actualizar_dificultad() -> void:
	var rampa: float = max(1.0, float(_ajuste("pipes", "segundos_rampa", 75.0)))
	var t: float = clampf(tiempo_juego / rampa, 0.0, 1.0)

	velocidad_actual = lerpf(
		float(_ajuste("pipes", "velocidad_inicial", 110.0)),
		float(_ajuste("pipes", "velocidad_final", 215.0)), t)
	hueco_actual = lerpf(
		float(_ajuste("pipes", "hueco_inicial", 118.0)),
		float(_ajuste("pipes", "hueco_final", 92.0)), t)
	timer_pipes.wait_time = lerpf(
		float(_ajuste("pipes", "intervalo_inicial", 2.2)),
		float(_ajuste("pipes", "intervalo_final", 1.0)), t)

	get_tree().call_group("moviles_ab", "set_speed", velocidad_actual)


func _actualizar_reloj() -> void:
	label_tiempo.text = str(int(ceil(max(tiempo_restante, 0.0))))


# ------------------------------------------------------------------- generacion

func _generar_columna() -> void:
	if estado != Estado.JUGANDO or pipe_scene == null:
		return

	var columna = pipe_scene.instantiate()
	contenedor.add_child(columna)
	columna.position.x = X_SPAWN
	var centro := randf_range(
		hueco_actual * 0.5 + MARGEN_HUECO,
		ALTO - hueco_actual * 0.5 - MARGEN_HUECO)
	columna.configurar(centro, hueco_actual, velocidad_actual)

	if randf() < float(_ajuste("objetos", "probabilidad", 0.55)):
		_generar_objeto(centro)


## Los objetos salen en medio del hueco (faciles, se agarran de paso) o pegados
## a una de las columnas (dificiles, hay que arriesgar el roce).
func _generar_objeto(centro_hueco: float) -> void:
	if item_scene == null:
		return
	var tipo := _sortear_tipo()
	if tipo < 0:
		return

	# Justo en el centro del hueco, y en la misma x que la columna: queda
	# exactamente en medio de los dos tubos, se agarra al pasar.
	var y := centro_hueco
	# La variante dificil (pegada a un tubo) sigue aqui pero apagada:
	# "probabilidad_dificil" esta en 0 dentro de atlasbird.json. Subirlo la
	# devuelve sin tocar codigo.
	if randf() < float(_ajuste("objetos", "probabilidad_dificil", 0.0)):
		var borde: float = hueco_actual * 0.5 - 10.0
		y = centro_hueco + (borde if randf() < 0.5 else -borde)

	var objeto = item_scene.instantiate()
	contenedor.add_child(objeto)
	objeto.position = Vector2(X_SPAWN, y)
	objeto.configurar(tipo, velocidad_actual)


## Devuelve el tipo de objeto que sale, o -1 si esa columna se queda sin nada.
##
## El sorteo corre SIEMPRE sobre la bolsa completa, incluidos los premios que
## ahora mismo no sirven, y esos devuelven -1. Es a proposito: si se sacaran de
## la bolsa, su probabilidad se repartiria entre los demas y bastaria con
## agarrar un escudo para que empezaran a llover turbos. Asi, quitar una opcion
## baja la cantidad total de objetos en vez de concentrarla en otro.
func _sortear_tipo() -> int:
	var bolsa: Array[int] = []
	for i in int(_ajuste("objetos", "peso_turbo", 3)):
		bolsa.append(2)    # ItemRush.Tipo.TURBO
	for i in int(_ajuste("objetos", "peso_escudo", 3)):
		bolsa.append(1)    # ItemRush.Tipo.ESCUDO
	for i in int(_ajuste("objetos", "peso_vida", 2)):
		bolsa.append(0)    # ItemRush.Tipo.VIDA
	for i in int(_ajuste("objetos", "peso_nada", 4)):
		bolsa.append(-1)   # casilla vacia
	if bolsa.is_empty():
		return -1

	var tipo: int = bolsa.pick_random()

	# Un escudo encima de otro escudo no acumula nada, y un corazon con las 3
	# vidas tampoco: en esos casos la casilla se queda vacia.
	if tipo == 1 and escudo:
		return -1
	if tipo == 0 and vidas >= int(cfg.get("vidas_maximas", 3)):
		return -1
	return tipo


# ------------------------------------------------------------------ interaccion

## La llaman las columnas (grupo "mundo_ab") cuando tocan a Atlas.
func atlas_choco() -> void:
	if estado != Estado.JUGANDO or atlas.invulnerable:
		return

	if escudo:
		escudo = false
		_actualizar_hud()
		_mostrar_mensaje("El escudo aguantó el golpe")
		_sacudir(sacudida_fuerza * 0.55)   # el escudo amortigua: sacude menos
		atlas.activar_invulnerabilidad(0.9)
		return

	vidas -= 1
	_actualizar_hud()
	_sacudir(sacudida_fuerza)
	if vidas <= 0:
		_derrota()
	else:
		atlas.activar_invulnerabilidad(float(cfg.get("invulnerabilidad", 1.2)))


func _on_toco_suelo() -> void:
	atlas_choco()


## La llaman los objetos recogibles (grupo "mundo_ab").
func recoger_objeto(tipo: int) -> void:
	match tipo:
		0:
			vidas = min(vidas + 1, int(cfg.get("vidas_maximas", 3)))
			_mostrar_mensaje("Una vida más")
		1:
			escudo = true
			_mostrar_mensaje("Escudo listo: aguanta un choque")
		2:
			var resta := float(_ajuste("objetos", "turbo_segundos", 5.0))
			tiempo_restante = max(tiempo_restante - resta, 0.0)
			_mostrar_mensaje(str(_ajuste("avisos", "turbo", "Turbo")))
			_actualizar_reloj()
			if tiempo_restante <= 0.0:
				_victoria()
	_actualizar_hud()


# ------------------------------------------------------------ eventos de Balaam

func _programar_evento(segundos: float) -> void:
	timer_eventos.start(segundos)


func _lanzar_evento_balaam() -> void:
	if estado != Estado.JUGANDO:
		_programar_evento(4.0)   # reintenta cuando el juego vuelva a correr
		return

	var tipo := "invertir" if randf() < 0.5 else "tiempo"
	_avisar_y_aplicar(tipo)


## Corta la generacion de columnas, muestra el cuadro de Atlas para que el
## jugador alcance a leer que le hizo Balaam y hasta entonces aplica el efecto.
## Las columnas que ya venian en camino terminan de salir solas, asi la pantalla
## queda limpia mientras se lee.
func _avisar_y_aplicar(tipo: String) -> void:
	estado = Estado.AVISO
	timer_pipes.stop()

	aviso_texto.text = str(_ajuste("avisos", tipo, "Balaam hizo de las suyas"))
	aviso.show()

	await get_tree().create_timer(float(_ajuste("eventos_balaam", "duracion_aviso", 3.0))).timeout

	# Si el dialogo ya cerro el minijuego mientras corria la espera, este nodo
	# esta en camino de liberarse y tocar sus hijos reventaria.
	if not is_inside_tree():
		return
	aviso.hide()

	# Puede que el jugador haya perdido o ganado mientras leia el aviso.
	if estado != Estado.AVISO:
		return

	estado = Estado.JUGANDO
	timer_pipes.start()

	if tipo == "invertir":
		_aplicar_inversion()
	else:
		tiempo_restante += float(_ajuste("eventos_balaam", "segundos_castigo", 10.0))
		_actualizar_reloj()

	var minimo := float(_ajuste("eventos_balaam", "intervalo_min", 18.0))
	var maximo := float(_ajuste("eventos_balaam", "intervalo_max", 25.0))
	_programar_evento(randf_range(minimo, maximo))


func _aplicar_inversion() -> void:
	atlas.controles_invertidos = true
	await get_tree().create_timer(float(_ajuste("eventos_balaam", "duracion_inversion", 8.0))).timeout
	if not is_inside_tree():
		return
	atlas.controles_invertidos = false
	if estado == Estado.JUGANDO:
		_mostrar_mensaje(str(_ajuste("avisos", "invertir_fin", "Controles normales")))


# -------------------------------------------------------------------- desenlace

func _victoria() -> void:
	if estado == Estado.VICTORIA:
		return
	estado = Estado.VICTORIA
	tiempo_restante = 0.0
	_actualizar_reloj()
	_terminar()
	panel_victoria.show()


func _derrota() -> void:
	if estado == Estado.DERROTA:
		return
	estado = Estado.DERROTA
	_terminar()
	panel_derrota.show()


func _terminar() -> void:
	atlas.activo = false
	atlas.controles_invertidos = false
	timer_pipes.stop()
	timer_eventos.stop()
	aviso.hide()
	_detener_sacudida()
	get_tree().call_group("moviles_ab", "detener")


# -------------------------------------------------------------------------- HUD

func _actualizar_hud() -> void:
	for i in corazones.size():
		corazones[i].visible = i < vidas
	icono_escudo.visible = escudo
	_actualizar_reloj()

	# Los objetos que ya venian en camino y dejaron de servir se retiran solos.
	get_tree().call_group("objetos_ab", "revisar_utilidad",
		escudo, vidas >= int(cfg.get("vidas_maximas", 3)))


# --------------------------------------------------------------------- sacudida

## Sacude la pantalla moviendo el nodo raiz, no una camara: este minijuego no
## tiene Camera2D y, cuando lo abre un dialogo, vive dentro de un CanvasLayer
## donde la camara del nivel ni siquiera aplica. Al mover la raiz se sacude todo
## a la vez (fondo, columnas, Atlas y marcador) sin descuadrar nada, porque las
## posiciones de spawn son locales a sus nodos.
func _sacudir(fuerza: float) -> void:
	_sacudida_actual = fuerza
	_sacudida_total = max(sacudida_duracion, 0.01)
	_sacudida_restante = _sacudida_total


func _actualizar_sacudida(delta: float) -> void:
	if _sacudida_restante <= 0.0:
		return

	_sacudida_restante -= delta
	if _sacudida_restante <= 0.0:
		_detener_sacudida()
		return

	# Se va apagando sola para que el ultimo tramo no quede vibrando.
	var fuerza: float = _sacudida_actual * (_sacudida_restante / _sacudida_total)
	position = Vector2(randf_range(-fuerza, fuerza), randf_range(-fuerza, fuerza))


## Deja la pantalla exactamente en su sitio. Importante antes de mostrar un
## panel: sus velos son de 640x360 justos y desplazados dejarian una franja sin
## cubrir en el borde.
func _detener_sacudida() -> void:
	_sacudida_restante = 0.0
	position = Vector2.ZERO


func _mostrar_mensaje(texto: String) -> void:
	mensaje.text = texto
	mensaje.modulate.a = 1.0
	mensaje.show()
	var tween := create_tween()
	tween.tween_interval(1.1)
	tween.tween_property(mensaje, "modulate:a", 0.0, 0.5)
	tween.tween_callback(mensaje.hide)
