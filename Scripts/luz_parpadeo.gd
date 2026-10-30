class_name LuzParpadeo
extends PointLight2D
## Luz cálida que tiembla un poco, como una antorcha o una linterna de aceite.
## Se usa en el cap 2 (Noche Triste) para la luz del jugador y las antorchas.

@export var variacion_energia: float = 0.15
@export var variacion_tamano: float = 0.05
@export var velocidad: float = 6.0

var _energia_base: float
var _escala_base: float
var _tiempo: float

func _ready() -> void:
	_energia_base = energy
	_escala_base = texture_scale
	# Cada luz arranca en un punto distinto para que no parpadeen al mismo tiempo.
	_tiempo = randf() * 10.0

func _process(delta: float) -> void:
	_tiempo += delta * velocidad
	var ruido := sin(_tiempo) * 0.6 + sin(_tiempo * 2.3) * 0.4
	energy = _energia_base * (1.0 + ruido * variacion_energia)
	texture_scale = _escala_base * (1.0 + ruido * variacion_tamano)
