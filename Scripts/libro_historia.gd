extends Control
## El Libro de Historia: la enciclopedia del juego. Dos pestañas sobre las
## páginas del libro:
##   Minijuegos — los de la historia, con candado hasta conocerlos en un capítulo
##                (Memorama siempre abierto). Palabras y Rompecabezas cuentan
##                cuántos de sus niveles lleva el jugador.
##   Capítulos  — recuadros grises con candado; al terminar un capítulo se abre su
##                resumen y sus personajes, con el mismo sprite que en el nivel.
## Lo desbloqueado vive en LibroProgreso (del dispositivo, no de la partida) y el
## contenido en libro_historia.json.

const RUTA_CONTENIDO := "res://libro_historia.json"
const FUENTE := preload("res://fonts/Amaranth-Bold.ttf")
const TEX_CANDADO := preload("res://assets/libro/candado.png")
const TEX_FLECHA := preload("res://assets/libro/flecha.png")

const CAFE := Color(0.243, 0.153, 0.137)
const CAFE_SUAVE := Color(0.243, 0.153, 0.137, 0.75)
const PERGAMINO := Color(0.93, 0.86, 0.7)
const GRIS := Color(0.55, 0.53, 0.5)
const DORADO := Color(0.85, 0.62, 0.18)

## Las dos páginas del dibujo libroHistoria.png (640x360), antes del zoom de entrada.
const PAG_IZQ := Rect2(128, 42, 170, 218)
const PAG_DER := Rect2(334, 42, 168, 218)
## El libro se agranda hasta casi llenar la pantalla: las páginas (y=30..275 del
## dibujo) quedan de y≈9 a y≈352.
const ZOOM := 1.4
const PIVOTE := Vector2(320, 152)
const DESPLAZAMIENTO := Vector2(0, 28)

const TAM_TITULO := 13
const TAM_TEXTO := 10
const TAM_NOMBRE := 11
const TAM_DESCRIPCION := 9
## Espacio al pie de la página derecha para las flechas de pasar hoja.
const ALTO_NAVEGACION := 20.0
const SEPARACION := 4.0
const LADO_SPRITE := 44.0
## Label deja estos pixeles entre renglones (constante line_spacing del tema).
const ENTRE_RENGLONES := 3.0

## Lo último que se veía, para volver ahí al regresar de un minijuego.
static var _pestana := "minijuegos"
static var _seleccion := {"minijuegos": "", "capitulos": ""}

@onready var texture_rect = $TextureRect

var _contenido: Dictionary = {}
var _paginas: Control
var _izq: VBoxContainer
var _der: Control
var _btn_minijuegos: Button
var _btn_capitulos: Button
## Sprites animados de la página derecha: [{rect, atlas, cuadros, ancho, alto, hframes}]
var _animados: Array = []
var _t := 0.0
## Hojas del capítulo abierto (cada una, una lista de piezas) y la que se ve.
var _hojas: Array = []
var _hoja := 0
var _pasando_hoja := false


func _ready():
	# Buscamos el botón sin importar en qué parte de la escena lo hayas puesto
	var btn = find_child("exit_book_btn", true, false)
	if btn:
		btn.pressed.connect(_on_exit_book_btn_pressed)

	var texto := FileAccess.get_file_as_string(RUTA_CONTENIDO)
	var datos = JSON.parse_string(texto)
	if typeof(datos) == TYPE_DICTIONARY:
		_contenido = datos
	else:
		push_error("No se pudo leer %s." % RUTA_CONTENIDO)

	_construir_paginas()
	if btn:
		move_child(btn, get_child_count() - 1)
	_mostrar_pestana(_pestana)

	# Efecto de zoom: el libro y lo escrito en él crecen juntos
	for nodo in [texture_rect, _paginas]:
		nodo.pivot_offset = PIVOTE
		nodo.position = DESPLAZAMIENTO
		nodo.scale = Vector2(0.5, 0.5)
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_BACK)
		tween.set_ease(Tween.EASE_OUT)
		tween.tween_property(nodo, "scale", Vector2(ZOOM, ZOOM), 0.7)


func _process(delta: float) -> void:
	_t += delta
	for a in _animados:
		if not is_instance_valid(a.rect):
			continue
		var cuadro := int(_t * 5.0) % int(a.cuadros)
		var atlas: AtlasTexture = a.atlas
		var usado: Rect2 = a.usado
		atlas.region = Rect2(usado.position + Vector2((cuadro % a.hframes) * a.ancho, (cuadro / a.hframes) * a.alto), usado.size)


func _on_exit_book_btn_pressed():
	get_tree().change_scene_to_file("res://Scenes/MenuPrincipal.tscn")

func _input(event):
	# Opcional: También te deja regresar presionando la tecla Esc
	if event.is_action_pressed("ui_cancel"):
		get_tree().change_scene_to_file("res://Scenes/MenuPrincipal.tscn")


# -- Armado -------------------------------------------------------------------

func _construir_paginas() -> void:
	_paginas = Control.new()
	_paginas.set_anchors_preset(Control.PRESET_FULL_RECT)
	_paginas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_paginas)

	var pestanas := HBoxContainer.new()
	pestanas.position = PAG_IZQ.position
	pestanas.size = Vector2(PAG_IZQ.size.x, 18)
	pestanas.add_theme_constant_override("separation", 4)
	_paginas.add_child(pestanas)
	_btn_minijuegos = _boton_pestana("Minijuegos", "minijuegos")
	_btn_capitulos = _boton_pestana("Capítulos", "capitulos")
	pestanas.add_child(_btn_minijuegos)
	pestanas.add_child(_btn_capitulos)

	_izq = VBoxContainer.new()
	_izq.position = PAG_IZQ.position + Vector2(0, 24)
	_izq.size = PAG_IZQ.size - Vector2(0, 24)
	_izq.add_theme_constant_override("separation", 4)
	_paginas.add_child(_izq)

	_der = Control.new()
	_der.position = PAG_DER.position
	_der.size = PAG_DER.size
	_paginas.add_child(_der)


func _boton_pestana(texto: String, pestana: String) -> Button:
	var b := Button.new()
	b.text = texto
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_override("font", FUENTE)
	b.add_theme_font_size_override("font_size", TAM_NOMBRE)
	b.pressed.connect(_mostrar_pestana.bind(pestana))
	return b


func _mostrar_pestana(pestana: String) -> void:
	_pestana = pestana
	for par in [[_btn_minijuegos, "minijuegos"], [_btn_capitulos, "capitulos"]]:
		var activa: bool = par[1] == pestana
		var b: Button = par[0]
		var color := CAFE if activa else Color(0, 0, 0, 0)
		for estado in ["normal", "hover", "pressed", "focus"]:
			b.add_theme_stylebox_override(estado, _caja(color, CAFE, 1, 3))
		for estado in ["font_color", "font_hover_color", "font_pressed_color"]:
			b.add_theme_color_override(estado, PERGAMINO if activa else CAFE)
	_vaciar(_izq)
	if pestana == "minijuegos":
		_llenar_minijuegos()
	else:
		_llenar_capitulos()


# -- Minijuegos ---------------------------------------------------------------

func _llenar_minijuegos() -> void:
	var lista: Array = _contenido.get("minijuegos", [])
	var elegido := str(_seleccion.minijuegos)
	if elegido == "" and not lista.is_empty():
		elegido = str(lista[0].get("id", ""))
	for mj in lista:
		var abierto := _minijuego_abierto(mj)
		var sub := _progreso_minijuego(mj) if abierto else "Bloqueado"
		var b := _boton_ficha("%s\n%s" % [mj.get("nombre", ""), sub], abierto, str(mj.get("id")) == elegido)
		b.custom_minimum_size = Vector2(PAG_IZQ.size.x, 32)
		b.pressed.connect(_elegir_minijuego.bind(str(mj.get("id"))))
		_izq.add_child(b)
	_mostrar_minijuego(elegido)


func _elegir_minijuego(id: String) -> void:
	_seleccion.minijuegos = id
	_mostrar_pestana("minijuegos")


func _minijuego(id: String) -> Dictionary:
	for mj in _contenido.get("minijuegos", []):
		if str(mj.get("id")) == id:
			return mj
	return {}


func _minijuego_abierto(mj: Dictionary) -> bool:
	if mj.get("siempre", false):
		return true
	match str(mj.get("contador", "")):
		"palabras":
			return _contar("palabras_nivel_", 1) > 0
		"rompecabezas":
			return _contar("rompecabezas_nivel_", 1) > 0
	return LibroProgreso.esta_desbloqueado(str(mj.get("clave", "")))


## Lo desbloqueado con ese prefijo; en modo desarrollador, todo (`total`).
func _contar(prefijo: String, total: int) -> int:
	return total if LibroProgreso.todo_abierto() else LibroProgreso.contar(prefijo)


## "3/30 textos", "2/6 niveles" o "Disponible".
func _progreso_minijuego(mj: Dictionary) -> String:
	match str(mj.get("contador", "")):
		"palabras":
			var total := _total_palabras()
			return "%d/%d textos" % [_contar("palabras_nivel_", total), total]
		"rompecabezas":
			var total := Global.total_capitulos()
			return "%d/%d niveles" % [_contar("rompecabezas_nivel_", total), total]
	return "Disponible"


## Textos "nivel_<cap>_<n>" de palabras.json (los que puede lanzar el soldado).
func _total_palabras() -> int:
	var datos = JSON.parse_string(FileAccess.get_file_as_string("res://palabras.json"))
	if typeof(datos) != TYPE_DICTIONARY:
		return 0
	var n := 0
	for clave in datos.keys():
		var partes: PackedStringArray = str(clave).split("_")
		if partes.size() == 3 and partes[0] == "nivel" and partes[1].is_valid_int():
			n += 1
	return n


func _mostrar_minijuego(id: String) -> void:
	_vaciar(_der)
	var mj := _minijuego(id)
	if mj.is_empty():
		return
	var abierto := _minijuego_abierto(mj)
	var caja := _columna_derecha()

	caja.add_child(_titulo_con_candado(str(mj.get("nombre", "")), not abierto))
	caja.add_child(_parrafo(str(mj.get("descripcion", "")), TAM_TEXTO))
	if abierto:
		if not mj.get("siempre", false):
			caja.add_child(_etiqueta(_progreso_minijuego(mj), TAM_NOMBRE, DORADO.darkened(0.2)))
		var jugar := Button.new()
		jugar.text = "Jugar"
		jugar.focus_mode = Control.FOCUS_NONE
		jugar.custom_minimum_size = Vector2(80, 22)
		jugar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		jugar.add_theme_font_override("font", FUENTE)
		jugar.add_theme_font_size_override("font_size", 12)
		for estado in ["normal", "focus"]:
			jugar.add_theme_stylebox_override(estado, _caja(CAFE, CAFE, 1, 4))
		jugar.add_theme_stylebox_override("hover", _caja(CAFE.lightened(0.15), CAFE, 1, 4))
		jugar.add_theme_stylebox_override("pressed", _caja(CAFE.darkened(0.2), CAFE, 1, 4))
		jugar.add_theme_color_override("font_color", PERGAMINO)
		jugar.add_theme_color_override("font_hover_color", Color.WHITE)
		jugar.pressed.connect(_jugar.bind(str(mj.get("escena", ""))))
		caja.add_child(jugar)
	else:
		caja.add_child(_etiqueta("Cómo desbloquearlo:", TAM_NOMBRE, CAFE))
		caja.add_child(_parrafo(str(mj.get("como_desbloquear", "")), TAM_TEXTO))


func _jugar(escena: String) -> void:
	if ResourceLoader.exists(escena):
		get_tree().change_scene_to_file(escena)
	else:
		push_error("El minijuego '%s' no existe." % escena)


# -- Capítulos ----------------------------------------------------------------

func _llenar_capitulos() -> void:
	var rejilla := GridContainer.new()
	rejilla.columns = 2
	rejilla.add_theme_constant_override("h_separation", 6)
	rejilla.add_theme_constant_override("v_separation", 6)
	_izq.add_child(rejilla)

	var elegido := str(_seleccion.capitulos)
	if elegido == "":
		elegido = "1"
	for n in range(1, Global.total_capitulos() + 1):
		var cap: Dictionary = Global.obtener_capitulo(n)
		var abierto := LibroProgreso.esta_desbloqueado("capitulo_%d" % n)
		var texto := "Capítulo %d\n%s" % [n, str(cap.get("anio", ""))] if abierto else "Capítulo %d" % n
		var b := _boton_ficha(texto, abierto, str(n) == elegido)
		b.custom_minimum_size = Vector2((PAG_IZQ.size.x - 6) / 2.0, 56)
		b.pressed.connect(_elegir_capitulo.bind(str(n)))
		rejilla.add_child(b)
	_mostrar_capitulo(elegido)


func _elegir_capitulo(n: String) -> void:
	_seleccion.capitulos = n
	_mostrar_pestana("capitulos")


func _mostrar_capitulo(n: String) -> void:
	_vaciar(_der)
	var cap: Dictionary = Global.obtener_capitulo(int(n))
	var abierto := LibroProgreso.esta_desbloqueado("capitulo_%s" % n)

	if not abierto:
		var caja := _columna_derecha()
		caja.add_child(_titulo_con_candado("Capítulo %s" % n, true))
		caja.add_child(_parrafo("Termina este capítulo para leer su historia y conocer a sus personajes.", TAM_TEXTO))
		return

	# Abierto: el resumen y los personajes no caben en una página, así que se
	# reparten en hojas que se pasan con las flechas de abajo.
	_hojas = _repartir_en_hojas(n, cap)
	_hoja = 0
	_pintar_hoja()


# -- Hojas del capítulo -------------------------------------------------------

## Reparte el capítulo en hojas que caben en la página derecha. Las piezas son
## {tipo: titulo|parrafo|encabezado|personaje}. El resumen se corta entre frases
## y un encabezado nunca se queda solo al final de una hoja.
func _repartir_en_hojas(n: String, cap: Dictionary) -> Array:
	var datos: Dictionary = _contenido.get("capitulos", {}).get(n, {})
	var libre := PAG_DER.size.y - ALTO_NAVEGACION
	var hojas: Array = [[]]
	var usado := 0.0

	var titulo := {"tipo": "titulo", "texto": str(cap.get("subtitulo", "Capítulo %s" % n))}
	hojas[-1].append(titulo)
	usado += _alto_pieza(titulo) + SEPARACION

	var parrafo := ""
	for frase in _frases(str(datos.get("resumen", ""))):
		var prueba: String = frase if parrafo == "" else parrafo + " " + frase
		if usado + _alto_pieza({"tipo": "parrafo", "texto": prueba}) <= libre:
			parrafo = prueba
			continue
		if parrafo != "":
			hojas[-1].append({"tipo": "parrafo", "texto": parrafo})
		hojas.append([])
		usado = 0.0
		parrafo = frase
	if parrafo != "":
		var pieza := {"tipo": "parrafo", "texto": parrafo}
		hojas[-1].append(pieza)
		usado += _alto_pieza(pieza) + SEPARACION

	# Grupos que no se separan: cada encabezado va con el primer personaje que le sigue
	var grupos: Array = []
	var personajes: Array = datos.get("personajes", [])
	for i in personajes.size():
		var grupo: Array = []
		if i == 0:
			grupo.append({"tipo": "encabezado", "texto": "Personajes importantes"})
		grupo.append({"tipo": "personaje", "datos": personajes[i]})
		grupos.append(grupo)
	var alux: Dictionary = _contenido.get("aluxes", {}).get(n, {})
	if not alux.is_empty():
		grupos.append([{"tipo": "encabezado", "texto": "El alux del capítulo"},
			{"tipo": "personaje", "datos": alux}])

	for grupo in grupos:
		var alto := 0.0
		for pieza in grupo:
			alto += _alto_pieza(pieza) + SEPARACION
		if usado + alto > libre and not hojas[-1].is_empty():
			hojas.append([])
			usado = 0.0
		hojas[-1].append_array(grupo)
		usado += alto
	return hojas


## "Hubo fiesta. Luego, batalla." → ["Hubo fiesta.", "Luego, batalla."]
func _frases(texto: String) -> Array:
	var re := RegEx.create_from_string("[^.!?]+[.!?]+[\"”»]?")
	var frases: Array = []
	for m in re.search_all(texto):
		frases.append(m.get_string().strip_edges())
	if frases.is_empty() and texto.strip_edges() != "":
		frases.append(texto.strip_edges())
	return frases


func _alto_pieza(pieza: Dictionary) -> float:
	var ancho := PAG_DER.size.x
	match str(pieza.tipo):
		"titulo":
			return _alto_texto(pieza.texto, TAM_TITULO, ancho)
		"parrafo":
			return _alto_texto(pieza.texto, TAM_TEXTO, ancho)
		"encabezado":
			return _alto_texto(pieza.texto, TAM_NOMBRE, ancho)
		"personaje":
			var p: Dictionary = pieza.datos
			var ancho_texto := ancho - LADO_SPRITE - SEPARACION
			return max(LADO_SPRITE, _alto_texto(str(p.get("nombre", "")), TAM_NOMBRE, ancho_texto)
				+ _alto_texto(str(p.get("descripcion", "")), TAM_DESCRIPCION, ancho_texto))
	return 0.0


## Alto que ocupará un Label con autowrap de ese ancho.
func _alto_texto(texto: String, tam: int, ancho: float) -> float:
	var alto_renglon := FUENTE.get_height(tam)
	var medida := FUENTE.get_multiline_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, ancho, tam)
	var renglones: int = max(1, roundi(medida.y / alto_renglon))
	return renglones * (alto_renglon + ENTRE_RENGLONES)


func _pintar_hoja() -> void:
	_vaciar(_der)
	var caja := VBoxContainer.new()
	caja.set_anchors_preset(Control.PRESET_FULL_RECT)
	caja.offset_bottom = -ALTO_NAVEGACION
	caja.add_theme_constant_override("separation", int(SEPARACION))
	_der.add_child(caja)
	for pieza in _hojas[_hoja]:
		match str(pieza.tipo):
			"titulo":
				caja.add_child(_etiqueta(pieza.texto, TAM_TITULO, CAFE))
			"parrafo":
				caja.add_child(_parrafo(pieza.texto, TAM_TEXTO))
			"encabezado":
				caja.add_child(_etiqueta(pieza.texto, TAM_NOMBRE, DORADO.darkened(0.25)))
			"personaje":
				caja.add_child(_fila_personaje(pieza.datos))
	_pintar_navegacion()


## Al pie de la página derecha: ← (si no es la primera hoja), "2/3" y →.
func _pintar_navegacion() -> void:
	if _hojas.size() <= 1:
		return
	var ancho := PAG_DER.size.x
	var pie := Control.new()
	pie.position = Vector2(0, PAG_DER.size.y - ALTO_NAVEGACION)
	pie.size = Vector2(ancho, ALTO_NAVEGACION)
	_der.add_child(pie)

	var numero := _etiqueta("%d/%d" % [_hoja + 1, _hojas.size()], TAM_DESCRIPCION, CAFE_SUAVE)
	numero.size = pie.size
	numero.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	numero.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pie.add_child(numero)

	if _hoja > 0:
		var atras := _boton_flecha(true)
		atras.position = Vector2(0, (ALTO_NAVEGACION - atras.size.y) / 2.0)
		atras.pressed.connect(_pasar_hoja.bind(-1))
		pie.add_child(atras)
	if _hoja < _hojas.size() - 1:
		var adelante := _boton_flecha(false)
		adelante.position = Vector2(ancho - adelante.size.x, (ALTO_NAVEGACION - adelante.size.y) / 2.0)
		adelante.pressed.connect(_pasar_hoja.bind(1))
		pie.add_child(adelante)


func _boton_flecha(hacia_atras: bool) -> TextureButton:
	var b := TextureButton.new()
	b.texture_normal = TEX_FLECHA
	b.flip_h = hacia_atras
	b.ignore_texture_size = true
	b.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	b.custom_minimum_size = Vector2(26, 20)
	b.size = b.custom_minimum_size
	b.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_entered.connect(func(): b.modulate = Color(1.25, 1.25, 1.25))
	b.mouse_exited.connect(func(): b.modulate = Color.WHITE)
	return b


## Como pasar la página de un libro: la hoja se cierra hacia el lomo y se abre la otra.
func _pasar_hoja(direccion: int) -> void:
	if _pasando_hoja:
		return
	var destino := clampi(_hoja + direccion, 0, _hojas.size() - 1)
	if destino == _hoja:
		return
	_pasando_hoja = true
	_der.pivot_offset = Vector2(0, PAG_DER.size.y / 2.0)  # el lomo está a la izquierda
	var t := create_tween()
	t.tween_property(_der, "scale:x", 0.0, 0.15).set_ease(Tween.EASE_IN)
	t.parallel().tween_property(_der, "modulate", Color(0.7, 0.65, 0.6), 0.15)
	await t.finished
	_hoja = destino
	_pintar_hoja()
	var t2 := create_tween()
	t2.tween_property(_der, "scale:x", 1.0, 0.18).set_ease(Tween.EASE_OUT)
	t2.parallel().tween_property(_der, "modulate", Color.WHITE, 0.18)
	await t2.finished
	_pasando_hoja = false


## Sprite de cuerpo completo (animado, como en el nivel) + nombre y descripción.
func _fila_personaje(p: Dictionary) -> Control:
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 4)

	var ruta := str(p.get("sprite", ""))
	if ResourceLoader.exists(ruta):
		var tex: Texture2D = load(ruta)
		var hframes := int(p.get("hframes", 0))
		var vframes := int(p.get("vframes", 1))
		if hframes <= 0:
			# Tira horizontal de cuadros cuadrados
			hframes = max(1, int(tex.get_width() / tex.get_height()))
		var ancho := tex.get_width() / float(hframes)
		var alto := tex.get_height() / float(vframes)
		var usado := _zona_dibujada(tex, hframes, vframes)
		var atlas := AtlasTexture.new()
		atlas.atlas = tex
		atlas.region = usado
		var rect := TextureRect.new()
		rect.texture = atlas
		rect.custom_minimum_size = Vector2(LADO_SPRITE, LADO_SPRITE)
		rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		fila.add_child(rect)
		_animados.append({"rect": rect, "atlas": atlas, "cuadros": hframes * vframes,
			"ancho": ancho, "alto": alto, "hframes": hframes, "usado": usado})

	var textos := VBoxContainer.new()
	textos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	textos.add_theme_constant_override("separation", 0)
	textos.add_child(_etiqueta(str(p.get("nombre", "")), TAM_NOMBRE, CAFE))
	textos.add_child(_parrafo(str(p.get("descripcion", "")), TAM_DESCRIPCION))
	fila.add_child(textos)
	return fila


## La parte dibujada del primer cuadro, sumando la de todos los cuadros (para que
## al animarse no se salga). Así los sprites con mucho aire alrededor no se ven
## diminutos junto a los demás.
func _zona_dibujada(tex: Texture2D, hframes: int, vframes: int) -> Rect2:
	var ancho := tex.get_width() / hframes
	var alto := tex.get_height() / vframes
	var img := tex.get_image()
	if img == null:
		return Rect2(0, 0, ancho, alto)
	if img.is_compressed():
		img.decompress()
	var union := Rect2i()
	for i in hframes * vframes:
		var origen := Vector2i((i % hframes) * ancho, (i / hframes) * alto)
		var usado := img.get_region(Rect2i(origen, Vector2i(ancho, alto))).get_used_rect()
		if usado.size == Vector2i.ZERO:
			continue
		union = usado if union.size == Vector2i.ZERO else union.merge(usado)
	if union.size == Vector2i.ZERO:
		return Rect2(0, 0, ancho, alto)
	return Rect2(union)


# -- Piezas -------------------------------------------------------------------

func _columna_derecha() -> VBoxContainer:
	var caja := VBoxContainer.new()
	caja.set_anchors_preset(Control.PRESET_FULL_RECT)
	caja.add_theme_constant_override("separation", 6)
	_der.add_child(caja)
	return caja


## Ficha de la página izquierda: pergamino oscuro si está abierta, gris con
## candado si no. La elegida lleva borde dorado.
func _boton_ficha(texto: String, abierto: bool, elegido: bool) -> Button:
	var b := Button.new()
	b.text = texto
	b.focus_mode = Control.FOCUS_NONE
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.add_theme_font_override("font", FUENTE)
	b.add_theme_font_size_override("font_size", TAM_TEXTO)
	b.add_theme_constant_override("line_spacing", -2)
	var fondo := Color(0.85, 0.72, 0.5) if abierto else GRIS
	var borde := DORADO if elegido else CAFE_SUAVE
	var grosor := 2 if elegido else 1
	b.add_theme_stylebox_override("normal", _caja(fondo, borde, grosor, 3))
	b.add_theme_stylebox_override("hover", _caja(fondo.lightened(0.1), DORADO, grosor, 3))
	b.add_theme_stylebox_override("pressed", _caja(fondo.darkened(0.1), DORADO, grosor, 3))
	for estado in ["font_color", "font_hover_color", "font_pressed_color"]:
		b.add_theme_color_override(estado, CAFE if abierto else Color(0.25, 0.24, 0.23))
	if not abierto:
		b.icon = TEX_CANDADO
		b.icon_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	return b


## Título de la página derecha; si está bloqueado lleva un candado a su lado.
func _titulo_con_candado(texto: String, bloqueado: bool) -> Control:
	var fila := HBoxContainer.new()
	var titulo := _etiqueta(texto, TAM_TITULO + 1, CAFE)
	titulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fila.add_child(titulo)
	if bloqueado:
		var r := TextureRect.new()
		r.texture = TEX_CANDADO
		r.custom_minimum_size = Vector2(16, 18)
		r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		r.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		fila.add_child(r)
	return fila


func _etiqueta(texto: String, tam: int, color: Color) -> Label:
	var l := Label.new()
	l.text = texto
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_override("font", FUENTE)
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", color)
	return l


func _parrafo(texto: String, tam: int) -> Label:
	var l := _etiqueta(texto, tam, CAFE_SUAVE.darkened(0.2))
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l


func _caja(fondo: Color, borde: Color, grosor: int, radio: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = fondo
	s.border_color = borde
	s.set_border_width_all(grosor)
	s.set_corner_radius_all(radio)
	s.content_margin_left = 6
	s.content_margin_right = 4
	s.content_margin_top = 2
	s.content_margin_bottom = 2
	return s


func _vaciar(nodo: Node) -> void:
	if nodo == _der:
		_animados.clear()
	for hijo in nodo.get_children():
		nodo.remove_child(hijo)
		hijo.queue_free()
