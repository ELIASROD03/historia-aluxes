extends Node

var personaje_seleccionado: String = "Personaje1"
var ruta_spritesheet: String = "res://Images/Personajes/Personajes_Principales/personaje1/respirando.png"
var ruta_walk: String = "res://Images/Personajes/Personajes_Principales/personaje1/caminando.png"
var en_dialogo: bool = false
var progreso_historia: int = 1 # 1 = Tenochtitlan, 2 = Siguiente época, etc.
var conoce_atlas: bool = false
var nombre_jugador: String = "Jugador"
var anio_objetivo_actual: String = "1519"

var titulo_pantalla: String = ""
var subtitulo_pantalla: String = ""
var destino_pantalla: String = "res://Scenes/MenuPrincipal.tscn"

func _process(delta: float) -> void:
	if not get_tree().paused:
		tiempo_juego += delta

# --- SISTEMA DE CAPITULOS ---
# La tabla de capitulos (numero, titulo, subtitulo, año, escena y dialogos) vive
# en res://capitulos.json. Antes estos datos estaban copiados en iu_maquina.gd,
# tenoch_manager.gd y tenoch1520_manager.gd, y era facil actualizar uno y olvidar
# los demas. Ahora todos preguntan aqui.

const RUTA_CAPITULOS := "res://capitulos.json"
const ESCENA_TRANSICION := "res://Scenes/Capitulo1Intro.tscn"
const ESCENA_LABORATORIO := "res://Scenes/Laboratorio.tscn"
const ESCENA_MENU := "res://Scenes/MenuPrincipal.tscn"

var capitulos: Array = []

func _ready() -> void:
	_cargar_capitulos()

func _cargar_capitulos() -> void:
	capitulos = []
	if not FileAccess.file_exists(RUTA_CAPITULOS):
		push_error("No se encontro %s: los capitulos no van a cargar." % RUTA_CAPITULOS)
		return
	var archivo := FileAccess.open(RUTA_CAPITULOS, FileAccess.READ)
	if archivo == null:
		return
	var json := JSON.new()
	var ok := json.parse(archivo.get_as_text()) == OK
	archivo.close()
	if not ok or typeof(json.data) != TYPE_DICTIONARY:
		push_error("capitulos.json tiene un error de sintaxis.")
		return
	var lista = json.data.get("capitulos", [])
	if typeof(lista) == TYPE_ARRAY:
		capitulos = lista

func total_capitulos() -> int:
	return capitulos.size()

## Datos del capitulo pedido, o {} si no existe.
func obtener_capitulo(numero: int) -> Dictionary:
	for cap in capitulos:
		if typeof(cap) == TYPE_DICTIONARY and int(cap.get("numero", 0)) == numero:
			return cap
	return {}

func capitulo_actual() -> Dictionary:
	return obtener_capitulo(progreso_historia)

## Deja listos los textos y el destino de la pantalla negra de transicion.
func preparar_transicion(titulo: String, subtitulo: String, destino: String) -> void:
	titulo_pantalla = titulo
	subtitulo_pantalla = subtitulo
	destino_pantalla = destino

## Pantalla "Capitulo N / <subtitulo>" antes de entrar al nivel.
## Devuelve false si el capitulo no existe o su escena falta; asi quien la llama
## puede avisar en vez de mandar al jugador a una pantalla negra sin salida.
func preparar_entrada_capitulo(numero: int) -> bool:
	var cap := obtener_capitulo(numero)
	if cap.is_empty():
		push_error("No hay capitulo %d en capitulos.json." % numero)
		return false
	var escena := str(cap.get("escena", ""))
	if not ResourceLoader.exists(escena):
		push_error("El capitulo %d apunta a '%s', que no existe." % [numero, escena])
		return false
	preparar_transicion(str(cap.get("titulo", "")), str(cap.get("subtitulo", "")), escena)
	return true

## Pantalla "Capitulo N / ¡COMPLETADO!" al terminar el nivel.
func preparar_capitulo_completado(numero: int, destino: String = ESCENA_LABORATORIO) -> void:
	var cap := obtener_capitulo(numero)
	preparar_transicion(str(cap.get("titulo", "Capítulo %d" % numero)), "¡COMPLETADO!", destino)

## Avanza al siguiente capitulo y deja puesto el año que pedira la maquina.
func avanzar_capitulo() -> void:
	progreso_historia += 1
	var siguiente := obtener_capitulo(progreso_historia)
	if not siguiente.is_empty():
		anio_objetivo_actual = str(siguiente.get("anio", anio_objetivo_actual))

## Año que la maquina del tiempo espera para el capitulo en curso.
func anio_del_capitulo_actual() -> String:
	var cap := capitulo_actual()
	return str(cap.get("anio", "0000")) if not cap.is_empty() else "0000"

# --- SISTEMA DE GUARDADO ---
var escena_actual: String = "res://Scenes/Laboratorio.tscn"
var posicion_x: float = 0.0
var posicion_y: float = 0.0
var flag_cargar_posicion: bool = false
var tiempo_juego: float = 0.0
var eventos_completados: Dictionary = {}
var slot_actual: String = "save_1"

const RUTA_MAESTRA = "res://Saves/partidas.json"

func _cargar_archivo_maestro() -> Dictionary:
	if not FileAccess.file_exists(RUTA_MAESTRA):
		return {}
	var file = FileAccess.open(RUTA_MAESTRA, FileAccess.READ)
	if file:
		var json_str = file.get_as_text()
		file.close()
		var json = JSON.new()
		if json.parse(json_str) == OK:
			var data = json.get_data()
			if typeof(data) == TYPE_DICTIONARY:
				return data
	return {}

func _guardar_archivo_maestro(data: Dictionary) -> void:
	if not DirAccess.dir_exists_absolute("res://Saves"):
		DirAccess.make_dir_absolute("res://Saves")
	var file = FileAccess.open(RUTA_MAESTRA, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()

func iniciar_nueva_partida(nombre: String, personaje_id: String, ruta_sheet: String, ruta_wlk: String) -> bool:
	var partidas_actuales = obtener_partidas()
	if partidas_actuales.size() >= 5:
		return false
		
	# Reiniciar variables globales a sus valores por defecto
	nombre_jugador = nombre
	personaje_seleccionado = personaje_id
	ruta_spritesheet = ruta_sheet
	ruta_walk = ruta_wlk
	en_dialogo = false
	progreso_historia = 1
	conoce_atlas = false
	anio_objetivo_actual = anio_del_capitulo_actual()
	# La pantalla de transicion tambien se limpia: si no, una partida nueva podia
	# heredar el letrero y el destino de la partida anterior.
	titulo_pantalla = ""
	subtitulo_pantalla = ""
	destino_pantalla = ESCENA_MENU
	escena_actual = ESCENA_LABORATORIO
	posicion_x = 0.0
	posicion_y = 0.0
	flag_cargar_posicion = false
	tiempo_juego = 0.0
	eventos_completados = {}
	
	# Generar un slot único usando timestamp (ej: save_20260708_173045)
	var time = Time.get_datetime_dict_from_system()
	slot_actual = "save_%d%02d%02d_%02d%02d%02d" % [time.year, time.month, time.day, time.hour, time.minute, time.second]
	
	# Crear el archivo de guardado inicial
	guardar_partida(slot_actual)
	return true

func obtener_datos_guardado() -> Dictionary:
	return {
		"nombre_jugador": nombre_jugador,
		"personaje_seleccionado": personaje_seleccionado,
		"ruta_spritesheet": ruta_spritesheet,
		"ruta_walk": ruta_walk,
		"progreso_historia": progreso_historia,
		"conoce_atlas": conoce_atlas,
		"anio_objetivo_actual": anio_objetivo_actual,
		"escena_actual": escena_actual,
		"posicion_x": posicion_x,
		"posicion_y": posicion_y,
		"tiempo_juego": tiempo_juego,
		"eventos_completados": eventos_completados
	}

func guardar_partida(slot: String = slot_actual) -> void:
	# Actualizar posición si el jugador existe en la escena activa
	var tree = get_tree()
	if tree and tree.current_scene:
		var player = tree.current_scene.find_child("Player", true, false)
		if player:
			posicion_x = player.global_position.x
			posicion_y = player.global_position.y
			escena_actual = tree.current_scene.scene_file_path

	var data = obtener_datos_guardado()
	var maestro = _cargar_archivo_maestro()
	maestro[slot] = data
	_guardar_archivo_maestro(maestro)
	print("Partida guardada exitosamente en el slot: ", slot)

func cargar_partida(slot: String) -> bool:
	var maestro = _cargar_archivo_maestro()
	if maestro.has(slot):
		var data = maestro[slot]
		nombre_jugador = data.get("nombre_jugador", "Jugador")
		personaje_seleccionado = data.get("personaje_seleccionado", "Personaje1")
		ruta_spritesheet = data.get("ruta_spritesheet", "res://Images/Personajes/Personajes_Principales/personaje1/respirando.png")
		ruta_walk = data.get("ruta_walk", "res://Images/Personajes/Personajes_Principales/personaje1/caminando.png")
		progreso_historia = data.get("progreso_historia", 1)
		conoce_atlas = data.get("conoce_atlas", false)
		anio_objetivo_actual = data.get("anio_objetivo_actual", "1519")
		escena_actual = data.get("escena_actual", "res://Scenes/Laboratorio.tscn")
		posicion_x = float(data.get("posicion_x", 0.0))
		posicion_y = float(data.get("posicion_y", 0.0))
		tiempo_juego = float(data.get("tiempo_juego", 0.0))
		eventos_completados = data.get("eventos_completados", {})
		slot_actual = slot
		flag_cargar_posicion = true
		return true
	return false

func obtener_partidas() -> Array:
	var partidas = []
	var maestro = _cargar_archivo_maestro()
	
	for slot_id in maestro.keys():
		var data = maestro[slot_id]
		partidas.append({
			"slot": slot_id,
			"nombre": data.get("nombre_jugador", "Desconocido"),
			"personaje": data.get("personaje_seleccionado", "N/A"),
			"tiempo": float(data.get("tiempo_juego", 0.0)),
			"progreso": int(data.get("progreso_historia", 1)),
			"ruta_spritesheet": data.get("ruta_spritesheet", "")
		})
		
	# Ordenar para que aparezcan en orden consistente
	partidas.sort_custom(func(a, b): return a["slot"] < b["slot"])
	return partidas

func eliminar_partida(slot: String) -> void:
	var maestro = _cargar_archivo_maestro()
	if maestro.has(slot):
		maestro.erase(slot)
		_guardar_archivo_maestro(maestro)
