extends Control

const PANEL_CONFIGURACION = preload("res://Scenes/PanelConfiguracion.tscn")

# 1. Creamos referencias a los contenedores y al texto gigante
@onready var VBox_Sub_Comenzar = $VBox_Sub_Comenzar
@onready var texto_derecha = $texto_derecha
@onready var VBox_menu_laboratorio = $VBox_menu_laboratorio
@onready var VBox_Principal = $VBox_Principal
# Variables para guardar las posiciones y rotaciones originales bajo llave
var pos_texto_original : Vector2
var rot_texto_original : float

func _ready() -> void:
	# Al iniciar, ocultamos opciones y ponemos el texto base
	VBox_Sub_Comenzar.hide()
	VBox_menu_laboratorio.hide()
	
	
	# --- EL SECRETO ESTÁ AQUÍ ---
	# Guardamos el estado original EXACTO que le pusiste en el editor
	pos_texto_original = texto_derecha.position
	rot_texto_original = texto_derecha.rotation_degrees
	
	# Guardamos la rotación original de los VBox directamente dentro de ellos como "metadatos"
	VBox_Sub_Comenzar.set_meta("rot_original", VBox_Sub_Comenzar.rotation_degrees)
	VBox_menu_laboratorio.set_meta("rot_original", VBox_menu_laboratorio.rotation_degrees)
	texto_derecha.set_meta("rot_original", rot_texto_original)
	
	# Conectar el botón de Nueva Partida
	var btn_nueva_partida = VBox_menu_laboratorio.get_node_or_null("Volver_comenzar_btn")
	if btn_nueva_partida:
		btn_nueva_partida.pressed.connect(_on_nueva_partida_pressed)
		
	# Conectar el botón de Continuar
	var btn_continuar = VBox_menu_laboratorio.get_node_or_null("Continuar_btn")
	if btn_continuar:
		btn_continuar.pressed.connect(_on_continuar_pressed)


# --- FUNCIONES DE ANIMACIÓN (ESTILO PERSONA 5) ---

func _animar_vibracion(nodo_a_animar: Node) -> void:
	if not nodo_a_animar: return
	
	# Recuperamos la rotación original exacta que guardamos en _ready()
	var rot_base = nodo_a_animar.get_meta("rot_original")
	
	# SEGURIDAD: Restablecemos a sus valores originales por si hubo clics rápidos
	nodo_a_animar.scale = Vector2(1.0, 1.0)
	nodo_a_animar.rotation_degrees = rot_base
	
	var tween = get_tree().create_tween()
	tween.set_parallel(true) 
	
	# Animación de Escala (hace "pop" visualmente)
	tween.tween_property(nodo_a_animar, "scale", Vector2(1.05, 1.05), 0.05).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	tween.tween_property(nodo_a_animar, "scale", Vector2(1.0, 1.0), 0.05).set_delay(0.05)
	
	# Animación de Rotación (temblor basado en su rotación original)
	tween.tween_property(nodo_a_animar, "rotation_degrees", rot_base + 1.5, 0.05).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(nodo_a_animar, "rotation_degrees", rot_base, 0.05).set_delay(0.05)

#func _animar_entrada_texto(nuevo_texto: String) -> void:
	#var tween = get_tree().create_tween()
	
	# FORZAMOS a que respete su rotación original SIEMPRE antes de moverse
	#texto_derecha.rotation_degrees = rot_texto_original
	#texto_derecha.position.x = pos_texto_original.x + 400 
	#texto_derecha.text = nuevo_texto
	
	# Animamos para que vuelva a su posición original como un latigazo
	#tween.tween_property(texto_derecha, "position:x", pos_texto_original.x, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

# --- BOTONES DEL MENÚ PRINCIPAL ---

func _on_comenzar_btn_pressed() -> void:
	VBox_menu_laboratorio.hide()
	VBox_Principal.hide()
	VBox_Sub_Comenzar.show()
	
	#_animar_vibracion(VBox_Sub_Comenzar)
	#_animar_entrada_texto("Comenzar")

func _on_lab_btn_pressed() -> void:
	VBox_Sub_Comenzar.hide()
	VBox_menu_laboratorio.show()
	
	#_animar_vibracion(VBox_menu_laboratorio)
	#_animar_entrada_texto("Laboratorio")

func _on_configuracion_btn_pressed() -> void:
	VBox_Sub_Comenzar.hide()
	VBox_menu_laboratorio.hide()

	var panel = PANEL_CONFIGURACION.instantiate()
	add_child(panel)
	# Configuracion_btn es de toggle: al cerrar se suelta para que no se quede
	# pintado como presionado.
	panel.cerrado.connect(func(): $VBox_Principal/Configuracion_btn.button_pressed = false)

	#_animar_vibracion(texto_derecha)
	#_animar_entrada_texto("Configuracíon")

func _on_salir_btn_pressed() -> void:
	get_tree().quit()


func _on_memorama_conceptual_btn_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Juegos/Atlas-Bird/Escenas/main-atlasbird.tscn")

func _on_nueva_partida_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/CreacionPersonaje.tscn")

func _on_continuar_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/MenuCargarPartida.tscn")

func _on_book_history_btn_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/LibroHistoria.tscn")

func _on_volver_btn_pressed() -> void:
	VBox_menu_laboratorio.hide()
	VBox_Sub_Comenzar.show()
	
	#_animar_vibracion(VBox_Sub_Comenzar)
	#_animar_entrada_texto("Comenzar")
