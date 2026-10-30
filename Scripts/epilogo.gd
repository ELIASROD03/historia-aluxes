extends Control
## Epílogo "Un viaje para recordar" (GDD), en greybox.
##
## El GDD lo pide como cómic. Mientras no existan las viñetas dibujadas, cada una
## es un recuadro que DESCRIBE la ilustración que va ahí y muestra las caras de
## quienes aparecen. El texto corre por el cuadro de diálogo normal (diálogo
## "epilogo" de dialogos.json); las líneas con "evento": "cinematica_vineta_N"
## cambian a la viñeta N.
##
## Cuando lleguen las ilustraciones: pon la ruta en "imagen" de cada viñeta y se
## mostrará en vez de la descripción.

const ESCENA_MENU := "res://Scenes/MenuPrincipal.tscn"
## Donde aparece el jugador al volver al laboratorio (posicion del Player en Laboratorio.tscn).
const POS_LABORATORIO := Vector2(80, 200)
const RETRATO_JUGADOR := Global.RETRATO_JUGADOR_GENERICO
const DOCTOR := "res://Images/Personajes/doctor/doctor_cara.png"
const ATLAS := "res://Images/Personajes/Atlas/atlas_cara.png"
const KAAN := "res://Images/Personajes/Kaan/cara_kaan.png"
const CHAAC := "res://Images/Personajes/chaac/chaac_cara.png"
const BALAAM := "res://Images/Personajes/balaam/balaam_cara.png"

## Cada viñeta: título, qué hay que dibujar, quiénes salen ([nombre, retrato]) y,
## cuando exista, la ilustración real.
var vinetas: Array = [
	{"titulo": "1 · La casita en el bosque",
	 "dibujo": "Un claro del bosque, de noche y algo irreal (colores que tiemblan).\nAl centro, una casita de madera con humo saliendo de la chimenea.\nBalaam explica; el jugador y Atlas miran la casa.",
	 "personajes": [["{nombre_jugador}", RETRATO_JUGADOR], ["Atlas", ATLAS], ["Balaam", BALAAM]],
	 "imagen": "res://Images/Cinematica/aluxes/bosque_casita.png"},
	{"titulo": "2 · ¡El reencuentro!",
	 "dibujo": "Dentro de la casita: el doctor Juan Pérez (bata blanca, lentes, pelo alborotado)\nsentado a la mesa con un plato de frijol con puerco.\nSalta de la silla y abraza al jugador y a Atlas.",
	 "personajes": [["{nombre_jugador}", RETRATO_JUGADOR], ["Atlas", ATLAS], ["Doctor Juan Pérez", DOCTOR]],
	 "imagen": "res://Images/Cinematica/epilogo/reencuentro.png"},
	{"titulo": "3 · De vuelta en el laboratorio",
	 "dibujo": "Un portal azul se abre en el laboratorio. Kaan y Chaac corren\na abrazar a Balaam entre lágrimas. El doctor mira su laboratorio, feliz.",
	 "personajes": [["Balaam", BALAAM], ["Kaan", KAAN], ["Chaac", CHAAC], ["Doctor Juan Pérez", DOCTOR]],
	 "imagen": "res://Images/Cinematica/epilogo/laboratorio.png"},
	{"titulo": "4 · Una promesa",
	 "dibujo": "El doctor, frente a los tres aluxes, promete cuidar su tierra.\nEn una mesita: atole, elotes y saká como ofrenda.",
	 "personajes": [["Doctor Juan Pérez", DOCTOR], ["Kaan", KAAN], ["Chaac", CHAAC], ["Balaam", BALAAM]],
	 "imagen": "res://Images/Cinematica/epilogo/promesa.png"},
	{"titulo": "5 · Ilustración final",
	 "dibujo": "Todos juntos y felices celebrando el reencuentro:\nel jugador, el doctor, Atlas y los tres aluxes, en el patio al atardecer.",
	 "personajes": [["{nombre_jugador}", RETRATO_JUGADOR], ["Doctor Juan Pérez", DOCTOR], ["Atlas", ATLAS], ["Kaan", KAAN], ["Chaac", CHAAC], ["Balaam", BALAAM]],
	 "imagen": "res://Images/Cinematica/epilogo/final.png"},
]

@onready var lbl_titulo: Label = $Vineta/VBox/Titulo
@onready var lbl_dibujo: Label = $Vineta/VBox/Dibujo
@onready var ilustracion: TextureRect = $Vineta/VBox/Ilustracion
@onready var fila_personajes: HBoxContainer = $Vineta/VBox/Personajes
@onready var vineta: Control = $Vineta
@onready var cuadro = $interfaz/CuadroDialogo
@onready var panel_fin: Control = $PanelFin
var _fondo: TextureRect


func _ready() -> void:
	panel_fin.hide()
	$PanelFin/VBox/BtnMenu.pressed.connect(_volver_al_menu)
	# Segundo boton, mismo estilo: seguir viajando por la historia desde el laboratorio.
	var btn_viajar: Button = $PanelFin/VBox/BtnMenu.duplicate()
	btn_viajar.text = "Seguir viajando por la historia"
	$PanelFin/VBox.add_child(btn_viajar)
	$PanelFin/VBox.move_child(btn_viajar, $PanelFin/VBox/BtnMenu.get_index())
	btn_viajar.pressed.connect(_ir_al_laboratorio)
	cuadro.evento_cinematica.connect(_on_evento_cinematica)
	cuadro.dialogo_terminado.connect(_on_dialogo_terminado)
	# Las ilustraciones van a pantalla completa detrás del cuadro de diálogo; la
	# viñeta-recuadro solo se usa para las que aún no tienen dibujo.
	_fondo = TextureRect.new()
	_fondo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_fondo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_fondo.size = Vector2(640, 360)
	_fondo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fondo)
	move_child(_fondo, vineta.get_index())
	_mostrar_vineta(0)
	cuadro.iniciar_dialogo.call_deferred("epilogo")


func _on_evento_cinematica(evento: String) -> void:
	if not evento.begins_with("cinematica_vineta_"):
		cuadro.continuar_cinematica()
		return
	var n := int(evento.trim_prefix("cinematica_vineta_")) - 1
	var tween := create_tween()
	tween.tween_property(vineta, "modulate:a", 0.0, 0.3)
	tween.parallel().tween_property(_fondo, "modulate:a", 0.0, 0.3)
	tween.tween_callback(_mostrar_vineta.bind(n))
	tween.tween_property(vineta, "modulate:a", 1.0, 0.3)
	tween.parallel().tween_property(_fondo, "modulate:a", 1.0, 0.3)
	await tween.finished
	cuadro.continuar_cinematica()


func _mostrar_vineta(n: int) -> void:
	var datos: Dictionary = vinetas[clampi(n, 0, vinetas.size() - 1)]
	lbl_titulo.text = datos["titulo"]
	var ruta: String = datos.get("imagen", "")
	var hay_imagen := ruta != "" and ResourceLoader.exists(ruta)
	vineta.visible = not hay_imagen
	_fondo.visible = hay_imagen
	if hay_imagen:
		_fondo.texture = load(ruta)
	else:
		lbl_dibujo.text = "[ VIÑETA PENDIENTE ]\n" + datos["dibujo"]
	for hijo in fila_personajes.get_children():
		hijo.queue_free()
	for p in datos["personajes"]:
		fila_personajes.add_child(_cara(str(p[0]).replace("{nombre_jugador}", Global.nombre_jugador), str(p[1])))


func _cara(nombre: String, ruta: String) -> Control:
	var caja := VBoxContainer.new()
	caja.add_theme_constant_override("separation", 0)
	var marco := Panel.new()
	marco.custom_minimum_size = Vector2(44, 44)
	caja.add_child(marco)
	if ruta != "" and ResourceLoader.exists(ruta):
		var cara := TextureRect.new()
		cara.texture = load(ruta)
		cara.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		cara.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		cara.set_anchors_preset(Control.PRESET_FULL_RECT)
		marco.add_child(cara)
	var etiqueta := Label.new()
	etiqueta.text = nombre
	etiqueta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	etiqueta.add_theme_font_size_override("font_size", 8)
	etiqueta.add_theme_color_override("font_color", Color(0.243137, 0.152941, 0.137255))
	etiqueta.custom_minimum_size = Vector2(60, 0)
	caja.add_child(etiqueta)
	return caja


func _on_dialogo_terminado(id_dialogo: String) -> void:
	if id_dialogo != "epilogo":
		return
	Global.eventos_completados["juego_terminado"] = true
	# Se guarda ya: al "Continuar" esta partida el jugador aparece en el laboratorio
	# y la maquina le deja viajar a cualquier capitulo (Global.juego_terminado()).
	Global.escena_actual = Global.ESCENA_LABORATORIO
	Global.posicion_x = POS_LABORATORIO.x
	Global.posicion_y = POS_LABORATORIO.y
	Global.guardar_partida()
	var tween := create_tween()
	tween.tween_property(vineta, "modulate:a", 0.0, 0.6)
	# La ilustración final se queda tenue de fondo detrás del "FIN".
	tween.parallel().tween_property(_fondo, "modulate:a", 0.35, 0.6)
	await tween.finished
	panel_fin.modulate.a = 0.0
	panel_fin.show()
	create_tween().tween_property(panel_fin, "modulate:a", 1.0, 0.8)


func _volver_al_menu() -> void:
	SceneTransition.change_scene(ESCENA_MENU)


func _ir_al_laboratorio() -> void:
	Global.flag_cargar_posicion = true
	SceneTransition.change_scene(Global.ESCENA_LABORATORIO)
