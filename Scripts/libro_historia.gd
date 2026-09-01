extends Control

@onready var texture_rect = $TextureRect

func _ready():
	# Buscamos el botón sin importar en qué parte de la escena lo hayas puesto
	var btn = find_child("exit_book_btn", true, false)
	if btn:
		btn.pressed.connect(_on_exit_book_btn_pressed)
		
	# Efecto de zoom
	if texture_rect:
		texture_rect.pivot_offset = Vector2(320, 180) # Asumiendo resolución 640x360
		texture_rect.scale = Vector2(0.5, 0.5)
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_BACK)
		tween.set_ease(Tween.EASE_OUT)
		# Escalarlo a 1.3 (un 30% más grande de lo normal)
		tween.tween_property(texture_rect, "scale", Vector2(1.2, 1.2), 0.7)

func _on_exit_book_btn_pressed():
	get_tree().change_scene_to_file("res://Scenes/MenuPrincipal.tscn")

func _input(event):
	# Opcional: También te deja regresar presionando la tecla Esc
	if event.is_action_pressed("ui_cancel"):
		get_tree().change_scene_to_file("res://Scenes/MenuPrincipal.tscn")

func _on_btn_palabras_pressed():
	get_tree().change_scene_to_file("res://Scenes/PalabrasImpostoras.tscn")

func _on_btn_memorama_pressed():
	get_tree().change_scene_to_file("res://Scenes/Memorama.tscn")

func _on_btn_atlas_bird_pressed():
	get_tree().change_scene_to_file("res://Scenes/Juegos/Atlas-Bird/Escenas/main-atlasbird.tscn")

func _on_btn_topo_alux_pressed():
	get_tree().change_scene_to_file("res://Scenes/Topo_Alux.tscn")

func _on_btn_rompecabezas_pressed():
	# El rompecabezas detecta solo que viene del libro (y no de un diálogo) y
	# muestra primero su selector de nivel, luego el de dificultad.
	get_tree().change_scene_to_file("res://Scenes/Rompecabezas.tscn")
