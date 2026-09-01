extends Node2D

@export var velocidad: float = 40.0
@export var direccion: int = -1 # 1 para derecha, -1 para izquierda

var tiempo_animacion: float = 0.0
var fps_animacion: float = 12.0 # Velocidad de la animación (cuadros por segundo)

func _ready():
	# Busca el sprite del hombre (el que tiene varios fotogramas) para voltearlo
	for hijo in get_children():
		if hijo is Sprite2D and hijo.hframes > 1:
			hijo.flip_h = true # Esto voltea la imagen del hombre para que mire hacia la izquierda

func _process(delta):
	# Mover la canoa horizontalmente
	position.x += (velocidad * direccion) * delta
	
	# Animación automática por código
	tiempo_animacion += delta
	if tiempo_animacion >= (1.0 / fps_animacion):
		tiempo_animacion = 0.0
		for hijo in get_children():
			if hijo is Sprite2D and hijo.hframes > 1:
				hijo.frame = (hijo.frame + 1) % hijo.hframes

# Conecta la señal "screen_exited" de un nodo VisibleOnScreenNotifier2D a esta función
func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free() # Destruye la canoa cuando ya no se ve en pantalla para no consumir memoria
