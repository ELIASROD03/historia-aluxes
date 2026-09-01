extends Control

@onready var lista_partidas = $Scroll/ListaPartidas
@onready var btn_volver = $BtnVolver

func _ready() -> void:
	if btn_volver:
		btn_volver.pressed.connect(_on_volver)
	
	var global = get_node_or_null("/root/Global")
	if not global: return
	
	var partidas = global.obtener_partidas()
	
	if partidas.is_empty():
		var lbl_vacio = Label.new()
		lbl_vacio.text = "No hay partidas guardadas actualmente."
		lbl_vacio.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lista_partidas.add_child(lbl_vacio)
	else:
		for p in partidas:
			var panel_item = PanelContainer.new()
			var hbox = HBoxContainer.new()
			panel_item.add_child(hbox)
			
			# Contenedor del Avatar Animado
			var avatar_container = Control.new()
			avatar_container.custom_minimum_size = Vector2(64, 64)
			hbox.add_child(avatar_container)
			
			var sprite = AnimatedSprite2D.new()
			sprite.position = Vector2(32, 32)
			sprite.scale = Vector2(1.0, 1.0)
			
			var frames = SpriteFrames.new()
			frames.add_animation("respirando")
			frames.set_animation_loop("respirando", true)
			frames.set_animation_speed("respirando", 8.0)
			
			var ruta = p.get("ruta_spritesheet", "")
			if ruta != "" and ResourceLoader.exists(ruta):
				var tex = load(ruta)
				var num_frames = 9
				var frame_width = tex.get_width() / num_frames
				var frame_height = tex.get_height()
				for i in range(num_frames):
					var atlas = AtlasTexture.new()
					atlas.atlas = tex
					atlas.region = Rect2(i * frame_width, 0, frame_width, frame_height)
					frames.add_frame("respirando", atlas)
			
			sprite.sprite_frames = frames
			sprite.play("respirando")
			avatar_container.add_child(sprite)
			
			# Info (Nombre, Tiempo)
			var info = Label.new()
			var mins = int(p["tiempo"]) / 60
			var secs = int(p["tiempo"]) % 60
			info.text = " %s  |  Tiempo: %02d:%02d" % [p["nombre"], mins, secs]
			info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			info.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			hbox.add_child(info)
			
			# Botón Cargar
			var btn_cargar = Button.new()
			btn_cargar.text = " Cargar "
			btn_cargar.pressed.connect(func(): _on_cargar(p["slot"]))
			hbox.add_child(btn_cargar)
			
			# Botón Eliminar
			var btn_eliminar = Button.new()
			btn_eliminar.text = " Borrar "
			btn_eliminar.modulate = Color(1.0, 0.4, 0.4)
			btn_eliminar.pressed.connect(func(): _on_borrar(p["slot"]))
			hbox.add_child(btn_eliminar)
			
			lista_partidas.add_child(panel_item)

func _on_cargar(slot: String) -> void:
	var global = get_node("/root/Global")
	if global.cargar_partida(slot):
		var destino = global.escena_actual
		var transition = get_node_or_null("/root/SceneTransition")
		if transition:
			transition.change_scene(destino)
		else:
			get_tree().change_scene_to_file(destino)

func _on_borrar(slot: String) -> void:
	var global = get_node("/root/Global")
	global.eliminar_partida(slot)
	# Recargar la pantalla para actualizar la lista
	get_tree().reload_current_scene()

func _on_volver() -> void:
	var transition = get_node_or_null("/root/SceneTransition")
	if transition:
		transition.change_scene("res://Scenes/MenuPrincipal.tscn")
	else:
		get_tree().change_scene_to_file("res://Scenes/MenuPrincipal.tscn")
