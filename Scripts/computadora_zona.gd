extends Node2D
## La computadora del laboratorio. Su monitor derecho transmite la zona de
## resguardo (brilla turquesa cuando hay aluxes adentro) y al interactuar con
## ella se abre ZonaAluxes a pantalla completa.

const ESCENA_ZONA := preload("res://Scenes/ZonaAluxes.tscn")

## Pantallas del sprite computadora.png, relativas a este nodo (centro del sprite).
const PANTALLA_ZONA := Rect2(-1, -14, 13, 9)
const PANTALLA_DATOS := Rect2(-18, -13, 10, 7)

var _zona: Node
var _t := 0.0
var _hay_aluxes := false


func _ready() -> void:
	$Interactable.interacted.connect(_abrir_zona)
	_hay_aluxes = not ZonaAluxes.aluxes_en_zona().is_empty()


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var brillo := 0.5 + sin(_t * 2.2) * 0.2
	if _hay_aluxes:
		draw_rect(PANTALLA_ZONA, Color(0.2, 0.9, 0.85, brillo))
		# El anillo de glifos, en chiquito
		draw_arc(PANTALLA_ZONA.get_center(), 3.0, _t, _t + TAU * 0.75, 8, Color(0.8, 1, 1, 0.9), 1.0)
	else:
		draw_rect(PANTALLA_ZONA, Color(0.1, 0.3, 0.35, 0.4))
	# Renglones de datos que parpadean en el otro monitor
	for i in 3:
		if fmod(_t * 1.5 + i * 0.4, 1.0) < 0.75:
			var largo := 4.0 + fmod(i * 3.7 + floor(_t), 5.0)
			draw_rect(Rect2(PANTALLA_DATOS.position + Vector2(1, 1 + i * 2), Vector2(largo, 1)), Color(0.4, 1, 0.5, 0.7))


func _abrir_zona() -> void:
	if is_instance_valid(_zona):
		return
	_zona = ESCENA_ZONA.instantiate()
	get_tree().current_scene.add_child(_zona)
