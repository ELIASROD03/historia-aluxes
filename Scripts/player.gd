class_name Player
extends CharacterBody2D

const SPEED = 150.0
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var sprite = $Sprite2D

var tex_idle: Texture2D
var tex_walk: Texture2D

# Referencia directa al Autoload si existe, para evitar buscarlo cada frame
var global_ref: Node = null

func debug_log(msg: String):
	# Imprimir en consola siempre es rápido
	print(msg)
	
	# OPCIONAL: Si realmente necesitas escribir en archivo, hazlo solo en _ready o eventos raros.
	# Evita llamarlo dentro de _physics_process.
	var f = FileAccess.open("user://debug_log.txt", FileAccess.READ_WRITE)
	if not f:
		f = FileAccess.open("user://debug_log.txt", FileAccess.WRITE)
	if f:
		f.seek_end()
		f.store_line(msg)
		f.close()

func _ready() -> void:
	# Limpiar el log al inicio
	var f = FileAccess.open("user://debug_log.txt", FileAccess.WRITE)
	if f: f.close() 
	
	debug_log("Player _ready iniciado")
	
	# Guardamos la referencia de Global una sola vez al cargar la escena
	if has_node("/root/Global"):
		global_ref = get_node("/root/Global")
		debug_log("GlobalNode encontrado y referenciado")
	else:
		debug_log("No se encontro /root/Global en _ready")

	# Cargar texturas desde el nodo Global si están disponibles
	if global_ref:
		var ruta_idle = global_ref.get("ruta_spritesheet")
		debug_log("Ruta idle: " + str(ruta_idle))
		if typeof(ruta_idle) == TYPE_STRING and ruta_idle != "":
			var loaded_idle = load(ruta_idle)
			if loaded_idle: 
				tex_idle = loaded_idle
				debug_log("Cargada textura idle ok")
			
		var ruta_walk = global_ref.get("ruta_walk")
		debug_log("Ruta walk: " + str(ruta_walk))
		if typeof(ruta_walk) == TYPE_STRING and ruta_walk != "":
			var loaded_walk = load(ruta_walk)
			if loaded_walk: 
				tex_walk = loaded_walk
				debug_log("Cargada textura walk ok")

	# Fallbacks por defecto
	if not tex_idle:
		tex_idle = load("res://Images/Personajes/Personajes_Principales/personaje1/respirando.png")
	if not tex_walk:
		tex_walk = load("res://Images/Personajes/Personajes_Principales/personaje1/caminando.png")

	if tex_idle:
		debug_log("Asignando textura idle inicial")
		_set_texture(tex_idle, 9, true)
		
	# Cargar posición si venimos de cargar partida
	if global_ref and global_ref.get("flag_cargar_posicion"):
		global_position = Vector2(global_ref.get("posicion_x"), global_ref.get("posicion_y"))
		global_ref.set("flag_cargar_posicion", false)
		debug_log("Posicion cargada: " + str(global_position))

func _set_texture(new_tex: Texture2D, frames: int, force: bool = false) -> void:
	var needs_update = false
	if force:
		needs_update = true
	elif sprite.texture != new_tex:
		needs_update = true
		
	if new_tex and needs_update:
		sprite.texture = new_tex
		sprite.hframes = frames
		sprite.vframes = 1
		sprite.frame = 0
		if sprite.has_method("reset_timer"):
			sprite.reset_timer()

func _physics_process(delta: float) -> void:
	# 1. Aplicar Gravedad
	if not is_on_floor():
		velocity.y += gravity * delta

	# 2. Verificar si está en diálogo usando la referencia optimizada
	var en_dialogo = false
	if global_ref:
		en_dialogo = global_ref.get("en_dialogo") == true

	# 3. Control de Movimiento y Animación
	if en_dialogo:
		velocity.x = 0.0
		if tex_idle:
			_set_texture(tex_idle, 9)
	else:
		var direction := Input.get_axis("ui_left", "ui_right")
		if direction:
			velocity.x = direction * SPEED
			sprite.flip_h = direction < 0
			if tex_walk:
				_set_texture(tex_walk, 9)
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
			if tex_idle:
				_set_texture(tex_idle, 9)

	# 4. Mover al personaje (Sincronizado con la física)
	move_and_slide()
