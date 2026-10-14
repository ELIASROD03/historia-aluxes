extends Control
## Minijuego "Fuercitas": Atlas contra Chaac (capítulo 3).
##
## El jugador pica la pantalla (o Enter) para empujar; Chaac empuja de vuelta
## cada vez más fuerte. Cada tanto se carga el botón de "Contar un chisme": uno de
## los secretos que contó Kaan en el laboratorio desconcentra a Chaac unos segundos
## y Atlas le gana terreno. Es la escena del GDD en la que el protagonista suelta
## los chismes de Kaan.
##
## NO está en el Libro de Historia a propósito: solo se abre desde el diálogo
## final_cap3 ("evento": "minijuego_fuercitas_cap3").
##
## Contrato de minijuego (ver resumen_cambios.md): `nivel_a_cargar` y la señal
## `juego_completado`. Perder nunca deja al jugador encerrado: siempre hay
## "Otra vez", y cada derrota le quita fuerza a Chaac.

signal juego_completado

## Lo asigna DialogoManager ("cap3"). Este minijuego no tiene niveles todavía.
var nivel_a_cargar: String = ""
## true si se corrió la escena sola (F6) y no desde un diálogo: solo así hay botón
## para salir, porque abierta desde el diálogo la cierra el propio diálogo.
var modo_libre: bool = false

@export_group("Equilibrio")
## Cuánto avanza Atlas por cada toque (la barra va de -1 a 1).
@export var empuje_por_toque: float = 0.04
## Fuerza de Chaac al empezar y al final, en barra por segundo.
@export var fuerza_chaac_inicial: float = 0.15
@export var fuerza_chaac_maxima: float = 0.3
## Segundos que tarda Chaac en llegar a su fuerza máxima.
@export var segundos_para_fuerza_maxima: float = 20.0
## Cada derrota multiplica la fuerza de Chaac por esto (ayuda para no atorarse).
@export var ayuda_por_derrota: float = 0.8

@export_group("Chismes")
@export var segundos_recarga_chisme: float = 6.0
@export var segundos_desconcentrado: float = 2.5
## Mientras está desconcentrado, Chaac cede terreno solo (barra por segundo).
@export var retroceso_desconcentrado: float = 0.12
## Los secretos que contó Kaan. Se muestran en orden aleatorio sin repetirse hasta
## agotar la lista. Los dos primeros los menciona Kaan en "laboratorio_cap3" y
## Chaac en "final_cap3" (dialogos.json): si los cambias, cámbialos allá también.
@export var chismes: PackedStringArray = [
	"¡Chaac le tiene miedo a las iguanas!",
	"¡Chaac duerme en hamaca abrazado a una mazorca!",
	"¡Una vez Chaac se cayó a un cenote por presumir que sabía nadar!",
	"¡Chaac probó un chile habanero y lloró toda la tarde!",
	"¡Chaac se comió los papadzules de la ofrenda y culpó a Kaan!",
	"¡Chaac quiso echar una bomba yucateca y se le olvidó a la mitad!",
	"¡Una chachalaca regañó a Chaac por hacer mucho ruido!",
	"¡Chaac duerme con la luz prendida por miedo a la X'tabay!",
]

const COLOR_ATLAS := Color(0.35, 0.85, 1.0)
const COLOR_CHAAC := Color(1.0, 0.35, 0.25)
const ESCENA_MENU := "res://Scenes/MenuPrincipal.tscn"

enum Estado { INSTRUCCIONES, CUENTA_ATRAS, JUGANDO, TERMINADO }

var estado: int = Estado.INSTRUCCIONES
## -1 = gana Chaac, 0 = empate, 1 = gana Atlas.
var posicion: float = 0.0
var tiempo_jugando: float = 0.0
var recarga_chisme: float = 0.0
var desconcentrado: float = 0.0
var derrotas: int = 0
var _chismes_pendientes: Array = []

@onready var brazos: Control = $Brazos
@onready var barra: Control = $Barra
@onready var btn_chisme: Button = $BtnChisme
@onready var lbl_indicacion: Label = $LblIndicacion
@onready var lbl_chisme: Label = $LblChisme
@onready var lbl_chaac: Label = $Chaac/LblReaccion
@onready var cara_chaac: TextureRect = $Chaac/Cara
@onready var lbl_cuenta: Label = $LblCuenta
@onready var panel_instrucciones: Control = $PanelInstrucciones
@onready var panel_final: Control = $PanelFinal
@onready var lbl_final: Label = $PanelFinal/Marco/VBox/Titulo
@onready var lbl_final_sub: Label = $PanelFinal/Marco/VBox/Subtitulo
@onready var btn_otra_vez: Button = $PanelFinal/Marco/VBox/Botones/BtnOtraVez
@onready var btn_salir: Button = $PanelFinal/Marco/VBox/Botones/BtnSalir


func _ready() -> void:
	modo_libre = (get_parent() == get_tree().root)
	brazos.draw.connect(_dibujar_brazos)
	barra.draw.connect(_dibujar_barra)
	btn_chisme.pressed.connect(_contar_chisme)
	$PanelInstrucciones/Marco/VBox/BtnListo.pressed.connect(_empezar_cuenta_atras)
	btn_otra_vez.pressed.connect(_otra_vez)
	btn_salir.pressed.connect(_salir)
	btn_salir.visible = modo_libre
	panel_final.hide()
	lbl_cuenta.hide()
	lbl_chisme.text = ""
	lbl_chaac.text = ""
	_reiniciar_valores()
	panel_instrucciones.show()


func _reiniciar_valores() -> void:
	posicion = 0.0
	tiempo_jugando = 0.0
	recarga_chisme = segundos_recarga_chisme
	desconcentrado = 0.0
	_actualizar_boton_chisme()
	brazos.queue_redraw()
	barra.queue_redraw()


func _empezar_cuenta_atras() -> void:
	panel_instrucciones.hide()
	estado = Estado.CUENTA_ATRAS
	lbl_cuenta.show()
	for texto in ["3", "2", "1", "¡YA!"]:
		lbl_cuenta.text = texto
		await get_tree().create_timer(0.6).timeout
	lbl_cuenta.hide()
	estado = Estado.JUGANDO
	lbl_indicacion.text = "¡Toca rápido para empujar!"


# --- Entrada ---

# Toques y clics sobre el fondo. Los botones se quedan con sus propios clics, así
# que pulsar "Contar un chisme" no cuenta también como empujón. Solo se escucha
# el clic de mouse: el toque en pantalla llega convertido en clic, y escuchar los
# dos contaría doble con emulate_touch_from_mouse.
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_empujar()
		accept_event()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") and not event.is_echo():
		_empujar()
		get_viewport().set_input_as_handled()


func _empujar() -> void:
	if estado != Estado.JUGANDO:
		return
	posicion += empuje_por_toque
	brazos.queue_redraw()
	barra.queue_redraw()


func _contar_chisme() -> void:
	if estado != Estado.JUGANDO or recarga_chisme > 0.0:
		return
	if _chismes_pendientes.is_empty():
		_chismes_pendientes = Array(chismes)
		_chismes_pendientes.shuffle()
	lbl_chisme.text = "«%s»" % _chismes_pendientes.pop_back()
	lbl_chaac.text = "¡¿QUÉ?!\n¡¿QUIÉN TE DIJO?!"
	desconcentrado = segundos_desconcentrado
	recarga_chisme = segundos_recarga_chisme
	_actualizar_boton_chisme()


# --- Juego ---

func _process(delta: float) -> void:
	if estado != Estado.JUGANDO:
		return
	tiempo_jugando += delta

	if desconcentrado > 0.0:
		desconcentrado -= delta
		posicion += retroceso_desconcentrado * delta
		# Chaac tiembla de coraje mientras está desconcentrado.
		cara_chaac.position.x = _x_cara_chaac + randf_range(-2.0, 2.0)
		if desconcentrado <= 0.0:
			cara_chaac.position.x = _x_cara_chaac
			lbl_chaac.text = "¡GRRR!"
			lbl_chisme.text = ""
	else:
		posicion -= _fuerza_chaac() * delta

	if recarga_chisme > 0.0:
		recarga_chisme = maxf(recarga_chisme - delta, 0.0)
		_actualizar_boton_chisme()

	posicion = clampf(posicion, -1.0, 1.0)
	brazos.queue_redraw()
	barra.queue_redraw()

	if posicion >= 1.0:
		_terminar(true)
	elif posicion <= -1.0:
		_terminar(false)


var _x_cara_chaac: float:
	get:
		return $Chaac.size.x / 2.0 - cara_chaac.size.x / 2.0


func _fuerza_chaac() -> float:
	var avance := clampf(tiempo_jugando / segundos_para_fuerza_maxima, 0.0, 1.0)
	var fuerza := lerpf(fuerza_chaac_inicial, fuerza_chaac_maxima, avance)
	return fuerza * pow(ayuda_por_derrota, derrotas)


func _actualizar_boton_chisme() -> void:
	if recarga_chisme > 0.0:
		btn_chisme.text = "Chisme en %d..." % ceili(recarga_chisme)
		btn_chisme.modulate.a = 0.6
	else:
		btn_chisme.text = "¡Contar un chisme!"
		btn_chisme.modulate.a = 1.0


func _terminar(gano: bool) -> void:
	estado = Estado.TERMINADO
	lbl_chisme.text = ""
	cara_chaac.position.x = _x_cara_chaac
	if gano:
		lbl_chaac.text = "¡NO ES JUSTO!"
		lbl_final.text = "¡Atlas gana las fuercitas!"
		lbl_final_sub.text = "Chaac no pudo concentrarse con tantos chismes."
		btn_otra_vez.hide()
	else:
		derrotas += 1
		lbl_chaac.text = "¡JA, JA, JA!"
		lbl_final.text = "¡Chaac ganó esta vez!"
		lbl_final_sub.text = "Atlas ajusta sus motores: Chaac ya no empujará tan fuerte. ¡Intenta de nuevo!"
		btn_otra_vez.show()
	panel_final.show()

	if gano and not modo_libre:
		# Abierto desde el diálogo: se deja leer el resultado y se devuelve el control.
		await get_tree().create_timer(2.5).timeout
		juego_completado.emit()


func _otra_vez() -> void:
	panel_final.hide()
	lbl_chaac.text = ""
	_reiniciar_valores()
	_empezar_cuenta_atras()


func _salir() -> void:
	if modo_libre:
		SceneTransition.change_scene(ESCENA_MENU)
	else:
		juego_completado.emit()


# --- Dibujo ---

## Los dos antebrazos sobre la mesa, unidos por las manos. El ángulo sale de
## `posicion`: hacia la derecha va ganando Atlas (le dobla el brazo a Chaac).
func _dibujar_brazos() -> void:
	var tam := brazos.size
	var mesa := Rect2(0, tam.y - 26, tam.x, 26)
	brazos.draw_rect(mesa, Color(0.45, 0.3, 0.18))
	brazos.draw_rect(Rect2(0, tam.y - 26, tam.x, 5), Color(0.6, 0.42, 0.26))

	var codo_atlas := Vector2(tam.x * 0.3, tam.y - 26)
	var codo_chaac := Vector2(tam.x * 0.7, tam.y - 26)
	var angulo := posicion * deg_to_rad(55.0)
	var largo := tam.x * 0.24
	var manos := Vector2(tam.x / 2.0, tam.y - 26 - largo) \
		+ Vector2(sin(angulo), 1.0 - cos(angulo)) * largo
	brazos.draw_line(codo_atlas, manos, Color(0.9, 0.93, 0.97), 14.0)
	brazos.draw_line(codo_chaac, manos, Color(0.62, 0.4, 0.25), 14.0)
	brazos.draw_circle(manos, 11.0, Color(0.85, 0.75, 0.6))
	if desconcentrado > 0.0:
		brazos.draw_arc(manos, 18.0, 0.0, TAU, 24, Color(1, 0.9, 0.3, 0.8), 2.0)


## Barra de ventaja: se llena desde el centro hacia el lado de quien va ganando
## (Atlas empuja hacia Chaac, a la derecha; Chaac hacia Atlas, a la izquierda).
func _dibujar_barra() -> void:
	var tam := barra.size
	var mitad := tam.x / 2.0
	barra.draw_rect(Rect2(Vector2.ZERO, tam), Color(0.15, 0.15, 0.18))
	var x := mitad + posicion * mitad
	if posicion > 0.0:
		barra.draw_rect(Rect2(mitad, 0, x - mitad, tam.y), COLOR_ATLAS)
	elif posicion < 0.0:
		barra.draw_rect(Rect2(x, 0, mitad - x, tam.y), COLOR_CHAAC)
	barra.draw_rect(Rect2(mitad - 1, 0, 2, tam.y), Color(1, 1, 1, 0.5))
	barra.draw_rect(Rect2(Vector2.ZERO, tam), Color(0, 0, 0, 0.8), false, 2.0)
	barra.draw_rect(Rect2(x - 3, -4, 6, tam.y + 8), Color.WHITE)
