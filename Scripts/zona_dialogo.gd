class_name ZonaDialogo
extends Area2D

@export var id_dialogo: String = "dialogo_soldado"

## Id que ya usaban las 6 escenas para la zona del soldado. Significa "no lances
## este diálogo tal cual, elige una variante al azar". Se conserva para no tener
## que editar las escenas una por una.
const ID_VARIANTES := "dialogo_soldado"

@export_group("Variantes al azar")
## Si es true, en vez de id_dialogo se lanza una variante al azar:
##     <id_dialogo>_cap<N>_<1..variantes>       (N = capítulo del nivel)
## Sirve para que el mismo NPC cuente un texto distinto en cada capítulo.
@export var variantes_por_capitulo: bool = false
@export_range(1, 20) var variantes: int = 5

@export_group("Interacción")
@export var requiere_interaccion: bool = false
@export var texto_interaccion: String = "Inspeccionar"
@export var un_solo_uso: bool = true

var jugador_cerca: bool = false
var label_interaccion: Label

func _ready() -> void:
	# Si ya lo completamos y es de un solo uso, lo desactivamos y no hacemos nada más
	if un_solo_uso and Global.eventos_completados.get(_clave_evento(), false):
		monitoring = false
		return
		
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Crear y configurar el Label de interacción automáticamente si no existe
	if requiere_interaccion:
		if has_node("LabelInteraccion"):
			label_interaccion = get_node("LabelInteraccion")
		else:
			label_interaccion = Label.new()
			label_interaccion.name = "LabelInteraccion"
			label_interaccion.position = Vector2(-25, -35) # Ajustable según el tamaño de tu NPC
			label_interaccion.custom_minimum_size = Vector2(50, 15)
			label_interaccion.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			label_interaccion.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
			label_interaccion.add_theme_constant_override("outline_size", 3)
			label_interaccion.add_theme_font_size_override("font_size", 8)
			add_child(label_interaccion)
			
		label_interaccion.text = texto_interaccion
		label_interaccion.visible = false

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player" or body is Player:
		jugador_cerca = true
		if requiere_interaccion:
			if label_interaccion:
				label_interaccion.visible = true
		else:
			lanzar_dialogo()

func _on_body_exited(body: Node2D) -> void:
	if body.name == "Player" or body is Player:
		jugador_cerca = false
		if label_interaccion:
			label_interaccion.visible = false

func _input(event: InputEvent) -> void:
	if requiere_interaccion and jugador_cerca and event.is_action_pressed("ui_accept"):
		lanzar_dialogo()

## Qué capítulo es el nivel donde está esta zona. Se le pregunta al CapituloManager
## subiendo por el árbol y NO con get_tree().current_scene: durante el _ready de un
## nivel recién cargado, current_scene todavía puede apuntar a la escena anterior,
## mientras que los nodos padre ya están en su sitio.
func _capitulo_del_nivel() -> int:
	var nodo: Node = self
	while nodo != null:
		if "numero_capitulo" in nodo:
			return int(nodo.numero_capitulo)
		nodo = nodo.get_parent()
	return Global.progreso_historia


## Clave con la que se recuerda que este diálogo ya se vio.
## Lleva el número de capítulo a fuerza: las 6 escenas de nivel salieron de copiar
## Tenoch.tscn, así que TODAS comparten el mismo id_dialogo ("dialogo_soldado",
## "dialogo_kaan", "encuentro_cortes_moctezuma"). Sin el capítulo en la clave,
## hablar con el soldado del capítulo 1 apagaba de una vez a los de los capítulos
## 2 a 6, que nacían con monitoring = false y nunca se activaban.
func _clave_evento() -> String:
	return "%s_cap%d" % [id_dialogo, _capitulo_del_nivel()]


func lanzar_dialogo() -> void:
	var cuadro_dialogo = get_tree().current_scene.find_child("CuadroDialogo", true, false)
	
	if cuadro_dialogo and cuadro_dialogo.has_method("iniciar_dialogo") and not cuadro_dialogo.visible:
		var dialogo_a_lanzar = id_dialogo
		if variantes_por_capitulo or id_dialogo == ID_VARIANTES:
			dialogo_a_lanzar = "%s_cap%d_%d" % [id_dialogo, _capitulo_del_nivel(), (randi() % variantes) + 1]

		cuadro_dialogo.iniciar_dialogo(dialogo_a_lanzar)
		
		if label_interaccion:
			label_interaccion.visible = false
			
		if un_solo_uso:
			Global.eventos_completados[_clave_evento()] = true
			set_deferred("monitoring", false)
			jugador_cerca = false
