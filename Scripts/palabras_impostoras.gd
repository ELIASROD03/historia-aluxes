extends Control

signal juego_completado

@onready var flow_text = $HFlowText
@onready var mira_detector = $MiraDetector
@onready var barra_carga = $MiraDetector/BarraCarga
@onready var beep_audio = $BeepAudio
@onready var beep_timer = $BeepTimer
@onready var menu_reemplazo = $MenuReemplazo
@onready var btn_analizar = $BtnAnalizarAtlas
@onready var btn_ayuda = $BtnAyudaAtlas
@onready var imagen_detector = $MiraDetector/ImagenDetector

@onready var opciones_cartas = {
	"opcion_a": $MenuReemplazo/VBox/HBoxCartas/OpcionA,
	"opcion_b": $MenuReemplazo/VBox/HBoxCartas/OpcionB,
	"opcion_c": $MenuReemplazo/VBox/HBoxCartas/OpcionC
}

@onready var panel_capitulos: Control = $PanelCapitulos
@onready var grid_capitulos: GridContainer = $PanelCapitulos/GridCapitulos
@onready var btn_volver_libro: Button = $PanelCapitulos/BtnVolverLibro
@onready var btn_salir_libre: Button = $BtnSalirLibre
@onready var label_completado: Label = $LabelCompletado

## Cuánto se queda en pantalla el "¡Completado!" antes de seguir.
const ESPERA_COMPLETADO := 3.0

var font_normal = preload("res://fonts/Amaranth-Bold.ttf")

# Variables que ahora se llenarán desde el JSON
var historia_base = ""
var datos_impostoras = {}
var nivel_a_cargar = "nivel_1_1" # Puedes cambiar esto desde otro script antes de que se ejecute el _ready()

## true cuando se entró desde el Libro de Historia (esta escena ES la escena
## actual) y false cuando la abrió un diálogo dentro de un nivel. En modo libre
## el jugador escoge capítulo y puede salirse; en modo diálogo el texto lo fija
## la historia y quien manda de regreso es el diálogo.
var modo_libre: bool = false

# Variables de estado del minijuego
var zona_activa = null
var tiempo_hover = 0.0
var tiempo_necesario = 3.0
var escaneando = true
var palabras_corregidas = 0
var velocidad_parpadeo = 2.0

func _ready():
	# Si nuestro padre es la raíz del árbol, esta escena ES la escena actual: se
	# entró desde el libro. Si no, alguien nos instanció encima de un nivel.
	modo_libre = (get_parent() == get_tree().root)

	menu_reemplazo.hide()
	btn_analizar.disabled = true
	barra_carga.value = 0

	for key in opciones_cartas.keys():
		opciones_cartas[key].connect("pressed", Callable(self, "_on_carta_seleccionada").bind(key))

	btn_volver_libro.pressed.connect(_on_volver_libro_pressed)
	btn_salir_libre.pressed.connect(_mostrar_capitulos)

	if modo_libre:
		_mostrar_capitulos()
	else:
		_empezar_texto(nivel_a_cargar)


# ── Pantalla de capítulos (solo en modo libre) ────────────────────────────────

## Arma la lista leyendo qué capítulos tienen textos en palabras.json, así
## agregar un capítulo nuevo no obliga a tocar esta escena.
func _mostrar_capitulos() -> void:
	escaneando = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	menu_reemplazo.hide()
	btn_salir_libre.hide()
	btn_analizar.hide()
	btn_ayuda.hide()
	mira_detector.hide()
	for child in flow_text.get_children():
		child.queue_free()

	for hijo in grid_capitulos.get_children():
		hijo.queue_free()

	for numero in _capitulos_disponibles():
		var cap: Dictionary = Global.obtener_capitulo(numero)
		var titulo: String = str(cap.get("subtitulo", "Capítulo %d" % numero)) if not cap.is_empty() \
			else "Capítulo %d" % numero
		grid_capitulos.add_child(_crear_boton_capitulo(numero, titulo))

	panel_capitulos.show()


## Capítulos que tienen al menos un texto "nivel_<cap>_<n>" en palabras.json.
func _capitulos_disponibles() -> Array:
	var encontrados: Array = []
	var file = FileAccess.open("res://palabras.json", FileAccess.READ)
	if not file:
		return encontrados
	var json = JSON.new()
	if json.parse(file.get_as_text()) != OK:
		return encontrados
	for clave in json.data.keys():
		var partes: PackedStringArray = clave.split("_")
		if partes.size() == 3 and partes[0] == "nivel" and partes[1].is_valid_int():
			var numero := int(partes[1])
			if not encontrados.has(numero):
				encontrados.append(numero)
	encontrados.sort()
	return encontrados


## Los textos que existen para un capítulo, para poder sortear entre ellos.
func _textos_del_capitulo(numero: int) -> Array:
	var lista: Array = []
	var file = FileAccess.open("res://palabras.json", FileAccess.READ)
	if not file:
		return lista
	var json = JSON.new()
	if json.parse(file.get_as_text()) != OK:
		return lista
	for clave in json.data.keys():
		if clave.begins_with("nivel_%d_" % numero):
			lista.append(clave)
	lista.sort()
	return lista


func _crear_boton_capitulo(numero: int, titulo: String) -> Button:
	var boton := Button.new()
	boton.text = "%d. %s" % [numero, titulo]
	boton.clip_text = true
	boton.custom_minimum_size = Vector2(250, 34)
	boton.add_theme_font_override("font", font_normal)
	boton.add_theme_font_size_override("font_size", 12)
	boton.add_theme_color_override("font_color", Color(0.24313726, 0.15294118, 0.13725491, 1))
	var estilo := btn_volver_libro.get_theme_stylebox("normal")
	for estado in ["normal", "hover", "pressed", "disabled"]:
		boton.add_theme_stylebox_override(estado, estilo)
	boton.pressed.connect(_elegir_capitulo.bind(numero))
	return boton


## Al elegir capítulo se sortea uno de sus textos, que es justo lo que se pidió:
## que el jugador no sepa cuál le va a tocar.
func _elegir_capitulo(numero: int) -> void:
	var textos := _textos_del_capitulo(numero)
	if textos.is_empty():
		push_error("El capítulo %d no tiene textos en palabras.json." % numero)
		return
	panel_capitulos.hide()
	_empezar_texto(str(textos[randi() % textos.size()]))


func _on_volver_libro_pressed() -> void:
	SceneTransition.change_scene("res://Scenes/LibroHistoria.tscn")


## Deja el minijuego listo para jugar un texto concreto.
func _empezar_texto(nivel_id: String) -> void:
	palabras_corregidas = 0
	zona_activa = null
	tiempo_hover = 0.0
	barra_carga.value = 0
	btn_analizar.disabled = true
	btn_analizar.show()
	btn_ayuda.show()
	btn_ayuda.disabled = false
	mira_detector.show()
	# En modo libre siempre debe haber salida: sin esto, terminar el minijuego
	# desde el libro dejaría al jugador encerrado, porque ahí no hay diálogo
	# esperando la señal juego_completado.
	btn_salir_libre.visible = modo_libre

	cargar_datos_nivel(nivel_id)
	actualizar_texto()
	escaneando = true
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func cargar_datos_nivel(nivel_id: String):
	var file = FileAccess.open("res://palabras.json", FileAccess.READ)
	if not file: return
	
	var json = JSON.new()
	if json.parse(file.get_as_text()) == OK:
		var data = json.data
		if data.has(nivel_id):
			historia_base = data[nivel_id]["historia"]
			
			datos_impostoras.clear()
			var zonas_json = data[nivel_id]["zonas"]
			for z_id in zonas_json:
				datos_impostoras[z_id] = zonas_json[z_id]
				# Añadimos el estado actual vacío por defecto
				datos_impostoras[z_id]["reemplazo_actual"] = ""

func actualizar_texto():
	# Limpia los nodos actuales
	for child in flow_text.get_children():
		child.queue_free()
		
	# Procesamos la historia para preservar los saltos de línea
	var lineas = historia_base.split("\n")
	
	for i in range(lineas.size()):
		var linea = lineas[i]
		var palabras = linea.split(" ")
		
		for p in palabras:
			if p == "": continue
			
			if p.begins_with("{") and p.ends_with("}"):
				var zona_id = p.replace("{", "").replace("}", "")
				if not datos_impostoras.has(zona_id): continue
				
				var label = Label.new()
				label.name = zona_id
				label.set_meta("zona_id", zona_id)
				
				var txt = datos_impostoras[zona_id]["texto_original"]
				var color_fuente = Color.BLACK
				if datos_impostoras[zona_id]["reemplazo_actual"] != "":
					txt = datos_impostoras[zona_id]["reemplazo_actual"]
					color_fuente = Color("1f9fb4ff") # Ámbar
					
				label.text = txt + " "
				label.add_theme_font_override("font", font_normal)
				label.add_theme_font_size_override("font_size", 14)
				label.add_theme_color_override("font_color", color_fuente)
				label.add_to_group("zonas_impostoras")
				label.mouse_filter = Control.MOUSE_FILTER_PASS
				
				flow_text.add_child(label)
			else:
				var label = Label.new()
				label.text = p + " "
				label.add_theme_font_override("font", font_normal)
				label.add_theme_font_size_override("font_size", 14)
				label.add_theme_color_override("font_color", Color.BLACK)
				flow_text.add_child(label)
				
		# Añadir un salto de línea si no es la última línea
		if i < lineas.size() - 1:
			var br = Control.new()
			br.custom_minimum_size = Vector2(400, 0) # Ancho exacto del pergamino para forzar salto sin salir de la pantalla
			flow_text.add_child(br)

func _process(delta):
	if not escaneando:
		mira_detector.hide()
		return
		
	mira_detector.show()
	var mouse_pos = get_global_mouse_position()
	mira_detector.global_position = mouse_pos - (mira_detector.size / 2.0)
	
	var distancia_minima = 9999.0
	var zona_mas_cercana = null
	var en_hover = null
	
	var zonas = get_tree().get_nodes_in_group("zonas_impostoras")
	for zona in zonas:
		if not zona.has_meta("zona_id"): continue
		var id = zona.get_meta("zona_id")
			
		var rect = zona.get_global_rect()
		var centro = rect.position + rect.size / 2.0
		var dist = mouse_pos.distance_to(centro)
		
		if dist < distancia_minima:
			distancia_minima = dist
			zona_mas_cercana = zona
			
		if rect.has_point(mouse_pos):
			en_hover = zona
			
	# Actualizar el contador Geiger
	if zona_mas_cercana != null:
		actualizar_geiger(distancia_minima)
		
		if en_hover != null:
			tiempo_hover += delta
			barra_carga.value = (tiempo_hover / tiempo_necesario) * 100
			
			if tiempo_hover >= tiempo_necesario:
				abrir_menu_reemplazo(en_hover.get_meta("zona_id"))
		else:
			tiempo_hover = 0.0
			barra_carga.value = 0
	else:
		beep_timer.stop()
		tiempo_hover = 0.0
		barra_carga.value = 0
		
	# Animar el parpadeo del detector
	if escaneando and imagen_detector:
		var oscilacion = (sin(Time.get_ticks_msec() * 0.001 * velocidad_parpadeo) + 1.0) / 2.0
		imagen_detector.modulate.a = 0.4 + (oscilacion * 0.6)

func actualizar_geiger(distancia: float):
	if distancia > 250:
		beep_timer.stop()
		velocidad_parpadeo = 2.0
		return
		
	var nuevo_tiempo = 1.5
	if distancia < 40: 
		nuevo_tiempo = 0.1 # Muy rápido
		velocidad_parpadeo = 25.0
	elif distancia < 100: 
		nuevo_tiempo = 0.4
		velocidad_parpadeo = 15.0
	elif distancia < 180: 
		nuevo_tiempo = 0.8
		velocidad_parpadeo = 8.0
		
	if beep_timer.is_stopped() or abs(beep_timer.wait_time - nuevo_tiempo) > 0.1:
		beep_timer.wait_time = max(0.1, nuevo_tiempo)
		beep_timer.start()

func _on_beep_timer_timeout():
	if beep_audio.stream != null: beep_audio.play()

func abrir_menu_reemplazo(zona_id: String):
	escaneando = false
	beep_timer.stop()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	zona_activa = zona_id
	
	var opciones = datos_impostoras[zona_id]["opciones"]
	opciones.shuffle() # Randomizar el orden de las cartas
	
	opciones_cartas["opcion_a"].get_node("Texto").text = opciones[0]["texto"]
	opciones_cartas["opcion_b"].get_node("Texto").text = opciones[1]["texto"]
	opciones_cartas["opcion_c"].get_node("Texto").text = opciones[2]["texto"]
	
	menu_reemplazo.show()

func _on_carta_seleccionada(btn_key: String):
	menu_reemplazo.hide()
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	escaneando = true
	tiempo_hover = 0.0
	barra_carga.value = 0
	
	var indice = 0
	if btn_key == "opcion_b": indice = 1
	elif btn_key == "opcion_c": indice = 2
		
	var seleccion = datos_impostoras[zona_activa]["opciones"][indice]
	datos_impostoras[zona_activa]["reemplazo_actual"] = seleccion["texto"]
	
	palabras_corregidas += 1
	btn_analizar.disabled = false
	actualizar_texto()

func _on_btn_analizar_atlas_pressed():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	escaneando = false
	
	var todas_correctas = true
	for zona_id in datos_impostoras:
		if datos_impostoras[zona_id]["reemplazo_actual"] != datos_impostoras[zona_id]["correcta"]:
			todas_correctas = false
			break
			
	if todas_correctas:
		await _celebrar_y_continuar()
	else:
		# Incorrecto, mostrar Cuadro de Diálogo
		var cuadro = get_node_or_null("CuadroDialogo")
		if cuadro and cuadro.has_method("iniciar_dialogo"):
			cuadro.iniciar_dialogo("error_palabras")
			if not cuadro.is_connected("dialogo_terminado", Callable(self, "_on_error_dialogo_terminado")):
				cuadro.connect("dialogo_terminado", Callable(self, "_on_error_dialogo_terminado"))
		else:
			# Respaldo por si no está el cuadro
			Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
			escaneando = true

## Muestra "¡Completado!" unos segundos y luego sigue: en el juego devuelve el
## control al diálogo, y en el libro regresa a escoger capítulo.
func _celebrar_y_continuar() -> void:
	escaneando = false
	mira_detector.hide()
	btn_analizar.hide()
	btn_ayuda.hide()
	btn_salir_libre.hide()
	label_completado.show()

	await get_tree().create_timer(ESPERA_COMPLETADO).timeout
	if not is_inside_tree():
		return
	label_completado.hide()

	if modo_libre:
		# Desde el libro nadie escucha la señal, así que hay que regresar solos
		# o el jugador se queda aquí atorado.
		_mostrar_capitulos()
	else:
		# El diálogo escucha esto, cierra el minijuego y sigue con la historia.
		juego_completado.emit()


func _on_error_dialogo_terminado(id_dialogo):
	if id_dialogo == "error_palabras":
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
		escaneando = true
	
func _on_btn_ayuda_atlas_pressed():
	var zonas_incorrectas = []
	for zona in get_tree().get_nodes_in_group("zonas_impostoras"):
		if not zona.has_meta("zona_id"): continue
		var id = zona.get_meta("zona_id")
		
		if datos_impostoras[id]["reemplazo_actual"] != datos_impostoras[id]["correcta"]:
			zonas_incorrectas.append(zona)
			
	if zonas_incorrectas.size() > 0:
		var zona_elegida = zonas_incorrectas[randi() % zonas_incorrectas.size()]
		
		var tween = create_tween()
		tween.tween_property(zona_elegida, "theme_override_colors/font_color", Color(1, 0, 0, 1), 0.3)
		tween.tween_property(zona_elegida, "theme_override_colors/font_color", Color(0, 0, 0, 1), 0.3)
		tween.tween_property(zona_elegida, "theme_override_colors/font_color", Color(1, 0, 0, 1), 0.3)
		tween.tween_property(zona_elegida, "theme_override_colors/font_color", Color(0, 0, 0, 1), 0.3)
		tween.tween_property(zona_elegida, "theme_override_colors/font_color", Color(1, 0, 0, 1), 0.3)
		tween.tween_property(zona_elegida, "theme_override_colors/font_color", Color(0, 0, 0, 1), 0.3)
		
		btn_ayuda.disabled = true
