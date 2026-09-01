extends CharacterBody2D

@export var distancia_patrulla: float = 80.0
@export var velocidad: float = 30.0

@export var textura_idle: Texture2D
@export var textura_caminar: Texture2D

@export var hframes_idle: int = 1
@export var hframes_walk: int = 1

@export_group("Acción Extra (Opcional)")
@export var textura_accion: Texture2D
@export var hframes_accion: int = 1
@export var tiempo_caminando_antes_de_accion: float = 0.0 ## 0 = desactivado
@export var duracion_accion: float = 1.0

@onready var sprite = $Sprite2D

var pos_inicial: float
var direccion: int = 1

var temporizador_accion: float = 0.0
var en_accion: bool = false

# Variables para controlar la animación (por si no usan AnimationPlayer)
var anim_timer: float = 0.0
var anim_speed: float = 0.15

func _ready():
	pos_inicial = global_position.x
	_actualizar_textura(textura_caminar, hframes_walk)
	if tiempo_caminando_antes_de_accion > 0.0:
		temporizador_accion = tiempo_caminando_antes_de_accion

func _physics_process(delta):
	var esta_hablando = false
	if has_node("BurbujaMundo"):
		var burbuja = get_node("BurbujaMundo")
		if burbuja.fondo.visible:
			esta_hablando = true

	# Detenerse si el jugador está en un diálogo global o si este NPC está mostrando su burbuja
	if Global.en_dialogo or esta_hablando:
		velocity.x = 0
		en_accion = false # Cancelar acción extra si ocurre un diálogo
		_actualizar_textura(textura_idle, hframes_idle)
		_procesar_animacion(delta)
		move_and_slide()
		return
		
	if en_accion:
		velocity.x = 0
		_actualizar_textura(textura_accion, hframes_accion)
		temporizador_accion -= delta
		if temporizador_accion <= 0.0:
			en_accion = false
			temporizador_accion = tiempo_caminando_antes_de_accion
	else:
		# Patrullar de lado a lado
		velocity.x = direccion * velocidad
		
		if global_position.x > pos_inicial + distancia_patrulla:
			direccion = -1
			sprite.flip_h = true
		elif global_position.x < pos_inicial - distancia_patrulla:
			direccion = 1
			sprite.flip_h = false
			
		_actualizar_textura(textura_caminar, hframes_walk)
		
		# Lógica para intercalar acción extra mientras camina
		if tiempo_caminando_antes_de_accion > 0.0 and textura_accion != null:
			temporizador_accion -= delta
			if temporizador_accion <= 0.0:
				en_accion = true
				temporizador_accion = duracion_accion
		
	_procesar_animacion(delta)
	move_and_slide()

# Función para cambiar entre spritesheet de caminar e idle
func _actualizar_textura(nueva_tex: Texture2D, nuevos_hframes: int):
	if sprite.texture != nueva_tex:
		sprite.texture = nueva_tex
		sprite.hframes = nuevos_hframes
		sprite.vframes = 1
		sprite.frame = 0

# Reproductor de animación interno para spritesheets
func _procesar_animacion(delta):
	anim_timer += delta
	if anim_timer >= anim_speed:
		anim_timer = 0.0
		if sprite.hframes > 1:
			sprite.frame = (sprite.frame + 1) % sprite.hframes
