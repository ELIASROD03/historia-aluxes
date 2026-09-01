extends CharacterBody2D

## Atlas dentro del minijuego Atlas-Bird.
##
## Hay dos formas de volar y se elige en el INSPECTOR (nodo "atlas" de
## main-atlasbird.tscn), no en atlasbird.json:
##   TAP      - el clasico de Flappy Bird: cada toque da un impulso hacia arriba.
##   MANTENER - mientras se tiene presionado sube y al soltar cae.
## Siempre vuela con la nariz un poco inclinada hacia la derecha; la inclinacion
## solo se exagera hacia arriba o hacia abajo segun la velocidad vertical.

signal toco_suelo

enum ModoControl { TAP, MANTENER }

@export var modo_control: ModoControl = ModoControl.TAP
## Velocidad que toma Atlas de golpe con cada toque (modo TAP). Negativa = sube.
@export var impulso_tap: float = -290.0
## Aceleracion mientras se mantiene presionado (solo modo MANTENER).
@export var empuje: float = 1700.0

@export var gravedad: float = 950.0
@export var velocidad_max_caida: float = 300.0
@export var velocidad_max_subida: float = 300.0

@export_group("Limites de pantalla")
@export var limite_arriba: float = 14.0
@export var limite_suelo: float = 338.0

@export_group("Inclinacion")
@export var inclinacion_base: float = 10.0
@export var inclinacion_min: float = -10.0
@export var inclinacion_max: float = 34.0

## Mientras es false Atlas flota en su sitio (pantalla de inicio / avisos).
var activo: bool = false
## Lo pone en true el hechizo de Balaam: presionar hace bajar en vez de subir.
var controles_invertidos: bool = false
var invulnerable: bool = false

var _tiempo_flotando: float = 0.0
var _y_reposo: float = 0.0
var _parpadeo: float = 0.0
## Dedos/clics activos ahora mismo y estado de la tecla, para el control de mantener.
var _dedos: Dictionary = {}
var _tecla: bool = false


func _ready() -> void:
	_y_reposo = position.y
	rotation_degrees = inclinacion_base


## Solo pisa los numeros de vuelo. El modo de control NO se toca aqui a proposito:
## se decide en el inspector para poder probarlo sin editar el JSON.
func configurar(cfg: Dictionary) -> void:
	gravedad = float(cfg.get("gravedad", gravedad))
	empuje = float(cfg.get("empuje", empuje))
	impulso_tap = float(cfg.get("impulso_tap", impulso_tap))
	velocidad_max_caida = float(cfg.get("velocidad_max_caida", velocidad_max_caida))
	velocidad_max_subida = float(cfg.get("velocidad_max_subida", velocidad_max_subida))
	inclinacion_base = float(cfg.get("inclinacion_base", inclinacion_base))
	inclinacion_min = float(cfg.get("inclinacion_min", inclinacion_min))
	inclinacion_max = float(cfg.get("inclinacion_max", inclinacion_max))


func reiniciar() -> void:
	activo = false
	controles_invertidos = false
	invulnerable = false
	_dedos.clear()
	_tecla = false
	velocity = Vector2.ZERO
	position.y = _y_reposo
	rotation_degrees = inclinacion_base
	modulate.a = 1.0


## El estado de "presionado" se arma a mano desde los eventos en vez de usar
## Input.is_mouse_button_pressed(): el proyecto tiene emulate_touch_from_mouse
## activado, asi que el clic del raton llega como InputEventScreenTouch y el
## sondeo del boton del raton devolveria false en escritorio.
func _input(event: InputEvent) -> void:
	var toque_nuevo := false

	if event is InputEventScreenTouch:
		if event.pressed:
			_dedos[event.index] = true
			toque_nuevo = true
		else:
			_dedos.erase(event.index)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_dedos[-1] = true
			toque_nuevo = true
		else:
			_dedos.erase(-1)
	elif event.is_action("ui_accept"):
		# echo = true es la repeticion automatica de la tecla mantenida; en modo
		# TAP no debe contar como aleteos nuevos.
		if event.is_pressed() and not _tecla and not event.is_echo():
			toque_nuevo = true
		_tecla = event.is_pressed()

	if toque_nuevo and modo_control == ModoControl.TAP:
		_aletear()


## Impulso seco de Flappy Bird: fija la velocidad, no la acumula.
func _aletear() -> void:
	if not activo:
		return
	velocity.y = -impulso_tap if controles_invertidos else impulso_tap


func _entrada_presionada() -> bool:
	return _tecla or not _dedos.is_empty()


func _physics_process(delta: float) -> void:
	_animar_parpadeo(delta)

	if not activo:
		# Flotacion suave de espera: se ve vivo sin que el jugador pierda.
		_tiempo_flotando += delta
		position.y = _y_reposo + sin(_tiempo_flotando * 2.0) * 6.0
		rotation_degrees = lerp(rotation_degrees, inclinacion_base, 6.0 * delta)
		return

	# En TAP invertido hay que voltear TAMBIEN la gravedad, no solo el impulso:
	# si solo se voltea el toque, el aleteo empuja hacia abajo igual que la
	# gravedad y Atlas se estrella sin remedio, no hay forma de subir.
	# Volteada la gravedad, flota hacia el techo y cada toque lo hunde: el
	# hechizo se vuelve jugable y de verdad se siente al reves.
	var gravedad_invertida := _gravedad_invertida()
	velocity.y += (-gravedad if gravedad_invertida else gravedad) * delta

	# En modo TAP el impulso ya se aplico en _input; aqui solo cae.
	if modo_control == ModoControl.MANTENER:
		var subiendo := _entrada_presionada()
		if controles_invertidos:
			subiendo = not subiendo
		if subiendo:
			velocity.y -= empuje * delta

	velocity.y = clamp(velocity.y, -velocidad_max_subida, velocidad_max_caida)
	velocity.x = 0.0

	move_and_slide()

	# Con la gravedad volteada el lado peligroso es el techo, no el suelo.
	if position.y <= limite_arriba:
		if gravedad_invertida:
			position.y = limite_arriba + 30.0
			velocity.y = 180.0
			toco_suelo.emit()
		else:
			position.y = limite_arriba
			velocity.y = max(velocity.y, 0.0)   # el techo no hace daño, solo frena
	elif position.y >= limite_suelo:
		if gravedad_invertida:
			position.y = limite_suelo
			velocity.y = min(velocity.y, 0.0)   # ahora el suelo es el que solo frena
		else:
			position.y = limite_suelo - 30.0
			velocity.y = -180.0
			toco_suelo.emit()

	_actualizar_inclinacion(delta)


## Solo el modo TAP voltea la gravedad. En MANTENER no hace falta: ahi invertir
## ya funciona solo (presionar cae, soltar sube), asi que se deja tal cual.
func _gravedad_invertida() -> bool:
	return controles_invertidos and modo_control == ModoControl.TAP


func _actualizar_inclinacion(delta: float) -> void:
	var f := clampf(velocity.y / velocidad_max_caida, -1.0, 1.0)
	var objetivo := lerpf(inclinacion_min, inclinacion_max, (f + 1.0) / 2.0)
	rotation_degrees = lerp(rotation_degrees, objetivo, 7.0 * delta)


func activar_invulnerabilidad(segundos: float) -> void:
	invulnerable = true
	_parpadeo = 0.0
	await get_tree().create_timer(segundos).timeout
	if not is_inside_tree():
		return
	invulnerable = false
	modulate.a = 1.0


func _animar_parpadeo(delta: float) -> void:
	if invulnerable:
		_parpadeo += delta
		modulate.a = 0.35 if fmod(_parpadeo, 0.24) < 0.12 else 1.0
	elif modulate.a != 1.0:
		modulate.a = 1.0
