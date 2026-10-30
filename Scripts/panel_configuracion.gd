extends Control
## Panel de configuración. Se instancia encima de la pantalla que lo abre y se
## destruye al cerrarse; trae su propio velo para que los clics no lleguen a lo de
## abajo. Tiene process_mode ALWAYS, así que también sirve con el juego en pausa.

signal cerrado

## La sección "Desarrollador" se esconde hasta tocar el título "Configuración"
## TOQUES_PARA_REVELAR veces (para que los niños no la activen por accidente).
## Ponlo en false para que se vea siempre; para quitar el truco del todo, borra
## esta variable, _on_titulo_input() y la línea que la usa en _ready().
@export var revelar_con_toques := true
const TOQUES_PARA_REVELAR := 5

# El tamaño "normal" de los botones táctiles se muestra como 100 %.
const TAMANO_NORMAL := 1.3

@onready var sliders_volumen := {
	"general": %SliderGeneral, "musica": %SliderMusica, "efectos": %SliderEfectos}
@onready var valores_volumen := {
	"general": %ValorGeneral, "musica": %ValorMusica, "efectos": %ValorEfectos}
@onready var seccion_pantalla: Control = %SeccionPantalla
@onready var chk_pantalla: CheckButton = %ChkPantallaCompleta
@onready var opt_modo: OptionButton = %OptModo
@onready var slider_tamano: HSlider = %SliderTamano
@onready var valor_tamano: Label = %ValorTamano
@onready var slider_opacidad: HSlider = %SliderOpacidad
@onready var valor_opacidad: Label = %ValorOpacidad
@onready var seccion_desarrollador: Control = %SeccionDesarrollador
@onready var chk_desarrollador: CheckButton = %ChkDesarrollador

var _toques_titulo := 0

func _ready() -> void:
	# Los valores se ponen ANTES de conectar las señales, para no escribir de vuelta
	# en Configuracion lo mismo que acabamos de leer de ahí.
	for clave in sliders_volumen:
		var slider: HSlider = sliders_volumen[clave]
		slider.value = Configuracion.volumen[clave]
		_mostrar_porcentaje(valores_volumen[clave], slider.value)
		slider.value_changed.connect(_on_volumen_cambiado.bind(clave))

	seccion_pantalla.visible = not Configuracion.es_movil()
	chk_pantalla.button_pressed = Configuracion.pantalla_completa
	chk_pantalla.toggled.connect(Configuracion.set_pantalla_completa)

	opt_modo.add_item("Automático", Configuracion.ModoTactil.AUTOMATICO)
	opt_modo.add_item("Siempre", Configuracion.ModoTactil.SIEMPRE)
	if not Configuracion.es_movil():
		opt_modo.add_item("Ocultos", Configuracion.ModoTactil.OCULTOS)
	opt_modo.select(opt_modo.get_item_index(Configuracion.modo_tactil))
	slider_tamano.min_value = Configuracion.TAMANO_TACTIL_MIN
	slider_tamano.max_value = Configuracion.TAMANO_TACTIL_MAX
	slider_tamano.value = Configuracion.tamano_tactil
	slider_opacidad.min_value = Configuracion.OPACIDAD_TACTIL_MIN
	slider_opacidad.value = Configuracion.opacidad_tactil
	_actualizar_textos_controles()
	opt_modo.item_selected.connect(_on_controles_cambiados.unbind(1))
	slider_tamano.value_changed.connect(_on_controles_cambiados.unbind(1))
	slider_opacidad.value_changed.connect(_on_controles_cambiados.unbind(1))

	chk_desarrollador.button_pressed = Configuracion.modo_desarrollador
	chk_desarrollador.toggled.connect(Configuracion.set_modo_desarrollador)
	# Si ya está activo se ve siempre, para poder apagarlo.
	seccion_desarrollador.visible = not revelar_con_toques or Configuracion.modo_desarrollador
	var titulo: Label = $Marco/VBox/Titulo
	titulo.mouse_filter = Control.MOUSE_FILTER_STOP
	titulo.gui_input.connect(_on_titulo_input)

	%BtnVolver.pressed.connect(cerrar)
	_poner_iconos()
	_estilo_desplegable()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		cerrar()

func cerrar() -> void:
	Configuracion.guardar()
	cerrado.emit()
	queue_free()

# --- Sonido ---

func _on_volumen_cambiado(valor: float, clave: String) -> void:
	Configuracion.set_volumen(clave, valor)
	_mostrar_porcentaje(valores_volumen[clave], valor)

func _mostrar_porcentaje(etiqueta: Label, fraccion: float) -> void:
	etiqueta.text = "%d%%" % roundi(fraccion * 100.0)

# --- Controles táctiles ---

func _on_controles_cambiados() -> void:
	Configuracion.set_controles(opt_modo.get_selected_id(), slider_tamano.value, slider_opacidad.value)
	_actualizar_textos_controles()

func _actualizar_textos_controles() -> void:
	_mostrar_porcentaje(valor_tamano, slider_tamano.value / TAMANO_NORMAL)
	_mostrar_porcentaje(valor_opacidad, slider_opacidad.value)
	# El tamaño y la opacidad no se notan si los botones van ocultos.
	var ocultos := opt_modo.get_selected_id() == Configuracion.ModoTactil.OCULTOS
	slider_tamano.editable = not ocultos
	slider_opacidad.editable = not ocultos

# --- Apariencia ---

## Un ícono pixel art a la izquierda del título de cada sección.
func _poner_iconos() -> void:
	var iconos := {
		"Marco/VBox/Columnas/ColIzquierda/TituloSonido": "bocina",
		"Marco/VBox/Columnas/ColIzquierda/SeccionPantalla/TituloPantalla": "pantalla",
		"Marco/VBox/Columnas/ColDerecha/TituloControles": "mano",
		"Marco/VBox/Columnas/ColDerecha/SeccionDesarrollador/TituloDesarrollador": "engrane",
	}
	for ruta in iconos:
		var titulo: Label = get_node(ruta)
		var padre := titulo.get_parent()
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 5)
		padre.add_child(fila)
		padre.move_child(fila, titulo.get_index())
		var icono := TextureRect.new()
		icono.texture = load("res://assets/configuracion/icono_%s.png" % iconos[ruta])
		icono.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		icono.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		fila.add_child(icono)
		titulo.reparent(fila)


## La lista que se abre en "Mostrar": madera oscura con letras de pergamino.
func _estilo_desplegable() -> void:
	var lista := opt_modo.get_popup()
	var fondo := StyleBoxFlat.new()
	fondo.bg_color = Color(0.243, 0.153, 0.137)
	fondo.border_color = Color(0.85, 0.62, 0.18)
	fondo.set_border_width_all(1)
	fondo.set_corner_radius_all(3)
	fondo.set_content_margin_all(4)
	lista.add_theme_stylebox_override("panel", fondo)
	var resaltado := StyleBoxFlat.new()
	resaltado.bg_color = Color(0.85, 0.62, 0.18, 0.35)
	resaltado.set_corner_radius_all(2)
	lista.add_theme_stylebox_override("hover", resaltado)
	lista.add_theme_color_override("font_color", Color(0.93, 0.86, 0.7))
	lista.add_theme_color_override("font_hover_color", Color.WHITE)
	lista.add_theme_font_override("font", preload("res://fonts/Amaranth-Bold.ttf"))


# --- Desarrollador ---

## Toques (o clics) en el título: al llegar a TOQUES_PARA_REVELAR aparece la sección.
## Solo se cuenta el clic: en celular Godot convierte cada toque en clic, y contar
## también el toque lo duplicaría.
func _on_titulo_input(event: InputEvent) -> void:
	var toque: bool = event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	if not toque or seccion_desarrollador.visible:
		return
	_toques_titulo += 1
	var titulo: Label = $Marco/VBox/Titulo
	# Cada toque se nota: el título salta y dice cuántos faltan
	titulo.pivot_offset = titulo.size / 2.0
	var t := create_tween()
	t.tween_property(titulo, "scale", Vector2(1.08, 1.08), 0.06)
	t.tween_property(titulo, "scale", Vector2.ONE, 0.08)
	var faltan := TOQUES_PARA_REVELAR - _toques_titulo
	if faltan > 0:
		titulo.text = "Configuración  (%d)" % faltan
	else:
		titulo.text = "Configuración"
		seccion_desarrollador.show()
