extends Control
## Panel de configuración. Se instancia encima de la pantalla que lo abre y se
## destruye al cerrarse; trae su propio velo para que los clics no lleguen a lo de
## abajo. Tiene process_mode ALWAYS, así que también sirve con el juego en pausa.

signal cerrado

## Ponlo en false si lo abres a media partida: borrar la partida en curso y
## seguir jugando la volvería a crear en el siguiente guardado.
@export var permitir_borrar_partidas := true

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
@onready var seccion_partidas: Control = %SeccionPartidas
@onready var btn_borrar: Button = %BtnBorrar
@onready var lbl_partidas: Label = %LblPartidas
@onready var confirmacion: Control = %Confirmacion
@onready var lbl_confirmacion: Label = %LblConfirmacion

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

	seccion_partidas.visible = permitir_borrar_partidas
	btn_borrar.pressed.connect(_pedir_confirmacion)
	%BtnCancelar.pressed.connect(confirmacion.hide)
	%BtnConfirmar.pressed.connect(_borrar_partidas)
	%BtnVolver.pressed.connect(cerrar)
	confirmacion.hide()
	_actualizar_partidas()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		if confirmacion.visible:
			confirmacion.hide()
		else:
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

# --- Partidas guardadas ---

func _actualizar_partidas() -> void:
	var total := Global.obtener_partidas().size()
	match total:
		0: lbl_partidas.text = "No hay partidas guardadas."
		1: lbl_partidas.text = "1 partida guardada."
		_: lbl_partidas.text = "%d partidas guardadas." % total
	btn_borrar.disabled = total == 0

func _pedir_confirmacion() -> void:
	var total := Global.obtener_partidas().size()
	var cuales := "la partida guardada" if total == 1 else "las %d partidas guardadas" % total
	lbl_confirmacion.text = "¿Borrar %s?\nEsto no se puede deshacer." % cuales
	confirmacion.show()

func _borrar_partidas() -> void:
	for partida in Global.obtener_partidas():
		Global.eliminar_partida(partida["slot"])
	confirmacion.hide()
	_actualizar_partidas()
