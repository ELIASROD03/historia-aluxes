extends Area2D

## Par de columnas del minijuego. El hueco y su posicion se arman por codigo
## porque van cambiando conforme el minijuego se acelera; en la escena solo
## viven los nodos, sin medidas fijas.
##
## Las columnas NO se estiran: el Sprite2D usa region_rect mas alta que la
## textura con texture_repeat activado, asi la columna se repite y conserva sus
## proporciones de pixel art.
##
## En pipe.tscn los dos CollisionShape2D vienen con su rectangulo ya puesto
## (46 x 324.7, colocados para un hueco de 118 px centrado en y=180) para poder
## VERLOS en el editor. Al ejecutar, configurar() los reemplaza por formas
## nuevas con el hueco que toque en ese momento, asi que lo de la escena es una
## vista previa fiel, no el valor final. Para verlos corriendo:
## Depuracion -> Ver formas de colision.

const ANCHO_TEXTURA := 85.0
const REGION_ALTO := 600.0
const ESCALA := 46.0 / ANCHO_TEXTURA
const ANCHO_TUBO := ANCHO_TEXTURA * ESCALA      # 46 px
const ALTO_TUBO := REGION_ALTO * ESCALA         # ~324 px
const X_MUERTE := -80.0

var velocidad: float = 120.0
var moviendo: bool = true

@onready var arriba: Sprite2D = $Arriba
@onready var abajo: Sprite2D = $Abajo
@onready var col_arriba: CollisionShape2D = $ColArriba
@onready var col_abajo: CollisionShape2D = $ColAbajo


func _ready() -> void:
	body_entered.connect(_on_body_entered)


## centro_y = centro del hueco; hueco = alto libre entre las dos columnas.
func configurar(centro_y: float, hueco: float, vel: float) -> void:
	velocidad = vel
	position.y = 0.0

	var medio := hueco * 0.5
	var desplazamiento := medio + ALTO_TUBO * 0.5

	arriba.scale = Vector2(ESCALA, ESCALA)
	arriba.position = Vector2(0, centro_y - desplazamiento)
	abajo.scale = Vector2(ESCALA, ESCALA)
	abajo.position = Vector2(0, centro_y + desplazamiento)

	col_arriba.shape = _forma()
	col_arriba.position = arriba.position
	col_abajo.shape = _forma()
	col_abajo.position = abajo.position


## Una forma nueva por tubo: si se compartiera el recurso, cambiar el hueco de
## uno se lo cambiaria a todos los que ya estan en pantalla.
func _forma() -> RectangleShape2D:
	var forma := RectangleShape2D.new()
	forma.size = Vector2(ANCHO_TUBO, ALTO_TUBO)
	return forma


func set_speed(vel: float) -> void:
	velocidad = vel


func detener() -> void:
	moviendo = false


func _process(delta: float) -> void:
	if not moviendo:
		return
	position.x -= velocidad * delta
	if position.x < X_MUERTE:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("atlas_ab"):
		get_tree().call_group("mundo_ab", "atlas_choco")
