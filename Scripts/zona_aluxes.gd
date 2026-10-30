class_name ZonaAluxes
extends CanvasLayer
## La "zona de resguardo": la dimensión de bolsillo donde Atlas guarda a los
## aluxes atrapados (en vez de una celda con rejas). Se ve a través de la
## computadora del laboratorio, como si fuera la transmisión de una cámara.
##
## Quién está adentro depende del progreso (ver aluxes_en_zona()):
##   caps 3-4 → Kaan (atrapado al final del cap 2)
##   caps 5-6 → Kaan y Chaac (Chaac llega al final del cap 4)
##   historia terminada → vacía: ya viven en su casita del bosque.
## Mientras está abierta congela al jugador con Global.en_dialogo.

signal cerrada

const TEX_FONDO := preload("res://Images/Fondos/zona_aluxes/fondo.png")
const TEX_ANILLO := preload("res://Images/Fondos/zona_aluxes/anillo.png")
const FUENTE := preload("res://fonts/Amaranth-Bold.ttf")
const TEMA_BOTON := preload("res://Themes/boton_menu.tres")

## Centro del anillo de glifos dentro de fondo.png (de ahí se recortó anillo.png).
const CENTRO_ANILLO := Vector2(341.67, 185.56)

## nombre -> [hoja de animación, cuadros, cuadros por segundo, color del aura, escala]
## La escala iguala su altura en pantalla (~90 px): el dibujo de Kaan mide 47 px
## de su cuadro de 64 y el de Chaac llena los 64, como en los niveles (40 px ambos).
const ALUXES := {
	"Kaan": ["res://Images/Personajes/Kaan/Kaan_Idle.png", 9, 8.0, Color(0.35, 1.0, 0.55), 1.9],
	"Chaac": ["res://Images/Personajes/chaac/chaac_respirando.png", 4, 5.0, Color(1.0, 0.45, 0.35), 1.4],
}

const MARCO := Rect2(12, 10, 616, 340)
const PANTALLA := Rect2(24, 22, 592, 280)

var _pantalla: Control
var _en_vivo: Label
var _anillo: Sprite2D
var _flotantes: Array = [] # [{sprite, aura, base, fase, cuadros, fps}]
var _t := 0.0
var _puede_cerrar := false
var _cerrando := false


## Aluxes que están en la zona según el avance de la partida.
static func aluxes_en_zona() -> Array:
	if Global.juego_terminado():
		return []
	var p := Global.progreso_historia
	var lista := []
	if p >= 3:
		lista.append("Kaan")
	if p >= 5:
		lista.append("Chaac")
	return lista


func _ready() -> void:
	layer = 50
	Global.en_dialogo = true
	_construir()
	_encender()


func _construir() -> void:
	var negro := ColorRect.new()
	negro.color = Color(0, 0, 0, 0.9)
	negro.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(negro)

	# Carcasa del monitor
	var marco := Panel.new()
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0.17, 0.18, 0.2)
	estilo.border_color = Color(0.07, 0.07, 0.08)
	estilo.set_border_width_all(3)
	estilo.set_corner_radius_all(10)
	marco.add_theme_stylebox_override("panel", estilo)
	marco.position = MARCO.position
	marco.size = MARCO.size
	add_child(marco)

	# Pantalla: todo lo de adentro se recorta a su rectángulo
	_pantalla = Control.new()
	_pantalla.position = PANTALLA.position
	_pantalla.size = PANTALLA.size
	_pantalla.pivot_offset = PANTALLA.size / 2.0
	_pantalla.clip_contents = true
	add_child(_pantalla)

	var escala: float = max(PANTALLA.size.x / TEX_FONDO.get_width(), PANTALLA.size.y / TEX_FONDO.get_height())
	var mundo := Node2D.new()
	mundo.scale = Vector2(escala, escala)
	mundo.position = (PANTALLA.size - Vector2(TEX_FONDO.get_size()) * escala) / 2.0
	_pantalla.add_child(mundo)

	var fondo := Sprite2D.new()
	fondo.texture = TEX_FONDO
	fondo.centered = false
	mundo.add_child(fondo)

	# Una copia de los glifos gira despacio encima del anillo pintado
	_anillo = Sprite2D.new()
	_anillo.texture = TEX_ANILLO
	_anillo.position = CENTRO_ANILLO
	_anillo.modulate = Color(1, 1, 1, 0.45)
	_anillo.material = _material_suma()
	mundo.add_child(_anillo)

	var nombres := aluxes_en_zona()
	for i in nombres.size():
		var separacion := 70.0
		var x := (i - (nombres.size() - 1) / 2.0) * separacion * 2.0
		_agregar_alux(mundo, nombres[i], CENTRO_ANILLO + Vector2(x, 0), i * 1.7)

	_pantalla.add_child(_lineas_de_barrido())

	_en_vivo = _etiqueta("● EN VIVO", 10, Color(1, 0.3, 0.3))
	_en_vivo.position = Vector2(8, 4)
	_pantalla.add_child(_en_vivo)
	var titulo := _etiqueta("ZONA DE RESGUARDO · LAB. PÉREZ", 10, Color(0.6, 1, 0.95, 0.85))
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	titulo.position = Vector2(8, 4)
	titulo.size = Vector2(PANTALLA.size.x - 16, 16)
	_pantalla.add_child(titulo)

	# Abajo, en la carcasa: qué se ve y el botón para salir
	var estado := _etiqueta(_texto_estado(nombres), 13, Color(0.75, 0.95, 1))
	estado.position = Vector2(PANTALLA.position.x + 4, PANTALLA.end.y + 14)
	add_child(estado)

	var salir := Button.new()
	salir.text = "Salir"
	salir.theme = TEMA_BOTON
	salir.add_theme_font_size_override("font_size", 18)
	salir.custom_minimum_size = Vector2(120, 40)
	salir.size = Vector2(120, 40)
	salir.position = Vector2(PANTALLA.end.x - 120, PANTALLA.end.y + 6)
	salir.pressed.connect(cerrar)
	add_child(salir)


func _agregar_alux(mundo: Node2D, nombre: String, pos: Vector2, fase: float) -> void:
	var datos: Array = ALUXES[nombre]
	var color: Color = datos[3]

	var aura := Sprite2D.new()
	aura.texture = _textura_aura()
	aura.modulate = Color(color, 0.55)
	aura.material = _material_suma()
	aura.position = pos
	mundo.add_child(aura)

	var sprite := Sprite2D.new()
	sprite.texture = load(datos[0])
	sprite.hframes = datos[1]
	sprite.scale = Vector2.ONE * float(datos[4])
	# Tinte fantasmal: se ve un poco translúcido y azulado, como en otra dimensión
	sprite.modulate = Color(0.85, 1.0, 1.0, 0.92)
	sprite.position = pos
	mundo.add_child(sprite)

	var etiqueta := _etiqueta(nombre, 14, color.lightened(0.4))
	etiqueta.position = pos + Vector2(-etiqueta.get_minimum_size().x / 2.0, 62)
	mundo.add_child(etiqueta)

	_flotantes.append({"sprite": sprite, "aura": aura, "base": pos, "fase": fase,
		"cuadros": int(datos[1]), "fps": float(datos[2])})


func _texto_estado(nombres: Array) -> String:
	if Global.juego_terminado():
		return "Vacía. Los aluxes ya viven libres en su casita del bosque."
	if nombres.is_empty():
		return "Vacía. Aquí traeremos a los aluxes que atrapemos."
	if Global.progreso_historia >= 6 and Global.eventos_completados.get("laboratorio_cap6", false):
		return "Kaan y Chaac descansan: le dieron su poder a la máquina."
	if nombres.size() == 1:
		return "Kaan flota tranquilo con su biberón de atole."
	return "Kaan y Chaac flotan juntos (y comen elote)."


func _process(delta: float) -> void:
	_t += delta
	_anillo.rotation += delta * 0.08
	_en_vivo.visible = fmod(_t, 1.2) < 0.8
	for f in _flotantes:
		var fase: float = f.fase
		var sprite: Sprite2D = f.sprite
		var pos: Vector2 = f.base + Vector2(sin(_t * 0.7 + fase) * 4.0, sin(_t * 1.6 + fase) * 6.0)
		sprite.position = pos
		sprite.rotation = sin(_t * 0.9 + fase) * 0.07
		sprite.frame = int(_t * f.fps) % int(f.cuadros)
		var aura: Sprite2D = f.aura
		aura.position = pos
		aura.scale = Vector2.ONE * (1.0 + sin(_t * 2.0 + fase) * 0.08)


func _unhandled_input(event: InputEvent) -> void:
	if _puede_cerrar and (event.is_action_pressed("ui_cancel") or event.is_action_pressed("ui_accept")):
		get_viewport().set_input_as_handled()
		cerrar()


## Se prende como tele vieja: una línea que se abre hacia arriba y abajo.
func _encender() -> void:
	_pantalla.scale = Vector2(1, 0.02)
	_pantalla.modulate = Color(3, 3, 3)
	var t := create_tween()
	t.tween_property(_pantalla, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(_pantalla, "modulate", Color.WHITE, 0.4)
	# El mismo Enter que abrió la zona no debe cerrarla
	t.tween_callback(func(): _puede_cerrar = true)


func cerrar() -> void:
	if _cerrando:
		return
	_cerrando = true
	var t := create_tween()
	t.tween_property(_pantalla, "modulate", Color(3, 3, 3), 0.1)
	t.tween_property(_pantalla, "scale", Vector2(1, 0.02), 0.15)
	await t.finished
	Global.en_dialogo = false
	cerrada.emit()
	queue_free()


func _etiqueta(texto: String, tam: int, color: Color) -> Label:
	var l := Label.new()
	l.text = texto
	l.add_theme_font_override("font", FUENTE)
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	l.add_theme_constant_override("outline_size", 3)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _lineas_de_barrido() -> Control:
	var c := Control.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.size = PANTALLA.size
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.draw.connect(func():
		for y in range(0, int(PANTALLA.size.y), 3):
			c.draw_line(Vector2(0, y), Vector2(PANTALLA.size.x, y), Color(0, 0, 0, 0.16)))
	return c


static func _material_suma() -> CanvasItemMaterial:
	var m := CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	return m


static func _textura_aura() -> GradientTexture2D:
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 0.8))
	g.set_color(1, Color(1, 1, 1, 0))
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(0.5, 0.0)
	tex.width = 96
	tex.height = 96
	return tex
