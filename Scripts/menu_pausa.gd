extends CanvasLayer

const PANEL_CONFIGURACION = preload("res://Scenes/PanelConfiguracion.tscn")

@onready var panel_pausa = $PanelPausa
@onready var btn_pausa = $BtnPausa

var mouse_mode_previo = Input.MOUSE_MODE_VISIBLE

func _ready():
	panel_pausa.hide()
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(_delta: float) -> void:
	if has_node("/root/Global"):
		var en_dialogo = get_node("/root/Global").get("en_dialogo")
		if get_tree().paused:
			btn_pausa.visible = false
		else:
			btn_pausa.visible = not en_dialogo

func _on_btn_pausa_pressed():
	alternar_pausa()

func alternar_pausa():
	var pausado = not get_tree().paused
	get_tree().paused = pausado
	panel_pausa.visible = pausado
	
	if pausado:
		mouse_mode_previo = Input.get_mouse_mode()
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(mouse_mode_previo)
	
	# Ocultar controles táctiles al pausar y mostrarlos al reanudar si no estamos en diálogo
	var controles = get_tree().current_scene.find_child("ControlesTactiles", true, false)
	if controles:
		if pausado:
			controles.hide()
		else:
			var en_dialogo = false
			if has_node("/root/Global"):
				en_dialogo = get_node("/root/Global").get("en_dialogo")
			if not en_dialogo:
				controles.show()

func _on_btn_reanudar_pressed():
	alternar_pausa()

func _on_btn_configuracion_pressed():
	var panel = PANEL_CONFIGURACION.instantiate()
	# A media partida no se ofrece borrar: el siguiente guardado recrearía la
	# partida en curso.
	panel.permitir_borrar_partidas = false
	panel_pausa.hide()
	panel.cerrado.connect(panel_pausa.show)
	add_child(panel)

func _on_btn_ir_menu_pressed():
	alternar_pausa()
	get_tree().change_scene_to_file("res://Scenes/MenuPrincipal.tscn")

func _mostrar_animacion_guardando() -> void:
	# Contenedor principal con fondo
	var panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	# Ajustamos la posición para el pixel art
	panel.position = Vector2(-130, -40)
	
	# Usamos la textura oficial de los botones
	var estilo = StyleBoxTexture.new()
	estilo.texture = load("res://Images/Fondos/fondo_botones2.png")
	estilo.texture_margin_left = 6
	estilo.texture_margin_top = 6
	estilo.texture_margin_right = 6
	estilo.texture_margin_bottom = 6
	panel.add_theme_stylebox_override("panel", estilo)
	
	# HBox para poner el icono a la izquierda y el texto a la derecha
	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 6)
	panel.add_child(hbox)
	
	# Nodo del icono
	var icono = TextureRect.new()
	# ¡AQUÍ PONES TU TEXTURA OFICIAL LUEGO! Por ahora uso un placeholder
	icono.texture = load("res://icon.svg") 
	icono.custom_minimum_size = Vector2(16, 16)
	icono.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icono.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hbox.add_child(icono)
	
	# Etiqueta de texto
	var label = Label.new()
	label.text = "Guardando..."
	label.add_theme_color_override("font_color", Color("#3e2723")) # Color café oscuro
	label.add_theme_font_size_override("font_size", 12)
	hbox.add_child(label)
	
	# Si ya hay una notificación anterior, la borramos
	var viejo = get_node_or_null("AnimGuardando")
	if viejo: viejo.queue_free()
	
	panel.name = "AnimGuardando"
	add_child(panel)
	
	# Animación vinculada al panel (si el panel se borra, el tween se detiene)
	var tween = create_tween().bind_node(panel)
	tween.tween_property(panel, "modulate:a", 1.0, 0.3)
	
	# A la mitad de la animación, cambiamos el texto
	tween.tween_callback(func():
		if is_instance_valid(label):
			label.text = "Guardado"
			# Si consigues un segundo icono para "Éxito", puedes cambiarlo aquí:
			# icono.texture = load("res://Ruta/Al/Icono_Check_Verde.png")
	).set_delay(1.0)
	
	# Desaparecer suavemente
	tween.tween_property(panel, "modulate:a", 0.0, 1.0).set_delay(1.5)
	tween.tween_callback(panel.queue_free)

func _on_btn_guardar_pressed():
	if has_node("/root/Global"):
		get_node("/root/Global").guardar_partida()
		_mostrar_animacion_guardando()
		print("Partida guardada.")

func _on_btn_guardar_salir_pressed():
	if has_node("/root/Global"):
		get_node("/root/Global").guardar_partida()
	
	# Usar SceneTransition si existe
	if has_node("/root/SceneTransition"):
		get_node("/root/SceneTransition").change_scene("res://Scenes/MenuPrincipal.tscn")
	else:
		get_tree().change_scene_to_file("res://Scenes/MenuPrincipal.tscn")
	alternar_pausa()
