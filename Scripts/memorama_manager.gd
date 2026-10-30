extends Node2D

## Contrato de minijuegos (ver dialogo_manager.gd): hoy solo se abre desde el
## Libro de Historia, pero así también se puede lanzar desde un diálogo.
signal juego_completado
var nivel_a_cargar: String = ""

const ESCENA_LIBRO := "res://Scenes/LibroHistoria.tscn"
const TEMA_BOTON := preload("res://Themes/boton_menu.tres")
## Segundos que se ve "¡Ganaste!" antes de volver al diálogo (fuera del libro).
const ESPERA_VICTORIA := 2.0

@onready var grid = $GridContainer
@onready var btn_salir: Button = get_node_or_null("BtnSalir")
var carta_scene = preload("res://Scenes/Carta.tscn")

var pairs_to_play = 5 # Total de parejas en el tablero (12 cartas en total)
var first_card = null
var second_card = null
var can_click = true
var matched_pairs = 0

## true cuando se entró desde el Libro de Historia (esta escena ES la escena
## actual) y false cuando alguien la instanció encima de otra cosa.
var modo_libre: bool = false

func _ready():
	modo_libre = (get_parent() == get_tree().root)

	# Salida propia de vuelta al libro. El MenuPausa que trae la escena sí deja
	# salir, pero al menú principal: desde el libro eso saca al jugador de donde
	# estaba en vez de devolverlo.
	if btn_salir:
		btn_salir.visible = modo_libre
		if modo_libre:
			btn_salir.pressed.connect(_salir)

	load_and_setup_game()


func _salir() -> void:
	SceneTransition.change_scene(ESCENA_LIBRO)

func load_and_setup_game():
	var file = FileAccess.open("res://memorama_data.json", FileAccess.READ)
	if not file:
		print("Error: No se encontró el archivo memorama_data.json")
		return
		
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var error = json.parse(json_string)
	if error != OK:
		print("Error al parsear el JSON de memorama")
		return
		
	var data_array = json.data
	data_array.shuffle() # Revuelve el banco de datos disponible
	
	# Limitamos al máximo de parejas disponibles en JSON si hay menos de 6
	var actual_pairs_to_play = min(pairs_to_play, data_array.size())
	pairs_to_play = actual_pairs_to_play
	
	var selected_pairs = data_array.slice(0, actual_pairs_to_play)
	var cards_data = []
	
	# Generamos las cartas correspondientes para cada pareja
	for pair in selected_pairs:
		cards_data.append({"id": pair.id, "type": pair.tipo_a, "value": pair.valor_a})
		cards_data.append({"id": pair.id, "type": pair.tipo_b, "value": pair.valor_b})
		
	cards_data.shuffle() # Revuelve cómo se colocarán las cartas en la cuadrícula
	
	# Instancia las cartas en el grid
	for c_data in cards_data:
		var carta = carta_scene.instantiate()
		grid.add_child(carta)
		carta.setup(c_data.id, c_data.type, c_data.value)
		carta.connect("card_flipped", Callable(self, "_on_card_flipped"))

func _on_card_flipped(card):
	if not can_click:
		return
		
	card.flip_card()
	
	if first_card == null:
		first_card = card
	elif second_card == null and card != first_card:
		second_card = card
		can_click = false
		check_match()

func check_match():
	# Damos un segundo para ver la segunda carta antes de actuar
	await get_tree().create_timer(1.0).timeout
	
	if first_card.id == second_card.id:
		# ¡Acertaste!
		first_card.match_found()
		second_card.match_found()
		matched_pairs += 1
		
		if matched_pairs == pairs_to_play:
			first_card = null
			second_card = null
			_ganar()
			return
	else:
		# Fallaste, las voltea boca abajo
		first_card.flip_card()
		second_card.flip_card()
		
	first_card = null
	second_card = null
	can_click = true


var _pantalla_victoria: Array[Node] = []

## Todas las parejas encontradas: velo con "¡Ganaste!". Desde el libro se puede
## volver a jugar (o salir con el botón de siempre); desde un diálogo, avisa y se cierra.
func _ganar() -> void:
	can_click = false

	var velo := ColorRect.new()
	velo.color = Color(0, 0, 0, 0.55)
	velo.size = Vector2(640, 360)
	velo.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(velo)

	var caja := VBoxContainer.new()
	caja.position = Vector2(140, 120)
	caja.size = Vector2(360, 120)
	caja.alignment = BoxContainer.ALIGNMENT_CENTER
	caja.add_theme_constant_override("separation", 14)
	add_child(caja)

	var titulo := Label.new()
	titulo.text = "¡Ganaste!\nEncontraste todas las parejas."
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.add_theme_font_size_override("font_size", 20)
	titulo.add_theme_color_override("font_color", Color(0.98, 0.83, 0.34))
	titulo.add_theme_color_override("font_outline_color", Color(0.24, 0.15, 0.14))
	titulo.add_theme_constant_override("outline_size", 6)
	caja.add_child(titulo)

	# El velo va antes del botón Salir en el árbol para no taparlo (trampa 6).
	if btn_salir:
		move_child(velo, btn_salir.get_index())
		move_child(caja, btn_salir.get_index())
	_pantalla_victoria = [velo, caja]

	if modo_libre:
		var btn_otra := Button.new()
		btn_otra.theme = TEMA_BOTON
		btn_otra.text = "Jugar otra vez"
		btn_otra.custom_minimum_size = Vector2(160, 36)
		btn_otra.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		btn_otra.pressed.connect(_reiniciar)
		caja.add_child(btn_otra)
	else:
		await get_tree().create_timer(ESPERA_VICTORIA).timeout
		if is_inside_tree():
			juego_completado.emit()


func _reiniciar() -> void:
	for nodo in _pantalla_victoria:
		nodo.queue_free()
	_pantalla_victoria.clear()
	for carta in grid.get_children():
		carta.queue_free()
	matched_pairs = 0
	pairs_to_play = 5
	first_card = null
	second_card = null
	can_click = true
	load_and_setup_game()
