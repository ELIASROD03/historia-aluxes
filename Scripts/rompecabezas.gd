extends Control

## Minijuego de rompecabezas: el jugador arrastra las piezas hasta armar la imagen
## antes de que se acabe el tiempo.
##
## Flujo: al entrar se ve la imagen del nivel de fondo (difuminada) y el jugador
## elige dificultad -> se cortan las piezas y arranca el reloj -> gana si arma
## todo, pierde si se le acaba el tiempo.
##
## Las piezas NO son archivos aparte: el script toma UNA sola imagen y la corta
## generando la forma clasica de rompecabezas (pestanas y huecos) con geometria,
## no con shader. Cada pieza es un Polygon2D cuyo contorno lleva las pestanas y
## cuyo UV apunta al pedazo correcto de la imagen original.
##
## Cada nivel tiene VARIAS imagenes (normalmente 3). No se listan en el JSON: se
## buscan por convencion en res://Images/img-rompecabezas/nivelN/nivN_V.jpg, asi
## que agregar una imagen nueva es solo meter el archivo en su carpeta. Cual sale:
##   - Lanzado por un dialogo (historia): la primera que no se haya jugado, en
##     orden 1, 2, 3...; ya jugadas todas, una al azar.
##   - Entrando desde el Libro de Historia: la elige el jugador en PanelImagenes.
## Los dos ambitos llevan cuentas separadas (ver AMBITO_HISTORIA / AMBITO_LIBRO),
## para que practicar en el libro no gaste la rotacion de la historia.
##
## Los bordes internos se generan UNA vez y las dos piezas vecinas comparten
## exactamente la misma lista de puntos (una al derecho y otra al reves), por eso
## siempre embonan perfecto.

signal juego_completado
signal juego_perdido

const RUTA_CONFIG := "res://rompecabezas.json"
const IMAGEN_FALLBACK := "res://icon.svg"
const SEGUNDOS_POR_DEFECTO := 100.0

## Donde viven las imagenes. Dentro va una carpeta por nivel: "nivel1", "nivel2"...
const CARPETA_IMAGENES := "res://Images/img-rompecabezas"
## Se prueban en este orden para cada numero, y se queda con la primera que exista.
const EXTENSIONES_IMAGEN := ["jpg", "png", "jpeg", "webp"]
## Hasta cuantas imagenes se buscan por nivel. Con 3 es lo normal; sobra margen
## por si algun nivel lleva mas.
const MAX_VARIANTES := 9

## Las dos cuentas de "ya jugada", separadas a proposito: lo que el jugador arma
## en el Libro de Historia no adelanta la rotacion de la historia.
const AMBITO_HISTORIA := "historia"
const AMBITO_LIBRO := "libro"

## El rotulo de las miniaturas va sobre un marco oscuro, no sobre pergamino: el
## color_texto_normal (cafe) ahi no se leeria.
const COLOR_TEXTO_TARJETA := Color(1.0, 0.97, 0.90, 1.0)

## Ancho que de verdad se ve pintado dentro de un boton de 250 px de la rejilla
## de niveles (ver _ajustar_texto_boton).
const ANCHO_UTIL_BOTON := 190.0

## Cuánto se queda en pantalla el rompecabezas ya armado, con su mensaje, antes
## de devolver el control al diálogo.
const ESPERA_VICTORIA := 3.0

## Se usan si rompecabezas.json no trae "_dificultades" o le falta algun dato.
const DIFICULTADES_POR_DEFECTO := {
	"relajado": {"nombre": "Relajado", "filas": 3, "columnas": 3},      # 9 piezas
	"desafiante": {"nombre": "Desafiante", "filas": 4, "columnas": 4},  # 16 piezas
}

## Nivel a cargar. Se puede cambiar desde otro script ANTES de que corra _ready(),
## igual que en palabras_impostoras.gd:
##     var escena = load("res://Scenes/Rompecabezas.tscn").instantiate()
##     escena.nivel_a_cargar = "nivel_2"
@export var nivel_a_cargar: String = "nivel_1"

@export_group("Zonas en pantalla")
## Area maxima donde se arma la imagen. La imagen se ajusta dentro conservando
## su proporcion y se centra. Va debajo del titulo y arriba de los botones.
##
## Con imagenes 3:2 esto da un tablero de 369x246, que es practicamente lo mas
## grande que cabe: lo que le quites de ancho a las columnas de los lados se lo
## quitas al sitio donde esperan las piezas sueltas, y empiezan a encimarse unas
## con otras. El tope de alto son los 640x360 del juego menos el titulo (arriba)
## y la fila de botones (abajo).
@export var area_tablero := Rect2(135, 70, 370, 246)
## Columnas laterales donde aparecen revueltas las piezas al empezar.
@export var area_piezas_izq := Rect2(4, 74, 127, 238)
@export var area_piezas_der := Rect2(509, 74, 127, 238)

@export_group("Ajustes de juego")
## Que tan cerca (en pixeles) debe soltarse una pieza de su lugar para que se acomode sola.
@export var tolerancia_snap: float = 20.0
## Si es true, la pieza mal soltada regresa a la franja de abajo. Si es false, se queda donde la dejaron.
@export var devolver_si_falla: bool = false
## Segundos que le quedan al jugador cuando el reloj se pone rojo.
@export var segundos_alerta: float = 20.0

@export_group("Forma de las pestanas")
## Radio del "boton" de la pestana, relativo al lado mas corto de la pieza.
@export_range(0.05, 0.25) var radio_pestana: float = 0.135
## Que tanto sobresale el centro del boton.
@export_range(0.05, 0.35) var altura_pestana: float = 0.155
## Medio ancho del cuello. Mas chico = pestana mas "atorada".
@export_range(0.03, 0.2) var ancho_cuello: float = 0.085

@export_group("Apariencia")
## Dejalo en false para imagenes normales (fotos o ilustraciones): las suaviza al
## escalarlas. Ponlo en true SOLO si tus imagenes son pixel art.
@export var filtro_pixel_art: bool = false
@export var mostrar_contorno: bool = true
@export var color_contorno := Color(0.16, 0.10, 0.08, 0.9)
@export var color_marco_tablero := Color(0.16, 0.10, 0.08, 0.35)
@export var color_texto_normal := Color(0.24313726, 0.15294118, 0.13725491, 1)
@export var color_texto_alerta := Color(0.75, 0.18, 0.14, 1)
@export var color_victoria := Color(0.98039216, 0.827451, 0.34117648, 1)
@export var color_derrota := Color(0.90196078, 0.34901961, 0.27843137, 1)

@onready var captura_input: Control = $CapturaInput
@onready var tablero: Node2D = $Tablero
@onready var guia: Sprite2D = $Tablero/Guia
@onready var contenedor_piezas: Node2D = $Piezas
@onready var label_titulo: Label = $UI/LabelTitulo
@onready var label_progreso: Label = $UI/LabelProgreso
@onready var label_tiempo: Label = $UI/LabelTiempo
@onready var btn_pista: Button = $UI/BtnPista
@onready var btn_reiniciar: Button = $UI/BtnReiniciar
@onready var mensaje_victoria: Label = $MensajeVictoria
@onready var panel_seleccion: Control = $PanelSeleccion
@onready var btn_relajado: Button = $PanelSeleccion/BtnRelajado
@onready var btn_desafiante: Button = $PanelSeleccion/BtnDesafiante
@onready var lbl_relajado: Label = $PanelSeleccion/LblRelajado
@onready var lbl_desafiante: Label = $PanelSeleccion/LblDesafiante
@onready var btn_volver_niveles: Button = $PanelSeleccion/BtnVolverNiveles
@onready var btn_salir: Button = $UI/BtnSalir
@onready var panel_niveles: Control = $PanelNiveles
@onready var grid_niveles: GridContainer = $PanelNiveles/GridNiveles
@onready var btn_volver_libro: Button = $PanelNiveles/BtnVolverLibro
@onready var panel_imagenes: Control = $PanelImagenes
@onready var fila_imagenes: HBoxContainer = $PanelImagenes/FilaImagenes
@onready var label_nivel_imagenes: Label = $PanelImagenes/LabelNivel
@onready var btn_volver_niveles_img: Button = $PanelImagenes/BtnVolverNiveles

## true cuando el minijuego corre solo (se entro desde el Libro de Historia) y
## false cuando lo abre un dialogo dentro de un nivel. En modo libre el jugador
## escoge el nivel y puede salirse; en modo dialogo el nivel lo fija la historia
## y quien manda de regreso es el dialogo.
var modo_libre: bool = false

# --- Configuracion del nivel actual (leida del JSON) ---
var config: Dictionary = {}
var datos_nivel: Dictionary = {}
var textura: Texture2D
## Rutas de las imagenes del nivel actual, en orden (la 1 primero).
var imagenes_nivel: Array = []
## Cual de esas imagenes se esta armando. -1 = el nivel no tiene ninguna.
var variante_actual: int = -1
## id_nivel -> Array de rutas. Buscar las imagenes toca disco, y la pantalla de
## niveles pregunta por todas cada vez que se abre.
var _cache_imagenes: Dictionary = {}
var filas: int = 3
var columnas: int = 3
var pistas_restantes: int = 3

# --- Estado del tablero ---
var origen_tablero := Vector2.ZERO   # esquina superior izquierda de la imagen armada
var tam_tablero := Vector2.ZERO      # tamano en pantalla de la imagen armada
var ancho_pieza: float = 0.0
var alto_pieza: float = 0.0

# Bordes precalculados, en coordenadas locales del tablero.
# bordes_h[f][c] = borde horizontal de la fila f (0..filas) sobre la columna c, recorrido de izq a der.
# bordes_v[f][c] = borde vertical de la columna c (0..columnas) sobre la fila f, recorrido de arriba a abajo.
var bordes_h: Array = []
var bordes_v: Array = []
var perfil: PackedVector2Array = PackedVector2Array()

# --- Estado del juego ---
var piezas: Array = []          # Array de Dictionary: {nodo, fila, col, destino, colocada}
var pieza_activa: Polygon2D = null
var agarre_offset := Vector2.ZERO
var colocadas: int = 0
var terminado: bool = false
var jugando: bool = false       # true solo mientras se arma: es lo que corre el reloj
var segundos_totales: float = SEGUNDOS_POR_DEFECTO
var tiempo_restante: float = 0.0


func _ready() -> void:
	randomize()
	# Si nuestro padre es la raiz del arbol, esta escena ES la escena actual: se
	# entro desde el libro. Si no, alguien nos instancio encima de un nivel.
	modo_libre = (get_parent() == get_tree().root)

	mensaje_victoria.hide()
	btn_pista.pressed.connect(_on_pista_pressed)
	btn_reiniciar.pressed.connect(_on_reiniciar_pressed)
	btn_relajado.pressed.connect(_elegir_dificultad.bind("relajado"))
	btn_desafiante.pressed.connect(_elegir_dificultad.bind("desafiante"))
	captura_input.gui_input.connect(_on_captura_gui_input)
	btn_salir.pressed.connect(_mostrar_niveles)
	btn_volver_niveles.pressed.connect(_on_volver_desde_dificultad)
	btn_volver_niveles_img.pressed.connect(_mostrar_niveles)
	btn_volver_libro.pressed.connect(_on_volver_libro_pressed)

	_cargar_config()

	if modo_libre:
		_mostrar_niveles()
	elif _imagenes_de(nivel_a_cargar).is_empty():
		# Un diálogo pidió un nivel que todavía no tiene imágenes (p. ej. el 5): en
		# vez de tronar sin textura y dejar al jugador atorado, se cierra solo y el
		# diálogo sigue. En cuanto se copien imágenes a img-rompecabezas/nivelN/,
		# el mismo evento del diálogo ya abre el rompecabezas sin tocar nada más.
		push_warning("El rompecabezas '%s' no tiene imágenes todavía: se salta." % nivel_a_cargar)
		hide()
		juego_completado.emit.call_deferred()
	else:
		preparar_nivel(nivel_a_cargar)


func _process(delta: float) -> void:
	if not jugando or terminado or segundos_totales <= 0.0:
		return
	tiempo_restante -= delta
	if tiempo_restante <= 0.0:
		tiempo_restante = 0.0
		_actualizar_reloj()
		_perder()
		return
	_actualizar_reloj()


# ── Carga del nivel ───────────────────────────────────────────────────────────

func _cargar_config() -> void:
	config = {}
	if not FileAccess.file_exists(RUTA_CONFIG):
		push_warning("No se encontro %s, se usara la configuracion por defecto." % RUTA_CONFIG)
		return
	var archivo := FileAccess.open(RUTA_CONFIG, FileAccess.READ)
	if archivo == null:
		return
	var json := JSON.new()
	if json.parse(archivo.get_as_text()) == OK and typeof(json.data) == TYPE_DICTIONARY:
		config = json.data
	else:
		push_warning("rompecabezas.json tiene un error de sintaxis.")
	archivo.close()


## Deja el nivel listo y muestra la pantalla de dificultad. Todavia no corta las
## piezas: cuantas van depende de lo que elija el jugador.
##
## `variante` es el indice (base 0) de la imagen del nivel que se va a armar.
## Dejalo en -1 para que se elija solo: en modo libre la primera, y en la historia
## la que toque segun la rotacion.
func preparar_nivel(id_nivel: String, variante: int = -1) -> void:
	nivel_a_cargar = id_nivel
	datos_nivel = config.get(id_nivel, {})
	if datos_nivel.is_empty():
		push_warning("El nivel '%s' no existe en rompecabezas.json." % id_nivel)

	imagenes_nivel = _imagenes_de(id_nivel)
	if imagenes_nivel.is_empty():
		variante_actual = -1
	elif variante >= 0:
		variante_actual = clampi(variante, 0, imagenes_nivel.size() - 1)
	elif modo_libre:
		variante_actual = 0
	else:
		variante_actual = _variante_para_historia(imagenes_nivel)

	# Se marca AL LANZAR, no al ganar (igual que el resto de eventos_completados):
	# si el jugador recarga a media escena o pierde, la historia pasa a la imagen
	# siguiente en vez de plantarle la misma otra vez.
	if variante_actual >= 0:
		_marcar_jugada(
			imagenes_nivel[variante_actual],
			AMBITO_LIBRO if modo_libre else AMBITO_HISTORIA
		)

	_limpiar_piezas()
	terminado = false
	jugando = false
	pieza_activa = null
	mensaje_victoria.hide()

	label_titulo.text = _titulo_nivel()
	pistas_restantes = int(datos_nivel.get("pistas_maximas", 3))
	segundos_totales = float(datos_nivel.get("segundos", SEGUNDOS_POR_DEFECTO))
	tiempo_restante = segundos_totales

	textura = _cargar_textura(_ruta_imagen_actual())
	# Rejilla provisional: el tablero mide lo mismo sin importar cuantas piezas sean
	_calcular_tablero()
	_dibujar_marco_tablero()

	# Vista previa: se ve la imagen completa detras del menu, para que el jugador
	# sepa que va a armar.
	guia.texture = textura
	guia.texture_filter = _filtro()
	guia.visible = true
	guia.position = origen_tablero
	guia.scale = tam_tablero / textura.get_size()
	guia.modulate = Color(1, 1, 1, 0.8)

	_mostrar_seleccion()


## ── Imagenes del nivel y rotacion ─────────────────────────────────────────────

## Devuelve las rutas de las imagenes de un nivel, en orden (la "1" primero).
##
## No hace falta listarlas en rompecabezas.json: se buscan por convencion en
## res://Images/img-rompecabezas/nivelN/nivN_V.jpg, donde N es el numero del nivel
## ("nivel_2" -> carpeta "nivel2", prefijo "niv2_"). Por eso agregar una imagen es
## solo copiar el archivo a su carpeta (y abrir Godot una vez, para que la importe).
##
## Se puede saltar la convencion poniendo en el nivel "imagenes" (lista de rutas
## res://), "carpeta" o "prefijo". Un hueco en la numeracion no rompe nada: las
## que existan se toman en orden.
func _imagenes_de(id_nivel: String) -> Array:
	if _cache_imagenes.has(id_nivel):
		return _cache_imagenes[id_nivel]

	var datos: Dictionary = config.get(id_nivel, {})
	var numero := _numero_de_nivel(id_nivel)
	var rutas: Array = []

	# 1) Lista escrita a mano en el JSON, si la hay.
	for ruta in datos.get("imagenes", []):
		if ResourceLoader.exists(str(ruta)):
			rutas.append(str(ruta))

	# 2) Convencion: carpeta del nivel + prefijo numerado.
	if rutas.is_empty():
		var carpeta := str(datos.get("carpeta", "%s/nivel%d" % [CARPETA_IMAGENES, numero]))
		var prefijo := str(datos.get("prefijo", "niv%d_" % numero))
		for v in range(1, MAX_VARIANTES + 1):
			for ext in EXTENSIONES_IMAGEN:
				var ruta := "%s/%s%d.%s" % [carpeta, prefijo, v, ext]
				if ResourceLoader.exists(ruta):
					rutas.append(ruta)
					break   # una sola extension por numero

	# 3) Formato viejo, una imagen por nivel. Se conserva por si quedo algun JSON
	#    a la antigua.
	if rutas.is_empty() and ResourceLoader.exists(str(datos.get("imagen", ""))):
		rutas.append(str(datos["imagen"]))

	if rutas.is_empty():
		push_warning("El nivel '%s' no tiene imagenes; se esperaban en %s/nivel%d/." % [
			id_nivel, CARPETA_IMAGENES, numero
		])

	_cache_imagenes[id_nivel] = rutas
	return rutas


## "nivel_12" -> 12. Es lo que amarra el nivel del JSON con su carpeta.
func _numero_de_nivel(id_nivel: String) -> int:
	var digitos := ""
	for i in range(id_nivel.length() - 1, -1, -1):
		if not id_nivel[i].is_valid_int():
			break
		digitos = id_nivel[i] + digitos
	return int(digitos) if digitos != "" else 0


func _ruta_imagen_actual() -> String:
	if variante_actual >= 0 and variante_actual < imagenes_nivel.size():
		return str(imagenes_nivel[variante_actual])
	return IMAGEN_FALLBACK


func _titulo_nivel() -> String:
	var titulo := str(datos_nivel.get("titulo", ""))
	# En el libro sirve saber cual de las imagenes se esta armando; en la historia
	# el numero no le dice nada al jugador.
	if modo_libre and variante_actual >= 0 and imagenes_nivel.size() > 1:
		return "%s  %d/%d" % [titulo, variante_actual + 1, imagenes_nivel.size()]
	return titulo


## La rotacion que pide la historia: la primera imagen sin jugar, en orden. Ya
## jugadas todas, una al azar (asi rejugar un capitulo no siempre repite la misma).
func _variante_para_historia(rutas: Array) -> int:
	for i in rutas.size():
		if not _ya_jugada(str(rutas[i]), AMBITO_HISTORIA):
			return i
	return randi() % rutas.size()


## Se guarda con el nombre del archivo, no con su posicion, para que renumerar o
## agregar imagenes no reviva ni tache las que no son.
func _clave_jugada(ruta: String, ambito: String) -> String:
	return "rompecabezas_%s_%s" % [ruta.get_file().get_basename(), ambito]


func _ya_jugada(ruta: String, ambito: String) -> bool:
	return bool(Global.eventos_completados.get(_clave_jugada(ruta, ambito), false))


## Nota: esto solo toca el diccionario en memoria; queda en disco en el siguiente
## Global.guardar_partida(), igual que el resto de eventos_completados.
func _marcar_jugada(ruta: String, ambito: String) -> void:
	Global.eventos_completados[_clave_jugada(ruta, ambito)] = true


func _cargar_textura(ruta: String) -> Texture2D:
	if ruta != "" and ResourceLoader.exists(ruta):
		var tex := load(ruta)
		if tex is Texture2D:
			return tex
	push_warning("No se pudo cargar la imagen '%s'. Se usa el icono como reemplazo." % ruta)
	return load(IMAGEN_FALLBACK)


func _filtro() -> int:
	return CanvasItem.TEXTURE_FILTER_NEAREST if filtro_pixel_art else CanvasItem.TEXTURE_FILTER_LINEAR


## Ajusta la imagen dentro de area_tablero conservando su proporcion y la centra.
func _calcular_tablero() -> void:
	var tam_img := Vector2(textura.get_size())
	var escala: float = minf(area_tablero.size.x / tam_img.x, area_tablero.size.y / tam_img.y)
	tam_tablero = (tam_img * escala).floor()
	origen_tablero = (area_tablero.position + (area_tablero.size - tam_tablero) * 0.5).floor()
	ancho_pieza = tam_tablero.x / columnas
	alto_pieza = tam_tablero.y / filas


func _dibujar_marco_tablero() -> void:
	var marco: Line2D = tablero.get_node_or_null("Marco")
	if marco == null:
		marco = Line2D.new()
		marco.name = "Marco"
		marco.width = 1.0
		tablero.add_child(marco)
	marco.default_color = color_marco_tablero
	marco.closed = true
	marco.points = PackedVector2Array([
		origen_tablero,
		origen_tablero + Vector2(tam_tablero.x, 0),
		origen_tablero + tam_tablero,
		origen_tablero + Vector2(0, tam_tablero.y),
	])


# ── Pantalla de niveles (solo en modo libre) ──────────────────────────────────

## Arma la lista de niveles leyendo rompecabezas.json, asi agregar un nivel nuevo
## no obliga a tocar la escena: aparece solo.
func _mostrar_niveles() -> void:
	_volver_a_un_menu()
	panel_imagenes.hide()

	_vaciar(grid_niveles)
	for clave in config.keys():
		if clave.begins_with("_"):   # "_instrucciones" y "_dificultades" no son niveles
			continue
		var datos: Dictionary = config[clave]
		grid_niveles.add_child(
			_crear_boton_nivel(clave, str(datos.get("titulo", clave)), _imagenes_de(clave).size())
		)

	panel_niveles.show()


func _crear_boton_nivel(clave: String, titulo: String, total_imagenes: int) -> Button:
	var boton := Button.new()
	boton.text = titulo
	boton.clip_text = true          # que un titulo largo no deforme la rejilla
	boton.custom_minimum_size = Vector2(250, 34)
	_estilo_de_boton(boton, 12)
	if total_imagenes <= 0:
		# Nivel declarado en el JSON pero todavia sin imagenes en su carpeta. Se deja
		# a la vista para que se sepa que viene, pero sin poder entrar (no se conecta
		# 'pressed': un boton disabled tampoco lo emitiria).
		boton.text = "%s (pronto)" % titulo
		boton.disabled = true
		boton.modulate.a = 0.55
	else:
		boton.pressed.connect(_elegir_nivel.bind(clave))
	_ajustar_texto_boton(boton, ANCHO_UTIL_BOTON, 12, 9)
	return boton


func _elegir_nivel(clave: String) -> void:
	panel_niveles.hide()
	# Con una sola imagen no hay nada que elegir: directo a la dificultad.
	if _imagenes_de(clave).size() > 1:
		_mostrar_imagenes(clave)
	else:
		preparar_nivel(clave, 0)


func _on_volver_libro_pressed() -> void:
	SceneTransition.change_scene("res://Scenes/LibroHistoria.tscn")


# -- Pantalla de imagenes (solo en modo libre) --------------------------------

## Las imagenes del nivel como miniaturas, para que el jugador escoja cual armar.
## Esta pantalla NO aparece cuando el rompecabezas lo lanza un dialogo: ahi la
## imagen la decide la rotacion (ver _variante_para_historia).
func _mostrar_imagenes(clave: String) -> void:
	nivel_a_cargar = clave
	_volver_a_un_menu()
	panel_niveles.hide()

	var datos: Dictionary = config.get(clave, {})
	label_nivel_imagenes.text = str(datos.get("titulo", clave))

	_vaciar(fila_imagenes)
	var rutas := _imagenes_de(clave)
	for i in rutas.size():
		fila_imagenes.add_child(_crear_tarjeta_imagen(clave, i, str(rutas[i])))

	panel_imagenes.show()


## Una tarjeta = un Button del tamano de la miniatura, con la imagen dentro y su
## numero debajo. Los hijos llevan mouse_filter IGNORE para que el clic siempre
## acabe en el boton y no en la imagen.
##
## No usa el estilo de pergamino del resto de los botones: ese es una tira ancha
## y baja, y aqui la miniatura lo taparia entero. Va un marco propio, que ademas
## deja ver cual esta señalada.
func _crear_tarjeta_imagen(clave: String, indice: int, ruta: String) -> Button:
	const TAM_MINIATURA := Vector2(150, 100)
	const MARGEN := 6.0
	const ALTO_ETIQUETA := 20.0

	var jugada := _ya_jugada(ruta, AMBITO_LIBRO)

	var boton := Button.new()
	boton.custom_minimum_size = TAM_MINIATURA + Vector2(MARGEN * 2.0, MARGEN + ALTO_ETIQUETA + 2.0)
	boton.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	boton.tooltip_text = "Imagen %d" % (indice + 1)
	boton.add_theme_stylebox_override("normal", _marco_tarjeta(false))
	boton.add_theme_stylebox_override("disabled", _marco_tarjeta(false))
	boton.add_theme_stylebox_override("hover", _marco_tarjeta(true))
	boton.add_theme_stylebox_override("pressed", _marco_tarjeta(true))
	boton.pressed.connect(_elegir_imagen.bind(clave, indice))

	var miniatura := TextureRect.new()
	miniatura.texture = _cargar_textura(ruta)
	miniatura.texture_filter = _filtro()
	miniatura.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	miniatura.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	miniatura.mouse_filter = Control.MOUSE_FILTER_IGNORE
	miniatura.position = Vector2(MARGEN, MARGEN)
	miniatura.size = TAM_MINIATURA
	# La ya jugada se ve un poco apagada, para distinguirla de un vistazo.
	miniatura.modulate = Color(0.72, 0.68, 0.62) if jugada else Color.WHITE
	boton.add_child(miniatura)

	var etiqueta := Label.new()
	etiqueta.text = "Imagen %d - jugada" % (indice + 1) if jugada else "Imagen %d" % (indice + 1)
	etiqueta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	etiqueta.position = Vector2(MARGEN, MARGEN + TAM_MINIATURA.y)
	etiqueta.size = Vector2(TAM_MINIATURA.x, ALTO_ETIQUETA)
	etiqueta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	etiqueta.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	etiqueta.add_theme_font_override("font", btn_reiniciar.get_theme_font("font"))
	etiqueta.add_theme_font_size_override("font_size", 11)
	etiqueta.add_theme_color_override("font_color", color_victoria if jugada else COLOR_TEXTO_TARJETA)
	boton.add_child(etiqueta)

	return boton


func _marco_tarjeta(resaltado: bool) -> StyleBoxFlat:
	var marco := StyleBoxFlat.new()
	marco.bg_color = Color(0.16, 0.10, 0.08, 0.72)
	marco.set_border_width_all(2)
	marco.border_color = color_victoria if resaltado else Color(0.47, 0.33, 0.23, 1.0)
	marco.set_corner_radius_all(3)
	return marco


func _elegir_imagen(clave: String, indice: int) -> void:
	panel_imagenes.hide()
	preparar_nivel(clave, indice)


# -- Utilidades de los menus --------------------------------------------------

## Estado comun de cualquier pantalla de menu: sin piezas, sin reloj y sin HUD.
func _volver_a_un_menu() -> void:
	_limpiar_piezas()
	terminado = false
	jugando = false
	pieza_activa = null

	panel_seleccion.hide()
	mensaje_victoria.hide()
	guia.visible = false
	label_titulo.text = ""
	label_progreso.hide()
	label_tiempo.hide()
	btn_pista.hide()
	btn_reiniciar.hide()
	btn_salir.hide()


## queue_free() no saca al nodo del arbol hasta el final del cuadro, asi que sin el
## remove_child el contenedor acomodaria por un instante los viejos y los nuevos.
func _vaciar(contenedor: Node) -> void:
	for hijo in contenedor.get_children():
		contenedor.remove_child(hijo)
		hijo.queue_free()


## El pergamino de los botones (fondo_botones2.png) trae los bordes rasgados y
## transparentes, asi que la parte pintada es mas angosta que el boton: un texto
## que "cabe" en los 250 px igual se sale del dibujo. Se le baja la letra hasta
## que entre en lo que de verdad se ve, y si ni con la mas chica cabe, se recorta
## con puntos suspensivos en vez de invadir la pantalla.
func _ajustar_texto_boton(boton: Button, ancho_util: float, tam_max: int, tam_min: int) -> void:
	boton.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	var fuente := boton.get_theme_font("font")
	if fuente == null:
		return
	for tam in range(tam_max, tam_min - 1, -1):
		if fuente.get_string_size(boton.text, HORIZONTAL_ALIGNMENT_LEFT, -1, tam).x <= ancho_util:
			boton.add_theme_font_size_override("font_size", tam)
			return
	boton.add_theme_font_size_override("font_size", tam_min)


## Copia la fuente y el estilo de un boton que ya trae la escena, para no repetir
## recursos en los botones que se crean por codigo.
func _estilo_de_boton(boton: Button, tam_fuente: int) -> void:
	boton.add_theme_font_override("font", btn_reiniciar.get_theme_font("font"))
	boton.add_theme_font_size_override("font_size", tam_fuente)
	boton.add_theme_color_override("font_color", color_texto_normal)
	var estilo := btn_reiniciar.get_theme_stylebox("normal")
	for estado in ["normal", "hover", "pressed", "disabled"]:
		boton.add_theme_stylebox_override(estado, estilo)


# ── Pantalla de dificultad ────────────────────────────────────────────────────

func _mostrar_seleccion() -> void:
	var rel := _dificultad("relajado")
	var des := _dificultad("desafiante")

	btn_relajado.text = rel["nombre"]
	btn_desafiante.text = des["nombre"]
	lbl_relajado.text = "%d piezas" % (rel["filas"] * rel["columnas"])
	lbl_desafiante.text = "%d piezas" % (des["filas"] * des["columnas"])

	panel_imagenes.hide()
	panel_seleccion.show()
	# El HUD del juego no pinta nada mientras se elige
	label_progreso.hide()
	label_tiempo.hide()
	btn_pista.hide()
	btn_reiniciar.hide()
	btn_salir.hide()
	# Solo en modo libre se puede regresar a escoger otro nivel
	btn_volver_niveles.visible = modo_libre
	btn_volver_niveles.text = "< Imagenes" if imagenes_nivel.size() > 1 else "< Niveles"


## Lee una dificultad del JSON, rellenando con DIFICULTADES_POR_DEFECTO lo que falte.
func _dificultad(clave: String) -> Dictionary:
	var base: Dictionary = DIFICULTADES_POR_DEFECTO.get(clave, {})
	var dif: Dictionary = config.get("_dificultades", {}).get(clave, {})
	return {
		"nombre": str(dif.get("nombre", base.get("nombre", "Jugar"))),
		"filas": maxi(1, int(dif.get("filas", base.get("filas", 3)))),
		"columnas": maxi(1, int(dif.get("columnas", base.get("columnas", 3)))),
	}


func _elegir_dificultad(clave: String) -> void:
	var dif := _dificultad(clave)
	filas = dif["filas"]
	columnas = dif["columnas"]

	panel_seleccion.hide()
	label_progreso.show()
	label_tiempo.visible = segundos_totales > 0.0
	btn_reiniciar.show()
	# En modo libre siempre debe haber salida: sin esto, terminar el rompecabezas
	# desde el libro dejaria al jugador encerrado en la pantalla de victoria.
	btn_salir.visible = modo_libre

	# La vista previa baja a la opacidad de guia que pida el nivel
	var con_guia: bool = bool(datos_nivel.get("mostrar_guia", true))
	guia.visible = con_guia
	if con_guia:
		guia.modulate = Color(1, 1, 1, float(datos_nivel.get("opacidad_guia", 0.22)))

	_calcular_tablero()   # ahora si, con la rejilla definitiva
	_generar_piezas()
	_actualizar_hud()
	tiempo_restante = segundos_totales
	_actualizar_reloj()
	jugando = true


# ── Generacion de la forma de las piezas ──────────────────────────────────────

## Perfil normalizado de un borde con pestana: va de (0,0) a (1,0) y el "boton"
## sobresale en +y. Se construye como cuello -> arco del boton -> cuello.
func _construir_perfil() -> PackedVector2Array:
	const MUESTRAS_CUELLO := 8
	const MUESTRAS_ARCO := 18
	var pts := PackedVector2Array()
	var r := radio_pestana
	var cy := altura_pestana
	var cuello := ancho_cuello

	# El arco recorre el boton por la izquierda (200°), arriba (90°) y la derecha (-20°)
	var ang_ini := deg_to_rad(200.0)
	var ang_fin := deg_to_rad(-20.0)
	var p_izq := Vector2(0.5 + r * cos(ang_ini), cy + r * sin(ang_ini))
	var p_der := Vector2(0.5 + r * cos(ang_fin), cy + r * sin(ang_fin))
	var base_izq := Vector2(0.5 - cuello, 0.0)
	var base_der := Vector2(0.5 + cuello, 0.0)

	pts.append(Vector2(0.0, 0.0))
	pts.append(base_izq)

	# Subida por el cuello izquierdo
	for i in range(1, MUESTRAS_CUELLO + 1):
		var t := float(i) / MUESTRAS_CUELLO
		pts.append(_bezier2(base_izq, Vector2(base_izq.x + cuello * 0.35, cy * 0.55), p_izq, t))

	# Arco del boton
	for i in range(1, MUESTRAS_ARCO):
		var t := float(i) / MUESTRAS_ARCO
		var ang := lerpf(ang_ini, ang_fin, t)
		pts.append(Vector2(0.5 + r * cos(ang), cy + r * sin(ang)))
	pts.append(p_der)

	# Bajada por el cuello derecho
	for i in range(1, MUESTRAS_CUELLO + 1):
		var t := float(i) / MUESTRAS_CUELLO
		pts.append(_bezier2(p_der, Vector2(base_der.x - cuello * 0.35, cy * 0.55), base_der, t))

	pts.append(Vector2(1.0, 0.0))
	return pts


func _bezier2(p0: Vector2, p1: Vector2, p2: Vector2, t: float) -> Vector2:
	var u := 1.0 - t
	return u * u * p0 + 2.0 * u * t * p1 + t * t * p2


## Crea un borde entre dos esquinas. signo 0 = recto (orilla de la imagen),
## +1 / -1 = pestana hacia un lado o el otro.
func _crear_borde(a: Vector2, b: Vector2, signo: int) -> PackedVector2Array:
	if signo == 0:
		return PackedVector2Array([a, b])
	var d := b - a
	var largo := d.length()
	var dir := d / largo
	# Normal "hacia afuera" recorriendo el contorno en sentido horario
	var nor := Vector2(dir.y, -dir.x)
	# La pestana se escala con el lado mas corto para que se vea igual en piezas no cuadradas
	var escala_pestana: float = minf(ancho_pieza, alto_pieza)
	var pts := PackedVector2Array()
	for p in perfil:
		pts.append(a + dir * (p.x * largo) + nor * (p.y * signo * escala_pestana))
	return pts


## Genera todos los bordes del tablero. Los internos llevan pestana al azar; los
## de la orilla van rectos.
func _generar_bordes() -> void:
	perfil = _construir_perfil()
	bordes_h = []
	bordes_v = []

	for f in filas + 1:
		var fila_h: Array = []
		for c in columnas:
			var a := Vector2(c * ancho_pieza, f * alto_pieza)
			var b := Vector2((c + 1) * ancho_pieza, f * alto_pieza)
			var signo: int = 0 if (f == 0 or f == filas) else (1 if randf() < 0.5 else -1)
			fila_h.append(_crear_borde(a, b, signo))
		bordes_h.append(fila_h)

	for f in filas:
		var fila_v: Array = []
		for c in columnas + 1:
			var a := Vector2(c * ancho_pieza, f * alto_pieza)
			var b := Vector2(c * ancho_pieza, (f + 1) * alto_pieza)
			var signo: int = 0 if (c == 0 or c == columnas) else (1 if randf() < 0.5 else -1)
			fila_v.append(_crear_borde(a, b, signo))
		bordes_v.append(fila_v)


## Arma el contorno de una pieza recorriendo sus 4 bordes en sentido horario.
## Los bordes de abajo y de la izquierda se recorren al reves porque se comparten
## con la pieza vecina (asi las dos formas embonan exacto).
func _poligono_pieza(f: int, c: int) -> PackedVector2Array:
	var origen := Vector2(c * ancho_pieza, f * alto_pieza)
	var pts := PackedVector2Array()
	_agregar_borde(pts, bordes_h[f][c], false, origen)          # arriba: izq -> der
	_agregar_borde(pts, bordes_v[f][c + 1], false, origen)      # derecha: arriba -> abajo
	_agregar_borde(pts, bordes_h[f + 1][c], true, origen)       # abajo: der -> izq (invertido)
	_agregar_borde(pts, bordes_v[f][c], true, origen)           # izquierda: abajo -> arriba (invertido)
	# El ultimo punto cae encima del primero (es la misma esquina): se quita para
	# no dejar un segmento de largo cero que confunda la triangulacion.
	if pts.size() > 1 and pts[0].is_equal_approx(pts[pts.size() - 1]):
		pts.remove_at(pts.size() - 1)
	return pts


func _agregar_borde(destino: PackedVector2Array, borde: PackedVector2Array, invertido: bool, origen: Vector2) -> void:
	var n := borde.size()
	for i in n:
		# Se salta el primer punto: ya lo puso el borde anterior
		var idx: int = (n - 1 - i) if invertido else i
		if i == 0 and destino.size() > 0:
			continue
		destino.append(borde[idx] - origen)


# ── Creacion de los nodos de las piezas ───────────────────────────────────────

func _limpiar_piezas() -> void:
	for hijo in contenedor_piezas.get_children():
		hijo.queue_free()
	piezas.clear()
	colocadas = 0


func _generar_piezas() -> void:
	_limpiar_piezas()
	terminado = false
	pieza_activa = null
	mensaje_victoria.hide()

	_generar_bordes()

	var filtro := _filtro()
	var factor_uv := Vector2(textura.get_size()) / tam_tablero
	var revueltas := _posiciones_revueltas(filas * columnas)

	var i := 0
	for f in filas:
		for c in columnas:
			var poligono := _poligono_pieza(f, c)

			var pieza := Polygon2D.new()
			pieza.polygon = poligono
			pieza.texture = textura
			pieza.texture_filter = filtro
			# El UV va en pixeles de la imagen original: pasamos el punto a
			# coordenadas del tablero y de ahi a coordenadas de la textura.
			var origen_celda := Vector2(c * ancho_pieza, f * alto_pieza)
			var uvs := PackedVector2Array()
			for p in poligono:
				uvs.append((p + origen_celda) * factor_uv)
			pieza.uv = uvs

			if mostrar_contorno:
				var linea := Line2D.new()
				linea.points = poligono
				linea.closed = true
				linea.width = 1.0
				linea.default_color = color_contorno
				pieza.add_child(linea)

			pieza.position = revueltas[i]
			contenedor_piezas.add_child(pieza)

			piezas.append({
				"nodo": pieza,
				"fila": f,
				"col": c,
				"destino": origen_tablero + origen_celda,
				"colocada": false,
			})
			i += 1


## Reparte las piezas entre las dos columnas laterales y revuelve el orden.
func _posiciones_revueltas(cantidad: int) -> Array:
	var en_izquierda: int = int(ceil(cantidad / 2.0))
	var lista: Array = []
	lista.append_array(_posiciones_en(area_piezas_izq, en_izquierda))
	lista.append_array(_posiciones_en(area_piezas_der, cantidad - en_izquierda))
	lista.shuffle()
	return lista


## Acomoda `cantidad` piezas dentro de una columna, repartidas parejo. Si no caben
## todas se encimaran, que es lo natural en un rompecabezas; lo importante es que
## ninguna quede fuera de la pantalla ni encima del tablero.
func _posiciones_en(zona: Rect2, cantidad: int) -> Array:
	var lista: Array = []
	if cantidad <= 0:
		return lista

	# Espacio donde puede caer la ESQUINA de una pieza sin que se salga de la columna
	var util := Vector2(
		maxf(0.0, zona.size.x - ancho_pieza),
		maxf(0.0, zona.size.y - alto_pieza)
	)
	# Cuantos renglones caben a lo alto de la columna; las columnas internas
	# salen de repartir el resto de las piezas entre esos renglones.
	var rows: int = clampi(int(round(zona.size.y / maxf(1.0, alto_pieza))), 1, cantidad)
	var cols: int = int(ceil(float(cantidad) / float(rows)))

	for i in cantidad:
		var fx: float = 0.0 if cols <= 1 else float(i % cols) / float(cols - 1)
		var fy: float = 0.0 if rows <= 1 else float(i / cols) / float(rows - 1)
		var pos := zona.position + Vector2(util.x * fx, util.y * fy)
		# Un poco de desorden, pero sin salirse de la columna
		pos += Vector2(randf_range(-3.0, 3.0), randf_range(-3.0, 3.0))
		pos.x = clampf(pos.x, zona.position.x, zona.position.x + util.x)
		pos.y = clampf(pos.y, zona.position.y, zona.position.y + util.y)
		lista.append(_dentro_de_pantalla(pos))
	return lista


## Evita que una pieza quede fuera de la pantalla y ya no se pueda agarrar.
func _dentro_de_pantalla(pos: Vector2) -> Vector2:
	var limite: Vector2 = get_viewport_rect().size
	# Las pestanas sobresalen del rectangulo de la pieza, hay que contarlas
	var pestana: float = minf(ancho_pieza, alto_pieza) * (altura_pestana + radio_pestana)
	return Vector2(
		clampf(pos.x, pestana, maxf(pestana, limite.x - ancho_pieza - pestana)),
		clampf(pos.y, pestana, maxf(pestana, limite.y - alto_pieza - pestana))
	)


# ── Arrastrar y soltar ────────────────────────────────────────────────────────

## El arrastre se atiende con el gui_input de CapturaInput, NO con
## _unhandled_input. Cuando el minijuego se abre encima de un nivel, el
## ReferenceRect "LimitesCamara" del nivel es un Control de pantalla completa con
## mouse_filter STOP: se comia el click antes de que llegara a _unhandled_input y
## las piezas no se podian mover. Con una capa propia el minijuego agarra su
## input sin depender de lo que haya debajo (y de paso no se le escapan clicks al
## nivel). Los botones son hermanos posteriores, asi que conservan la prioridad.
func _on_captura_gui_input(evento: InputEvent) -> void:
	if terminado or not jugando:
		return

	if evento is InputEventMouseButton and evento.button_index == MOUSE_BUTTON_LEFT:
		if evento.pressed:
			_tomar_pieza(evento.position)
		else:
			_soltar_pieza()
	elif evento is InputEventMouseMotion and pieza_activa != null:
		pieza_activa.position = _dentro_de_pantalla(evento.position + agarre_offset)


func _tomar_pieza(punto: Vector2) -> void:
	# De arriba hacia abajo, para agarrar siempre la pieza que se ve encima
	for i in range(piezas.size() - 1, -1, -1):
		var datos: Dictionary = piezas[i]
		if datos["colocada"]:
			continue
		var pieza: Polygon2D = datos["nodo"]
		if Geometry2D.is_point_in_polygon(punto - pieza.position, pieza.polygon):
			pieza_activa = pieza
			agarre_offset = pieza.position - punto
			pieza.z_index = 100
			contenedor_piezas.move_child(pieza, -1)
			# La pieza agarrada tambien va al final del array, para que quede encima
			piezas.remove_at(i)
			piezas.append(datos)
			return


func _soltar_pieza() -> void:
	if pieza_activa == null:
		return
	var pieza := pieza_activa
	pieza_activa = null
	pieza.z_index = 0

	var datos := _datos_de(pieza)
	if datos.is_empty():
		return

	if pieza.position.distance_to(datos["destino"]) <= tolerancia_snap:
		_colocar(datos)
	elif devolver_si_falla:
		var regreso: Vector2 = _posiciones_revueltas(1)[0]
		var tw := create_tween()
		tw.tween_property(pieza, "position", regreso, 0.2).set_trans(Tween.TRANS_SINE)


func _datos_de(pieza: Polygon2D) -> Dictionary:
	for datos in piezas:
		if datos["nodo"] == pieza:
			return datos
	return {}


func _colocar(datos: Dictionary, animado: bool = true) -> void:
	var pieza: Polygon2D = datos["nodo"]
	datos["colocada"] = true
	colocadas += 1
	# OJO: nada de z_index negativo aqui. El Fondo es un TextureRect opaco de
	# pantalla completa con z_index 0, asi que un -1 esconderia la pieza detras
	# del fondo. El orden entre piezas ya lo da move_child().
	pieza.z_index = 0
	contenedor_piezas.move_child(pieza, 0)   # las colocadas se van hasta atras

	if animado:
		var tw := create_tween()
		tw.tween_property(pieza, "position", datos["destino"], 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	else:
		pieza.position = datos["destino"]

	_actualizar_hud()
	if colocadas >= piezas.size():
		_ganar()


func _ganar() -> void:
	terminado = true
	jugando = false
	pieza_activa = null
	_actualizar_hud()   # esconde el boton de pista, que ya no hace falta
	_mostrar_mensaje(str(datos_nivel.get("texto_victoria", "¡Lo lograste!")), color_victoria)

	# Emitir la señal cierra el minijuego de inmediato, porque el diálogo la
	# escucha y libera la escena. Se espera para que al jugador le dé tiempo de
	# ver la imagen ya armada antes de volver a la historia.
	await get_tree().create_timer(ESPERA_VICTORIA).timeout
	if not is_inside_tree():
		return

	# En modo libre nadie escucha: el mensaje se queda y el jugador sale con
	# "Niveles" o vuelve a jugar con "Reiniciar" cuando quiera.
	if not modo_libre:
		juego_completado.emit()


func _perder() -> void:
	terminado = true
	jugando = false
	pieza_activa = null
	_mostrar_mensaje(str(datos_nivel.get("texto_derrota", "¡Se acabó el tiempo!")), color_derrota)
	juego_perdido.emit()


func _mostrar_mensaje(texto: String, color: Color) -> void:
	mensaje_victoria.text = texto
	mensaje_victoria.add_theme_color_override("font_color", color)
	mensaje_victoria.show()
	mensaje_victoria.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(mensaje_victoria, "modulate:a", 1.0, 0.4)


# ── HUD y botones ─────────────────────────────────────────────────────────────

func _actualizar_hud() -> void:
	label_progreso.text = "Piezas: %d / %d" % [colocadas, piezas.size()]
	btn_pista.visible = pistas_restantes > 0 and not terminado
	btn_pista.text = "Pista (%d)" % pistas_restantes


func _actualizar_reloj() -> void:
	if segundos_totales <= 0.0:
		label_tiempo.hide()
		return
	var t := int(ceil(maxf(0.0, tiempo_restante)))
	label_tiempo.text = "%d:%02d" % [t / 60, t % 60]
	label_tiempo.add_theme_color_override(
		"font_color",
		color_texto_alerta if float(t) <= segundos_alerta else color_texto_normal
	)


func _on_pista_pressed() -> void:
	if terminado or not jugando or pistas_restantes <= 0:
		return
	for datos in piezas:
		if not datos["colocada"]:
			if pieza_activa == datos["nodo"]:
				pieza_activa = null
			pistas_restantes -= 1
			_colocar(datos)
			return


## Reiniciar regresa a la pantalla de dificultad, por si el jugador quiere cambiarla.
## Se le pasa variante_actual a proposito: sin eso, reiniciar en la historia gastaria
## otra imagen de la rotacion en vez de repetir la que estaba armando.
func _on_reiniciar_pressed() -> void:
	preparar_nivel(nivel_a_cargar, variante_actual)


## "< Imagenes" / "< Niveles" de la pantalla de dificultad.
func _on_volver_desde_dificultad() -> void:
	if imagenes_nivel.size() > 1:
		_mostrar_imagenes(nivel_a_cargar)
	else:
		_mostrar_niveles()
