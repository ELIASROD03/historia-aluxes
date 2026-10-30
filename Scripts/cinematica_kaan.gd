class_name CinematicaKaan
extends Node2D

var cuadro_dialogo: DialogoManager
@export var sprite_kaan: Sprite2D
@export var offset_portal: Vector2 = Vector2(80, 0) # Distancia a la que aparece el portal
@export var invertir_direccion_caminar: bool = true # Activar si Kaan camina de reversa (Moonwalk)
@export var escala_portal: float = 1.0 # Qué tan grande se hará el portal al aparecer
## Tamaño de Kaan sin disfraz: es un alux, un poco más bajito que el jugador (~40 px).
## El disfraz de soldado se queda a tamaño humano.
@export var escala_alux: float = 0.85

# El piso queda 24 px bajo el centro del sprite (Kaan en y=200, piso en y=224) y
# en Kaan_Idle los pies están 23 px bajo el centro del cuadro de 64 px.
const PISO_BAJO_CENTRO := 24.0
const PIES_KAAN := 23.0

@export_group("Texturas del Personaje")
@export var tex_idle: Texture2D = preload("res://Images/Personajes/Kaan/Kaan_Idle.png")
@export var tex_walking: Texture2D = preload("res://Images/Personajes/Kaan/kaan_walking.png")

@export_group("Nombres de Eventos (JSON)")
@export var evento_transformacion: String = "cinematica_transformacion_kaan"
@export var evento_escape: String = "cinematica_escape_kaan"
@export var evento_bosque: String = "cinematica_kaan_bosque"
@export var evento_dormido: String = "cinematica_kaan_dormido"

@export_group("Huida al bosque (cap 2)")
## Cuánto corre Kaan (y sus dobles) hacia la derecha antes de perderse entre los árboles.
@export var distancia_bosque: float = 220.0
@export var numero_dobles: int = 3
## Sprite de Kaan dormido que aparece al ganar Topo Alux.
@export var tex_dormido: Texture2D
## Dónde aparece dormido, respecto a donde estaba antes de huir (el sprite dormido
## tiene aire abajo, por eso baja un poco).
@export var ajuste_dormido: Vector2 = Vector2(40, 14)

var _pos_antes_de_huir: Vector2

var tex_portal = preload("res://Images/Fondos/portal.png")
var script_respirador = preload("res://Scripts/respirador.gd")

var portal_sprite: Sprite2D

func _ready():
	# Si no arrastraste el cuadro en el inspector, lo busca automáticamente
	if cuadro_dialogo == null:
		var nodo = get_tree().current_scene.find_child("Cuadro*", true, false)
		if nodo and nodo.has_method("continuar_cinematica"):
			cuadro_dialogo = nodo
			
	if cuadro_dialogo:
		cuadro_dialogo.connect("evento_cinematica", Callable(self, "_on_evento_cinematica"))

func _on_evento_cinematica(evento: String):
	if evento == evento_transformacion:
		ejecutar_transformacion()
	elif evento == evento_escape:
		ejecutar_escape()
	elif evento == evento_bosque:
		ejecutar_huida_bosque()
	elif evento == evento_dormido:
		ejecutar_dormido()

func ejecutar_transformacion():
	# 1. Si se perdió la referencia al sprite, intentar buscarlo en la escena automáticamente
	if sprite_kaan == null:
		var nodo = get_tree().current_scene.find_child("Kaan*", true, false)
		if nodo is Sprite2D or nodo is Node2D:
			sprite_kaan = nodo
		else:
			if cuadro_dialogo: cuadro_dialogo.continuar_cinematica()
			return
			
	# Asegurarnos de que el script siga funcionando aunque el diálogo pause el juego
	self.process_mode = Node.PROCESS_MODE_ALWAYS
		
	# 2. Crear partículas verdes (Sistema manual para evadir el bug de Android)
	# Al crear CPUParticles2D por código, Godot 4 en Android a veces crashea compilando shaders.
	# Crear ColorRects animados es 100% seguro en móviles.
	for i in range(30):
		var p = ColorRect.new()
		p.color = Color(0.2, 1.0, 0.2, 1.0)
		p.size = Vector2(3, 3)
		# Posición aleatoria en un radio de 15 píxeles
		p.position = Vector2(randf_range(-15, 15), randf_range(-10, 20))
		sprite_kaan.add_child(p)
		
		var t = get_tree().create_tween()
		t.bind_node(p)
		# Animarlas hacia arriba simulando gravedad invertida (-30) y desvanecerlas
		var duracion = randf_range(0.6, 1.0)
		var target_pos = p.position + Vector2(randf_range(-10, 10), -randf_range(30, 60))
		
		t.tween_property(p, "position", target_pos, duracion).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		t.parallel().tween_property(p, "modulate:a", 0.0, duracion)
		t.tween_callback(p.queue_free)
	
	# Esperar un poco a que la animación de las partículas termine
	await get_tree().create_timer(1.0).timeout
	
	# Cambiar textura a Kaan Idle y recalcular animación
	if sprite_kaan.get("texture") != null:
		sprite_kaan.texture = tex_idle
		sprite_kaan.hframes = 1
		sprite_kaan.vframes = 1
		sprite_kaan.frame = 0
	_encoger_kaan()

	# Forzar al script respirador a recalcular los frames
	if sprite_kaan.has_method("_ready"):
		sprite_kaan._ready()
	if sprite_kaan.has_method("reset_timer"):
		sprite_kaan.reset_timer()
	
	# Reanudar diálogo
	if cuadro_dialogo:
		cuadro_dialogo.continuar_cinematica()

func ejecutar_escape():
	if sprite_kaan == null:
		var nodo = get_tree().current_scene.find_child("Kaan*", true, false)
		if nodo is Sprite2D or nodo is Node2D:
			sprite_kaan = nodo
		else:
			if cuadro_dialogo: cuadro_dialogo.continuar_cinematica()
			return
			
	self.process_mode = Node.PROCESS_MODE_ALWAYS
		
	# Aparecer portal
	portal_sprite = Sprite2D.new()
	portal_sprite.texture = tex_portal
	
	# Como el portal es de 3x3, le indicamos directamente los frames
	portal_sprite.hframes = 3
	portal_sprite.vframes = 3
	portal_sprite.frame = 0
	
	portal_sprite.global_position = sprite_kaan.global_position + offset_portal
	portal_sprite.scale = Vector2.ZERO # Empezar pequeño
	portal_sprite.process_mode = Node.PROCESS_MODE_ALWAYS # Permitir funcionar en pausa
	
	add_child(portal_sprite)
	
	# Asignar script DESPUÉS de agregarlo al árbol para evitar el error '!is_inside_tree()'
	portal_sprite.set_script(script_respirador)
	
	# Llamar a _ready por si el script necesita auto-configurar la animación (como los 9 frames)
	if portal_sprite.has_method("_ready"):
		portal_sprite._ready()
	if portal_sprite.has_method("reset_timer"):
		portal_sprite.reset_timer()
	
	# Animar aparición del portal
	var tween = get_tree().create_tween()
	# Asegurar que el tween funcione aunque el juego esté en pausa por el diálogo
	tween.bind_node(portal_sprite)
	tween.tween_property(portal_sprite, "scale", Vector2(escala_portal, escala_portal), 0.5)
	await tween.finished
	
	# Kaan camina hacia el portal y actualizamos su animación
	if sprite_kaan.get("texture") != null:
		sprite_kaan.texture = tex_walking
		sprite_kaan.hframes = 1
		sprite_kaan.vframes = 1
		sprite_kaan.frame = 0
	if sprite_kaan.has_method("_ready"):
		sprite_kaan._ready()
	if sprite_kaan.has_method("reset_timer"):
		sprite_kaan.reset_timer()
		
	# Logica invertida para corregir el "Moonwalking"
	var va_hacia_la_derecha = offset_portal.x > 0
	if invertir_direccion_caminar:
		sprite_kaan.flip_h = va_hacia_la_derecha # Voltear si la imagen base mira al lado opuesto
	else:
		sprite_kaan.flip_h = not va_hacia_la_derecha
		
	var tween_walk = get_tree().create_tween()
	tween_walk.bind_node(sprite_kaan)
	tween_walk.tween_property(sprite_kaan, "global_position", portal_sprite.global_position, 1.5)
	await tween_walk.finished
	
	# Kaan desaparece
	sprite_kaan.visible = false
	
	# Portal desaparece
	var tween_portal = get_tree().create_tween()
	tween_portal.bind_node(portal_sprite)
	tween_portal.tween_property(portal_sprite, "scale", Vector2.ZERO, 0.5)
	await tween_portal.finished
	if is_instance_valid(portal_sprite):
		portal_sprite.queue_free()
	
	# Reanudar diálogo
	if cuadro_dialogo:
		cuadro_dialogo.continuar_cinematica()

## Cap 2: Kaan hace dobles de sí mismo y todos corren a esconderse en el bosque.
## Al terminar, Kaan queda oculto (antes se quedaba parado en el nivel).
func ejecutar_huida_bosque():
	if sprite_kaan == null:
		var nodo = get_tree().current_scene.find_child("Kaan*", true, false)
		if nodo is Sprite2D:
			sprite_kaan = nodo
		else:
			if cuadro_dialogo: cuadro_dialogo.continuar_cinematica()
			return

	self.process_mode = Node.PROCESS_MODE_ALWAYS
	_pos_antes_de_huir = sprite_kaan.position

	_poner_textura(sprite_kaan, tex_walking)
	sprite_kaan.flip_h = invertir_direccion_caminar

	# Los dobles salen de Kaan con un destello verde y corren con él
	var corredores: Array[Sprite2D] = [sprite_kaan]
	for i in range(numero_dobles):
		# Sprite nuevo y no duplicate(): Kaan tiene de hijo su zona de diálogo y no debe copiarse
		var doble := Sprite2D.new()
		doble.texture = sprite_kaan.texture
		doble.hframes = sprite_kaan.hframes
		doble.vframes = sprite_kaan.vframes
		doble.flip_h = sprite_kaan.flip_h
		doble.scale = sprite_kaan.scale
		doble.position = sprite_kaan.position + Vector2(randf_range(-30, 30), 0)
		doble.modulate.a = 0.0
		doble.process_mode = Node.PROCESS_MODE_ALWAYS
		sprite_kaan.get_parent().add_child(doble)
		doble.set_script(script_respirador)
		doble._ready()
		var t_aparece = get_tree().create_tween()
		t_aparece.bind_node(doble)
		t_aparece.tween_property(doble, "modulate:a", 1.0, 0.3)
		corredores.append(doble)
	await get_tree().create_timer(0.5).timeout

	var ultimo: Tween
	for i in range(corredores.size()):
		var c := corredores[i]
		var t = get_tree().create_tween()
		t.bind_node(c)
		var destino := c.position + Vector2(distancia_bosque + i * 25, 0)
		t.tween_property(c, "position", destino, 1.4 + i * 0.15)
		t.parallel().tween_property(c, "modulate:a", 0.0, 0.5).set_delay(1.0 + i * 0.15)
		ultimo = t
	await ultimo.finished

	for i in range(1, corredores.size()):
		corredores[i].queue_free()
	sprite_kaan.visible = false

	if cuadro_dialogo:
		cuadro_dialogo.continuar_cinematica()

## Cap 2: después de Topo Alux, Kaan aparece dormido junto al bosque con "Zzz".
func ejecutar_dormido():
	if sprite_kaan == null or tex_dormido == null:
		if cuadro_dialogo: cuadro_dialogo.continuar_cinematica()
		return

	self.process_mode = Node.PROCESS_MODE_ALWAYS

	_poner_textura(sprite_kaan, tex_dormido)
	sprite_kaan.position = _pos_antes_de_huir + ajuste_dormido
	sprite_kaan.flip_h = false
	sprite_kaan.modulate.a = 0.0
	sprite_kaan.visible = true
	var t = get_tree().create_tween()
	t.bind_node(sprite_kaan)
	t.tween_property(sprite_kaan, "modulate:a", 1.0, 0.6)

	# Las "Z" suben en bucle mientras siga en la escena
	var zzz := Label.new()
	zzz.text = "Zzz"
	zzz.add_theme_font_size_override("font_size", 10)
	zzz.add_theme_color_override("font_outline_color", Color.BLACK)
	zzz.add_theme_constant_override("outline_size", 3)
	zzz.position = Vector2(4, -30)
	sprite_kaan.add_child(zzz)
	var tz = get_tree().create_tween().set_loops()
	tz.bind_node(zzz)
	tz.tween_property(zzz, "position:y", -44.0, 1.2)
	tz.parallel().tween_property(zzz, "modulate:a", 0.0, 1.2)
	tz.tween_callback(func(): zzz.position.y = -30.0; zzz.modulate.a = 1.0)

	await t.finished
	if cuadro_dialogo:
		cuadro_dialogo.continuar_cinematica()

## Al quitarse el disfraz Kaan pasa a su tamaño de alux, con los pies sobre el
## piso (si solo se encoge, queda flotando).
func _encoger_kaan() -> void:
	if sprite_kaan.scale.x != 1.0:
		return
	sprite_kaan.scale = Vector2.ONE * escala_alux
	sprite_kaan.position.y += PISO_BAJO_CENTRO - PIES_KAAN * escala_alux

func _poner_textura(sprite: Sprite2D, tex: Texture2D) -> void:
	sprite.texture = tex
	sprite.hframes = 1
	sprite.vframes = 1
	sprite.frame = 0
	if sprite.has_method("_ready"):
		sprite._ready()
	if sprite.has_method("reset_timer"):
		sprite.reset_timer()
