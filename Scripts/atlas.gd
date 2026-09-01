extends CharacterBody2D

@export var follow_distance: float = 40.0
@export var speed: float = 120.0
@export var id_dialogo: String = "encuentro_atlas"

@export var tex_idle: Texture2D
@export var hframes_idle: int = 9

var following: bool = false
var player: Node2D
var cuadro_dialogo: Node
var zona_activada: bool = false

@onready var sprite = $Sprite2D if has_node("Sprite2D") else null

## Clave con la que se recuerda el encuentro. Se guarda ademas en
## Global.conoce_atlas, que es lo que viaja en el archivo de partida.
const CLAVE_CONOCIDO := "atlas_conocido"


func _ready():
	_resolver_referencias()

	# Ignorar colisiones con el jugador y cualquier otro NPC (CharacterBody2D)
	var raiz := _raiz_escena()
	if raiz:
		for p in raiz.find_children("*", "CharacterBody2D", true, false):
			if p != self:
				add_collision_exception_with(p)

	if cuadro_dialogo:
		# Conectamos la señal que agregamos en dialogo_manager.gd
		cuadro_dialogo.dialogo_terminado.connect(_on_dialogo_terminado)

	var area = get_node_or_null("Area2D")
	if area:
		area.body_entered.connect(_on_body_entered)

	if ya_conocido():
		_activar_modo_acompaniante()


## Raiz del nivel. Se prefiere `owner` sobre get_tree().current_scene porque
## durante el _ready de una escena recien cargada current_scene todavia puede
## apuntar a la anterior (o ser null), y entonces no se encontraba al Player:
## Atlas se quedaba plantado en su sitio original sin decir nada.
func _raiz_escena() -> Node:
	if owner:
		return owner
	if get_tree() and get_tree().current_scene:
		return get_tree().current_scene
	return get_parent()


func _resolver_referencias() -> void:
	var raiz := _raiz_escena()
	if raiz == null:
		return
	player = raiz.find_child("Player", true, false)
	cuadro_dialogo = raiz.find_child("CuadroDialogo", true, false)


## ¿El jugador ya se topo con Atlas alguna vez en esta partida?
func ya_conocido() -> bool:
	return Global.conoce_atlas or Global.eventos_completados.get(CLAVE_CONOCIDO, false)


## Deja a Atlas como acompañante: pegado al jugador y sin saludo pendiente.
func _activar_modo_acompaniante() -> void:
	following = true
	zona_activada = true
	var area = get_node_or_null("Area2D")
	if area:
		area.queue_free()   # sin area no puede volver a lanzar el saludo
	# Diferido para que el Player ya haya aplicado su posicion guardada (la fija
	# en su propio _ready, que corre despues del de Atlas)
	call_deferred("_teletransportar_al_jugador")


func _teletransportar_al_jugador():
	if player == null:
		_resolver_referencias()   # segundo intento: puede que antes no estuviera listo
	if player:
		# Lo colocamos a 40 píxeles detrás o al lado del jugador, y un poco más arriba si es necesario
		global_position = Vector2(player.global_position.x - 40, player.global_position.y - 10)


func _on_body_entered(body: Node2D):
	if not zona_activada and (body.name == "Player" or body is Player):
		if cuadro_dialogo and cuadro_dialogo.has_method("iniciar_dialogo") and not cuadro_dialogo.visible:
			zona_activada = true
			cuadro_dialogo.iniciar_dialogo(id_dialogo)
			# Se marca AL EMPEZAR, no al terminar: si el jugador se sale, guarda o
			# cambia de escena a media platica, el encuentro ya cuenta y Atlas no
			# vuelve a saludarlo como si fuera la primera vez.
			_marcar_conocido()


func _on_dialogo_terminado(id: String):
	if id == id_dialogo:
		_marcar_conocido()


func _marcar_conocido() -> void:
	following = true
	Global.conoce_atlas = true
	Global.eventos_completados[CLAVE_CONOCIDO] = true

func _set_texture(new_tex: Texture2D, frames: int) -> void:
	if sprite and sprite.texture != new_tex:
		sprite.texture = new_tex
		sprite.hframes = frames
		sprite.vframes = 1
		sprite.frame = 0
		if sprite.has_method("reset_timer"):
			sprite.reset_timer()

func _physics_process(delta):
	# Si no estamos siguiendo o estamos en diálogo, no nos movemos (solo gravedad)
	if not following or Global.en_dialogo or not player:
		velocity.x = 0
		if tex_idle:
			_set_texture(tex_idle, hframes_idle)
		if not is_on_floor():
			velocity.y += 980 * delta
		move_and_slide()
		return

	# Distancia del robot al jugador
	var distance_to_player = player.global_position.x - global_position.x

	# Si la distancia es mayor a la permitida, seguimos al jugador
	if abs(distance_to_player) > follow_distance:
		var dir = sign(distance_to_player)
		velocity.x = dir * speed
		
		if tex_idle:
			_set_texture(tex_idle, hframes_idle)
		
		# Opcional: Voltear el sprite según la dirección
		if sprite:
			sprite.flip_h = (dir > 0)
	else:
		velocity.x = 0
		if tex_idle:
			_set_texture(tex_idle, hframes_idle)

	# Aplicar gravedad
	if not is_on_floor():
		velocity.y += 980 * delta

	move_and_slide()
