extends CanvasLayer

# Lado del dibujo de los botones (btn_*.png son de 64x64) y su separación de los
# bordes de la pantalla, medidos del acomodo original a escala 1.3.
const LADO_BOTON := 64.0
const MARGEN_IZQ := 16.0
const SEPARACION_FLECHAS := 28.8
const MARGEN_ABAJO_FLECHAS := 20.8
const MARGEN_DER_ACCION := 28.8
const MARGEN_ABAJO_ACCION := 12.8

@onready var btn_izq: TouchScreenButton = $Left
@onready var btn_der: TouchScreenButton = $Right
@onready var btn_accion: TouchScreenButton = $Action

func _ready() -> void:
	Configuracion.cambiada.connect(_aplicar_configuracion)
	_aplicar_configuracion()

func _process(_delta: float) -> void:
	var ocultos := Configuracion.modo_tactil == Configuracion.ModoTactil.OCULTOS
	visible = not Global.en_dialogo and not ocultos

func _aplicar_configuracion() -> void:
	var escala := Configuracion.tamano_tactil
	var lado := LADO_BOTON * escala
	var alto_pantalla := get_viewport().get_visible_rect().size.y
	var ancho_pantalla := get_viewport().get_visible_rect().size.x

	# Las flechas crecen desde la esquina inferior izquierda y la acción desde la
	# inferior derecha, para que agrandarlas nunca las saque de la pantalla.
	btn_izq.position = Vector2(MARGEN_IZQ, alto_pantalla - MARGEN_ABAJO_FLECHAS - lado)
	btn_der.position = Vector2(MARGEN_IZQ + lado + SEPARACION_FLECHAS, btn_izq.position.y)
	btn_accion.position = Vector2(ancho_pantalla - MARGEN_DER_ACCION - lado,
		alto_pantalla - MARGEN_ABAJO_ACCION - lado)

	var siempre := Configuracion.modo_tactil == Configuracion.ModoTactil.SIEMPRE
	for boton in [btn_izq, btn_der, btn_accion]:
		boton.scale = Vector2(escala, escala)
		boton.modulate.a = Configuracion.opacidad_tactil
		boton.visibility_mode = TouchScreenButton.VISIBILITY_ALWAYS if siempre \
			else TouchScreenButton.VISIBILITY_TOUCHSCREEN_ONLY
