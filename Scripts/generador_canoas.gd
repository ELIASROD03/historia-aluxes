extends Node2D

@export var escena_canoa: PackedScene
@export var tiempo_spawn: float = 10.0
@export var activo: bool = true

var timer: Timer

func _ready():
	timer = Timer.new()
	timer.wait_time = tiempo_spawn
	timer.autostart = true
	timer.timeout.connect(_on_timer_timeout)
	add_child(timer)
	
	# Opcional: Generar la primera canoa inmediatamente al iniciar la escena
	# _generar_canoa()

func _on_timer_timeout():
	if activo:
		_generar_canoa()

func _generar_canoa():
	if escena_canoa:
		var nueva_canoa = escena_canoa.instantiate()
		nueva_canoa.global_position = global_position
		# Añadir a la escena raíz actual para que no se mueva junto con el generador si este se moviera
		get_tree().current_scene.add_child(nueva_canoa)

# Se llamará desde el Area2D cuando el jugador se acerque
func detener_generacion():
	activo = false
	timer.stop()

# Señal conectada al Area2D del jugador (Asegúrate de conectarlo en el editor)
func _on_area_2d_body_entered(body):
	if body.name == "Player": # Verifica que sea el jugador el que entró
		detener_generacion()
