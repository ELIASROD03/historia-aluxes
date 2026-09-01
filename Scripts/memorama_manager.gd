extends Node2D

const ESCENA_LIBRO := "res://Scenes/LibroHistoria.tscn"

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
			print("¡Ganaste el memorama!")
			# Aquí puedes lanzar victoria, diálogo o volver al menú
	else:
		# Fallaste, las voltea boca abajo
		first_card.flip_card()
		second_card.flip_card()
		
	first_card = null
	second_card = null
	can_click = true
