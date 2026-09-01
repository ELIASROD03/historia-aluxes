class_name CinematicaKaan
extends Node2D

var cuadro_dialogo: DialogoManager
@export var sprite_kaan: Sprite2D
@export var offset_portal: Vector2 = Vector2(80, 0) # Distancia a la que aparece el portal
@export var invertir_direccion_caminar: bool = true # Activar si Kaan camina de reversa (Moonwalk)
@export var escala_portal: float = 1.0 # Qué tan grande se hará el portal al aparecer

@export_group("Texturas del Personaje")
@export var tex_idle: Texture2D = preload("res://Images/Personajes/Kaan/Kaan_Idle.png")
@export var tex_walking: Texture2D = preload("res://Images/Personajes/Kaan/kaan_walking.png")

@export_group("Nombres de Eventos (JSON)")
@export var evento_transformacion: String = "cinematica_transformacion_kaan"
@export var evento_escape: String = "cinematica_escape_kaan"

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
