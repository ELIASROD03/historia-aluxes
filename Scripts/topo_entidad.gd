extends Area2D

signal topo_aplastado(es_kaan: bool)

var es_kaan: bool = true
var subiendo: bool = true

var sprite: Sprite2D
var tiempo_vida: Timer
var collision: CollisionShape2D

# Audios listos para cuando se agreguen sonidos
var audio_hit: AudioStreamPlayer

func _init():
	# Nos aseguramos de que el área pueda recibir clics
	input_pickable = true

func _ready():
	# 1. Crear el Sprite
	sprite = Sprite2D.new()
	var ruta_tex = "res://Images/Personajes/Kaan/kaan.png" if es_kaan else "res://Images/Personajes/Kaan/Kaan_Señuelo.png"
	sprite.texture = load(ruta_tex)
	# Si la imagen es un spritesheet, puedes ajustar hframes y vframes aquí
	# sprite.hframes = 4 
	add_child(sprite)
	
	# 2. Crear la Colisión
	collision = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	# Ajusta el tamaño de colisión según el tamaño de la imagen de Kaan
	rect.size = Vector2(50, 60) 
	collision.shape = rect
	add_child(collision)
	
	# 3. Preparar el nodo de Sonido
	audio_hit = AudioStreamPlayer.new()
	audio_hit.bus = "Efectos"
	add_child(audio_hit)
	
	# 4. Efecto de aparición (Tween)
	# Empieza invisible y escalado a 0
	modulate.a = 0.0
	scale = Vector2(0.5, 0.5)
	
	var tween_aparecer = create_tween().set_parallel(true)
	tween_aparecer.tween_property(self, "scale", Vector2(1, 1), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween_aparecer.tween_property(self, "modulate:a", 1.0, 0.2)
	
	# 5. Temporizador para desaparecer automáticamente si no se clickea
	tiempo_vida = Timer.new()
	# Los señuelos desaparecen más rápido o igual, puedes ajustarlo
	tiempo_vida.wait_time = randf_range(1.0, 1.5)
	tiempo_vida.one_shot = true
	tiempo_vida.timeout.connect(desaparecer)
	add_child(tiempo_vida)
	tiempo_vida.start()

func _input_event(_viewport, event, _shape_idx):
	# Detectar clic izquierdo sobre el topo
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if subiendo:
			recibir_golpe()

func recibir_golpe():
	subiendo = false
	tiempo_vida.stop()
	
	# Emitir señal al manager
	topo_aplastado.emit(es_kaan)
	
	# -- Efecto Visual de Golpe (Godot 4 Tweens) --
	# 1. Aplastar el sprite en Y, ensancharlo en X y cambiar a rojo/blanco
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.5, 0.2), 0.15).set_trans(Tween.TRANS_BOUNCE)
	tween.tween_property(self, "modulate", Color(1, 0, 0, 0), 0.2) # Se vuelve rojo y se desvanece
	
	# Puedes añadir un sonido aquí cuando tengas el archivo:
	# audio_hit.stream = preload("res://ruta/al/sonido_golpe.wav")
	# audio_hit.play()
	
	# Al terminar el efecto, destruimos el nodo
	tween.chain().tween_callback(queue_free)

func desaparecer():
	if not subiendo:
		return
	subiendo = false
	
	# Efecto de ocultarse hacia abajo
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "scale", Vector2(0.5, 0.5), 0.2)
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	tween.chain().tween_callback(queue_free)
