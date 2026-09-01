extends Area2D

## Objeto recogible del minijuego: vida, escudo o turbo. Comparte velocidad con
## los tubos (grupo "moviles_ab") para que se muevan como una sola pieza.

enum Tipo { VIDA, ESCUDO, TURBO }

const TEXTURAS := {
	Tipo.VIDA: "res://assets/Elementos-Rush/obj_juegoRush1.png",
	Tipo.ESCUDO: "res://assets/Elementos-Rush/obj_juegoRush3.png",
	Tipo.TURBO: "res://assets/Elementos-Rush/obj_juegoRush5.png",
}
const X_MUERTE := -60.0

var tipo: int = Tipo.TURBO
var velocidad: float = 120.0
var moviendo: bool = true

var _tiempo: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func configurar(nuevo_tipo: int, vel: float) -> void:
	tipo = nuevo_tipo
	velocidad = vel
	if TEXTURAS.has(tipo):
		sprite.texture = load(TEXTURAS[tipo])


func set_speed(vel: float) -> void:
	velocidad = vel


func detener() -> void:
	moviendo = false


func _process(delta: float) -> void:
	if not moviendo:
		return
	_tiempo += delta
	position.x -= velocidad * delta
	# El balanceo va en el SPRITE y no en el Area2D a proposito: el objeto se ve
	# vivo, pero su zona de recogida se queda clavada exactamente en el centro
	# del hueco. Si se moviera la raiz, el objeto dejaria de estar justo en medio
	# de los dos tubos y con el hueco ya cerrado a 92 px se notaria.
	sprite.position.y = sin(_tiempo * 3.0) * 4.0
	sprite.rotation_degrees = sin(_tiempo * 2.0) * 8.0
	if position.x < X_MUERTE:
		queue_free()


## Se sortea si el objeto sirve cuando NACE, pero tarda entre 3 y 5 segundos en
## cruzar la pantalla: en ese rato el jugador pudo agarrar otro escudo o llenar
## sus vidas. Cada vez que cambia el marcador, el mundo avisa por aqui y el
## objeto que quedo de sobra se desvanece en vez de llegar como un premio vacio.
func revisar_utilidad(tiene_escudo: bool, vidas_llenas: bool) -> void:
	if not moviendo:
		return
	if (tipo == Tipo.ESCUDO and tiene_escudo) or (tipo == Tipo.VIDA and vidas_llenas):
		moviendo = false
		set_deferred("monitoring", false)
		var tween := create_tween()
		tween.tween_property(self, "modulate:a", 0.0, 0.3)
		tween.tween_callback(queue_free)


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("atlas_ab"):
		return
	get_tree().call_group("mundo_ab", "recoger_objeto", tipo)
	moviendo = false
	set_deferred("monitoring", false)
	_animar_recogida()


func _animar_recogida() -> void:
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.6, 1.6), 0.25)
	tween.tween_property(self, "modulate:a", 0.0, 0.25)
	tween.chain().tween_callback(queue_free)
