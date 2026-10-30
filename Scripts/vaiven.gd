class_name Vaiven
extends Node2D
## Decoración que va y viene entre x_min y x_max (canoas, aves). Al dar la vuelta
## se voltea entero, así que sus sprites deben mirar a la derecha.

@export var x_min: float = 0.0
@export var x_max: float = 640.0
@export var velocidad: float = 25.0
## Sube y baja en píxeles (oleaje de la canoa, aleteo del ave). 0 = recto.
@export var flotar: float = 0.0
@export var velocidad_flotar: float = 2.0

var _direccion: float = 1.0
var _y_base: float
var _tiempo: float = 0.0

func _ready() -> void:
	_y_base = position.y

func _process(delta: float) -> void:
	position.x += velocidad * _direccion * delta
	if position.x > x_max:
		_direccion = -1.0
	elif position.x < x_min:
		_direccion = 1.0
	scale.x = _direccion
	if flotar != 0.0:
		_tiempo += delta
		position.y = _y_base + sin(_tiempo * velocidad_flotar) * flotar
