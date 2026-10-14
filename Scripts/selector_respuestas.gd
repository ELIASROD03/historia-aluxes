extends CanvasLayer
## Cuadro del jugador para elegir qué responderle a un NPC que habla en burbuja.
## Se ve igual que el cuadro de diálogo (mismo marco, retrato y letra), pero en
## vez de texto trae botones.
##
## Es una escena APARTE del cuadro de diálogo a propósito: DialogoManager escucha
## con _input y avanza con cualquier clic (trampa 1 de resumen_cambios.md), así
## que unos botones dentro de él también harían avanzar el diálogo.
##
## Uso (desde burbuja_mundo.gd):
##     var selector = SELECTOR.instantiate()
##     get_tree().current_scene.add_child(selector)
##     var elegida: int = await selector.preguntar(["Opción A", "Opción B"])

signal elegido(indice: int)

## Mismo retrato que usan las líneas del jugador en dialogos.json.
const RETRATO_JUGADOR := "res://Images/Personajes/Personajes_Principales/Personaje1/personaje.png"
const PREFIJO_FOCO := "» "

@onready var nombre_label: Label = $Caja/nombre_label
@onready var retrato: Sprite2D = $Caja/Retrato
@onready var opciones_box: VBoxContainer = $Caja/Opciones
@onready var boton_modelo: Button = $Caja/Opciones/BotonModelo

var _textos: Array = []


func _ready() -> void:
	boton_modelo.hide()
	nombre_label.text = Global.nombre_jugador
	if ResourceLoader.exists(RETRATO_JUGADOR):
		retrato.texture = load(RETRATO_JUGADOR)


## Muestra las opciones y devuelve el índice de la elegida. Mientras tanto el
## jugador se queda quieto, igual que en un diálogo.
func preguntar(textos: Array) -> int:
	_textos = textos
	Global.en_dialogo = true
	for i in textos.size():
		var boton := boton_modelo.duplicate() as Button
		boton.show()
		boton.text = "  " + str(textos[i])
		boton.pressed.connect(_on_elegir.bind(i))
		boton.focus_entered.connect(_marcar.bind(boton, i, true))
		boton.focus_exited.connect(_marcar.bind(boton, i, false))
		boton.mouse_entered.connect(boton.grab_focus)
		opciones_box.add_child(boton)
	# Un cuadro después: si no, el mismo Enter que cerró la burbuja "pulsaría" la
	# primera opción en cuanto recibe el foco.
	await get_tree().process_frame
	if opciones_box.get_child_count() > 1:
		(opciones_box.get_child(1) as Button).grab_focus()
	var indice: int = await elegido
	Global.en_dialogo = false
	queue_free()
	return indice


func _marcar(boton: Button, i: int, con_foco: bool) -> void:
	boton.text = (PREFIJO_FOCO if con_foco else "  ") + str(_textos[i])


func _on_elegir(i: int) -> void:
	for boton in opciones_box.get_children():
		(boton as Button).disabled = true
	elegido.emit(i)
