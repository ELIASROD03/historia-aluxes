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
				texto_burbuja = base_datos[id_dialogo]
				texto_label.text = "[center]" + texto_burbuja + "[/center]"
			else:
				print("Error: No se encontró el id_dialogo '", id_dialogo, "' en burbujas.json")

func mostrar_burbuja():
	if texto_burbuja == "":
		return
		
	timer.stop()
	
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
	# Si REQUIERE interacción, el jugador está cerca y presiona el botón de aceptar (Espacio/Enter)
	if requiere_interaccion and jugador_cerca and event.is_action_pressed("ui_accept"):
		# Si ya está visible, la ocultamos (opcional); si no, la mostramos
		if not fondo.visible:
			mostrar_burbuja()

func _on_timer_ocultar_timeout():
	ocultar_burbuja()
