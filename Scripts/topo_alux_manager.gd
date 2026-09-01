extends Node2D

signal juego_completado

## Color del texto al completar el minijuego: 3e2723, el mismo café oscuro de los
## botones del menú principal.
const COLOR_COMPLETADO := Color("3e2723")
const ESCENA_LIBRO := "res://Scenes/LibroHistoria.tscn"
## Clave con la que se recuerda que el jugador ya vio el "Cómo jugar".
const CLAVE_TUTORIAL := "topo_tutorial_visto"

@export var golpes_necesarios: int = 15
## Segundos para atrapar a Kaan. Al llegar a 0 se pierde.
@export var segundos_partida: float = 45.0
@export var label_puntuacion: Label
@export var cuadro_dialogo: Node2D

var golpes_acertados: int = 0
var hoyos: Array = []
var timer_spawn: Timer

## Solo corre el reloj mientras esto es true: se apaga al ganar, al perder y
## mientras la ficha de "Cómo jugar" está abierta.
var jugando: bool = false
var tiempo_restante: float = 0.0
## Color del marcador tal como viene de la escena, para poder devolvérselo al
## reiniciar después de que ganar_juego() lo haya pintado.
var _color_marcador: Color = Color.BLACK

## Lo asigna DialogoManager si algún día se lanza desde dialogos.json. Este
## minijuego no tiene niveles, pero la interfaz común de minijuegos lo pide.
var nivel_a_cargar: String = ""
## true cuando se entró desde el Libro de Historia (esta escena ES la escena
## actual) y false cuando alguien la instanció encima de otra cosa.
var modo_libre: bool = false

# Texturas
var tex_atlas = preload("res://Images/Personajes/Atlas/atlas_cara.png")

# Script del topo (se cargará al instanciar)
const ScriptTopo = preload("res://Scripts/topo_entidad.gd")

@onready var panel_como_jugar: Node2D = get_node_or_null("PanelComoJugar")
@onready var btn_salir: Button = get_node_or_null("BtnSalir")
@onready var btn_como_jugar: Button = get_node_or_null("BtnComoJugar")
@onready var label_tiempo: Label = get_node_or_null("Cronometro/LabelTiempo")
@onready var panel_derrota: Node2D = get_node_or_null("PanelDerrota")


func _ready():
	modo_libre = (get_parent() == get_tree().root)

	# El orden importa: antes los agujeros y el timer se creaban DESPUÉS de la
	# rama que llama a _iniciar_juego(), así que si no había cuadro de diálogo
	# asignado el juego reventaba al arrancar con timer_spawn en null.
	_preparar_agujeros()
	_preparar_timer()
	actualizar_marcador()

	if label_puntuacion:
		_color_marcador = label_puntuacion.get_theme_color("font_color")

	tiempo_restante = segundos_partida
	_actualizar_reloj()

	if panel_derrota:
		panel_derrota.hide()
		var btn_re: Button = panel_derrota.get_node_or_null("BtnReiniciar")
		if btn_re:
			btn_re.pressed.connect(_reiniciar)

	# Salir solo tiene sentido entrando desde el Libro de Historia: ahí esta
	# escena ES la escena actual y no hay nadie más que devuelva el control.
	# Abierta desde un diálogo, quien cierra el minijuego es el propio diálogo
	# al recibir "juego_completado", así que el botón sobra.
	if btn_salir:
		btn_salir.visible = modo_libre
		if modo_libre:
			btn_salir.pressed.connect(_salir)

	if btn_como_jugar:
		btn_como_jugar.pressed.connect(_abrir_como_jugar)

	if panel_como_jugar:
		panel_como_jugar.hide()
		var meta: Label = panel_como_jugar.get_node_or_null("LabelMeta")
		if meta:
			meta.text = "Atrapa %d veces al Kaan verdadero para completarlo." % golpes_necesarios
		var btn: Button = panel_como_jugar.get_node_or_null("BtnEntendido")
		if btn:
			btn.pressed.connect(_cerrar_como_jugar)

	if _debe_mostrar_como_jugar():
		panel_como_jugar.show()
	else:
		_arrancar_presentacion()


## Los agujeros se ponen en la escena (nodo "Agujeros"); si faltan, se inventan
## tres para que el minijuego siga siendo jugable.
func _preparar_agujeros() -> void:
	var grupo_agujeros = get_node_or_null("Agujeros")
	if not grupo_agujeros:
		grupo_agujeros = Node2D.new()
		grupo_agujeros.name = "Agujeros"
		add_child(grupo_agujeros)
		for i in range(3):
			var m = Marker2D.new()
			m.position = Vector2(100 + (i * 150), 200)
			grupo_agujeros.add_child(m)
	hoyos = grupo_agujeros.get_children()


func _preparar_timer() -> void:
	timer_spawn = Timer.new()
	timer_spawn.wait_time = 1.2
	timer_spawn.autostart = false
	timer_spawn.timeout.connect(_on_spawn_timeout)
	add_child(timer_spawn)


# ------------------------------------------------------------------ cómo jugar

func _debe_mostrar_como_jugar() -> bool:
	if panel_como_jugar == null:
		return false
	return not Global.eventos_completados.get(CLAVE_TUTORIAL, false)


## Lo abre el botón "Cómo jugar", que solo existe antes de empezar a jugar.
##
## El cuadro de diálogo escucha con _input y no con _gui_input, y _input corre
## ANTES que la GUI: el mismo clic que pulsa este botón le llega también al
## diálogo, lo da por leído y dispara _iniciar_juego. No se puede evitar sin
## tocar DialogoManager (lo usan las 6 escenas de nivel), así que en vez de
## evitarlo se deshace: se para el juego que acaba de arrancar, se limpian los
## topos que hayan alcanzado a salir y al cerrar la ficha se vuelve a mostrar la
## línea de Atlas desde el principio, como si nunca se hubiera tocado.
func _abrir_como_jugar() -> void:
	if panel_como_jugar == null or panel_como_jugar.visible:
		return

	jugando = false          # el reloj se congela mientras se lee la ficha
	timer_spawn.stop()
	_limpiar_topos()

	if btn_como_jugar:
		btn_como_jugar.show()
		btn_como_jugar.disabled = false
	if cuadro_dialogo:
		cuadro_dialogo.hide()

	panel_como_jugar.show()


func _cerrar_como_jugar() -> void:
	# Se marca al cerrarlo, igual que el resto de eventos de un solo uso: así no
	# vuelve a salir solo en la siguiente partida (el botón sigue estando).
	Global.eventos_completados[CLAVE_TUTORIAL] = true
	panel_como_jugar.hide()

	# Siempre se vuelve a la línea de Atlas. El juego NO arranca al cerrar esta
	# ficha, sino cuando el jugador toque la pantalla para pasar el diálogo.
	_arrancar_presentacion()


func _ocultar_como_jugar() -> void:
	if btn_como_jugar and btn_como_jugar.visible:
		btn_como_jugar.hide()
		btn_como_jugar.disabled = true


func _limpiar_topos() -> void:
	for h in hoyos:
		for t in h.get_children():
			t.queue_free()


## Después del tutorial va la línea de Atlas y, cuando termina, arranca el juego.
func _arrancar_presentacion() -> void:
	if cuadro_dialogo:
		if not cuadro_dialogo.dialogo_terminado.is_connected(_iniciar_juego):
			cuadro_dialogo.dialogo_terminado.connect(_iniciar_juego)

		cuadro_dialogo._cargar_dialogos()
		if cuadro_dialogo.dialogos_cargados.has("minijuego_topo"):
			cuadro_dialogo.id_dialogo_actual = "minijuego_topo"
			cuadro_dialogo.dialogo_actual = cuadro_dialogo.dialogos_cargados["minijuego_topo"]
			cuadro_dialogo.indice_dialogo = 0
			cuadro_dialogo._mostrar_linea_actual()
			cuadro_dialogo.show()
			return

	# Sin cuadro de diálogo (o sin esa entrada en el JSON) se juega directo.
	_iniciar_juego("")


# ----------------------------------------------------------------------- juego

func _process(delta: float) -> void:
	if not jugando:
		return
	tiempo_restante = max(tiempo_restante - delta, 0.0)
	_actualizar_reloj()
	if tiempo_restante <= 0.0:
		perder_juego()


func _actualizar_reloj() -> void:
	if label_tiempo:
		label_tiempo.text = str(int(ceil(max(tiempo_restante, 0.0))))


## Arranca al terminar el diálogo, o sea con el toque del jugador en la pantalla.
func _iniciar_juego(_id = ""):
	tiempo_restante = segundos_partida
	_actualizar_reloj()
	jugando = true
	timer_spawn.start()


func _on_spawn_timeout():
	# El primer topo es lo que marca que la partida ya va en serio: hasta aquí
	# la ficha de ayuda sigue disponible.
	#
	# Esconderla en _iniciar_juego NO funciona, y así estaba roto el botón: el
	# cuadro de diálogo escucha con _input, que corre antes que la GUI, así que
	# el mismo clic que pulsa "Cómo jugar" termina el diálogo y dispara
	# _iniciar_juego en el mouse DOWN. El botón se ocultaba antes del mouse UP y
	# un Button oculto o deshabilitado ya no emite "pressed": el botón no hacía
	# nada. Aquí llega 1.2 s después, con el clic hace rato terminado.
	_ocultar_como_jugar()
	# Primero, buscamos qué hoyos están completamente vacíos
	var hoyos_vacios = []
	for h in hoyos:
		if h.get_child_count() == 0:
			hoyos_vacios.append(h)

	if hoyos_vacios.is_empty():
		return

	# Cuántos topos saldrán de golpe (1 a 3)
	var cantidad = randi_range(1, 3)
	# No intentar sacar más topos que hoyos vacíos disponibles
	cantidad = min(cantidad, hoyos_vacios.size())

	# Barajamos los hoyos vacíos para que salgan en posiciones aleatorias
	hoyos_vacios.shuffle()

	# Elegimos al azar cuál de los topos que van a salir será el verdadero Kaan
	var indice_kaan_real = randi_range(0, cantidad - 1)

	for i in range(cantidad):
		var hoyo = hoyos_vacios[i]

		# Crear una nueva entidad Area2D (el topo) usando nuestro script por código
		var topo = Area2D.new()
		topo.set_script(ScriptTopo)

		# Si su índice coincide con el que elegimos, es el real. Si no, es señuelo garantizado.
		topo.es_kaan = (i == indice_kaan_real)

		hoyo.add_child(topo)

		# Conectar señal de golpe
		topo.topo_aplastado.connect(_on_topo_aplastado)

	# Variar un poco el tiempo de aparición para que sea más dinámico
	timer_spawn.wait_time = randf_range(1.0, 1.5)


func _on_topo_aplastado(fue_kaan: bool):
	if fue_kaan:
		golpes_acertados += 1
		actualizar_marcador()

		if golpes_acertados >= golpes_necesarios:
			ganar_juego()
	else:
		# Penalización opcional por darle al señuelo
		# golpes_acertados = max(0, golpes_acertados - 1)
		# actualizar_marcador()
		pass


func actualizar_marcador():
	if label_puntuacion:
		label_puntuacion.text = str(golpes_acertados) + " de " + str(golpes_necesarios) + " golpes acertados"


## Se acabó el tiempo sin llegar a los golpes necesarios.
func perder_juego() -> void:
	if not jugando:
		return
	jugando = false
	tiempo_restante = 0.0
	_actualizar_reloj()
	timer_spawn.stop()
	_limpiar_topos()
	_ocultar_como_jugar()

	if panel_derrota:
		panel_derrota.show()


## Vuelve a empezar desde cero. No pasa por el diálogo: quien pulsa "Reiniciar"
## ya sabe de qué va y quiere jugar otra vez, no volver a leer.
func _reiniciar() -> void:
	if panel_derrota:
		panel_derrota.hide()

	golpes_acertados = 0
	actualizar_marcador()
	if label_puntuacion:
		# Por si veníamos de una victoria, que dejó el marcador en café oscuro.
		label_puntuacion.add_theme_color_override("font_color", _color_marcador)

	_limpiar_topos()
	_iniciar_juego("")


func ganar_juego():
	jugando = false
	timer_spawn.stop()
	label_puntuacion.text = "¡MINIJUEGO COMPLETADO!"
	label_puntuacion.add_theme_color_override("font_color", COLOR_COMPLETADO)

	# Los topos que quedaron asomados se retiran, si no siguen siendo clicables.
	_limpiar_topos()

	if modo_libre:
		# Desde el libro manda el jugador: se queda leyendo y sale cuando quiera.
		if btn_salir:
			btn_salir.text = "Volver"
	else:
		# Abierto desde un diálogo: se deja ver el mensaje y se devuelve el control.
		await get_tree().create_timer(3.0).timeout
		juego_completado.emit()


## Salida siempre disponible. Antes esta escena no tenía ninguna: al entrar desde
## el Libro de Historia el jugador se quedaba encerrado.
func _salir() -> void:
	if modo_libre:
		SceneTransition.change_scene(ESCENA_LIBRO)
	else:
		juego_completado.emit()
