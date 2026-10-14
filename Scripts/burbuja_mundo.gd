extends Area2D

@onready var contenedor_visual = $CapaIndependiente/ContenedorVisual
@onready var fondo = $CapaIndependiente/ContenedorVisual/FondoBurbuja
@onready var texto_label = $CapaIndependiente/ContenedorVisual/FondoBurbuja/Texto
@onready var timer = $TimerOcultar

@onready var label_interaccion = $CapaIndependiente/ContenedorVisual/LabelInteraccion

@export var id_dialogo: String = ""
@export var tiempo_visible: float = 3.0

var ruta_json = "res://burbujas.json"
var texto_burbuja = ""
## En burbujas.json un id puede tener:
##   - UN texto:     "hola"
##   - VARIOS:       ["hola", "adiós"]   (uno tras otro; cada uno dura
##                   `tiempo_visible` segundos o se adelanta con el botón de acción)
##   - CONVERSACIÓN: {"frases": [...], "respuestas": [{"texto": "...", "contesta": [...]}]}
##                   Tras las frases se abre el cuadro del jugador para elegir una
##                   respuesta (SelectorRespuestas.tscn) y el NPC contesta en su burbuja.
const SELECTOR := preload("res://Scenes/SelectorRespuestas.tscn")

var frases: Array = []
var respuestas: Array = []
## Lo que la burbuja está diciendo ahora: `frases` o el "contesta" de la respuesta elegida.
var lineas: Array = []
var indice_linea: int = 0
## true mientras el jugador elige respuesta: la burbuja ignora el botón de acción
## para no volver a empezar con el mismo Enter.
var _esperando_respuesta: bool = false
var _contestando: bool = false
@export var requiere_interaccion: bool = false
var jugador_cerca: bool = false

func _process(_delta):
	if contenedor_visual:
		contenedor_visual.global_position = global_position

func _ready():
	# Solo ocultamos la imagen, el Area2D debe seguir activa
	fondo.visible = false
	if label_interaccion:
		label_interaccion.visible = false
	
	cargar_texto_desde_json()
	
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func cargar_texto_desde_json():
	if id_dialogo == "":
		return
		
	if FileAccess.file_exists(ruta_json):
		var archivo = FileAccess.open(ruta_json, FileAccess.READ)
		var contenido = archivo.get_as_text()
		var json = JSON.new()
		if json.parse(contenido) == OK:
			var base_datos = json.data
			if base_datos.has(id_dialogo):
				var valor = base_datos[id_dialogo]
				if valor is Dictionary:
					frases = valor.get("frases", [])
					respuestas = valor.get("respuestas", [])
				elif valor is Array:
					frases = valor
				else:
					frases = [str(valor)]
				lineas = frases
				texto_burbuja = str(frases[0]) if not frases.is_empty() else ""
				if not frases.is_empty():
					_poner_linea(0)
			else:
				print("Error: No se encontró el id_dialogo '", id_dialogo, "' en burbujas.json")

func _poner_linea(i: int) -> void:
	indice_linea = i
	texto_label.text = "[center]" + _con_nombre(str(lineas[i])) + "[/center]"

func _con_nombre(texto: String) -> String:
	return texto.replace("{nombre_jugador}", str(Global.nombre_jugador))

## `lista` vacía = las frases normales del NPC.
func mostrar_burbuja(lista: Array = []):
	if texto_burbuja == "":
		return
	lineas = lista if not lista.is_empty() else frases
	_contestando = not lista.is_empty()
		
	timer.stop()
	_poner_linea(0)
	
	if label_interaccion:
		label_interaccion.visible = false
	
	# Centrar el punto de crecimiento en la colita de abajo
	fondo.pivot_offset = Vector2(fondo.size.x / 2, fondo.size.y)
	
	fondo.scale = Vector2.ZERO
	fondo.visible = true
	var tween = create_tween()
	tween.tween_property(fondo, "scale", Vector2(1, 1), 0.2).set_trans(Tween.TRANS_SPRING)
	
	timer.wait_time = tiempo_visible
	timer.start()

func ocultar_burbuja():
	if not fondo.visible:
		return
	var tween = create_tween()
	tween.tween_property(fondo, "scale", Vector2.ZERO, 0.2)
	await tween.finished
	fondo.visible = false
	
	# Si el jugador sigue cerca y requiere interacción, volvemos a mostrar "Hablar"
	if requiere_interaccion and jugador_cerca and label_interaccion:
		label_interaccion.visible = true

func _on_body_entered(body):
	if body.name == "Player":
		jugador_cerca = true
		# Si NO requiere interacción, se muestra sola al acercarse
		if not requiere_interaccion:
			mostrar_burbuja()
		else:
			# Mostramos el indicador visual
			if not fondo.visible and label_interaccion:
				label_interaccion.visible = true

func _on_body_exited(body):
	if body.name == "Player":
		jugador_cerca = false
		if label_interaccion:
			label_interaccion.visible = false
		ocultar_burbuja()

func _input(event):
	if _esperando_respuesta:
		return
	# Si REQUIERE interacción, el jugador está cerca y presiona el botón de aceptar (Espacio/Enter)
	if requiere_interaccion and jugador_cerca and event.is_action_pressed("ui_accept"):
		# Si no está visible, la mostramos; si ya lo está, pasamos a la frase siguiente
		if not fondo.visible:
			mostrar_burbuja()
		elif indice_linea < lineas.size() - 1 or not respuestas.is_empty():
			_on_timer_ocultar_timeout()

func _on_timer_ocultar_timeout():
	if indice_linea < lineas.size() - 1:
		_poner_linea(indice_linea + 1)
		# La burbuja cambia de alto con el texto: se re-centra la colita.
		fondo.pivot_offset = Vector2(fondo.size.x / 2, fondo.size.y)
		timer.start()
		return
	timer.stop()
	if not _contestando and not respuestas.is_empty() and jugador_cerca:
		_preguntar()
		return
	_contestando = false
	ocultar_burbuja()

## Terminó de hablar el NPC: el jugador elige qué contestar y el NPC responde.
func _preguntar() -> void:
	_esperando_respuesta = true
	await ocultar_burbuja()
	if label_interaccion:
		label_interaccion.visible = false
	var textos: Array = []
	for r in respuestas:
		textos.append(_con_nombre(str(r.get("texto", "..."))))
	var selector = SELECTOR.instantiate()
	get_tree().current_scene.add_child(selector)
	var elegida: int = await selector.preguntar(textos)
	var contesta: Array = respuestas[elegida].get("contesta", [])
	if not contesta.is_empty():
		mostrar_burbuja(contesta)
	elif requiere_interaccion and jugador_cerca and label_interaccion:
		label_interaccion.visible = true
	# Un cuadro de margen: el Enter que eligió la respuesta no debe reabrir la burbuja.
	await get_tree().process_frame
	_esperando_respuesta = false
