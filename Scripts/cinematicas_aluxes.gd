class_name CinematicasAluxes
extends Node2D
## Cinemáticas de los aluxes dentro de los niveles (caps 3, 4 y 6), animadas con
## los sprites de la escena. Responde a los eventos "cinematica_*" del diálogo y al
## terminar llama a continuar_cinematica(), igual que CinematicaKaan.
##
##  - cinematica_escape_chaac (cap 3): relámpagos, portal rojo y Chaac se mete.
##  - cinematica_nubes_chaac  (cap 4): el cielo se oscurece con nubes de tormenta
##    que se van sin soltar una gota.
##  - cinematica_rayo_chaac   (cap 4): un rayo le cae a Atlas y lo manda a volar.
##  - cinematica_huida_balaam (cap 6): Balaam se eleva y escapa por sus portales.
##
## La escena debe tener el nodo CinematicaProvisional con estos eventos en
## `ignorar`, para que no muestre su letrero encima.

const TEX_PORTAL := preload("res://Images/Fondos/portal.png")
## El mismo portal en grises, para teñirlo de rojo (Chaac); el azul original es el de Balaam.
const TEX_PORTAL_GRIS := preload("res://Images/Escenarios/comun/portal_gris.png")

const TEX_NUBE := preload("res://Images/Escenarios/comun/nube_tormenta.png")
const TEX_RAYO := preload("res://Images/Escenarios/comun/rayo.png")
const SCRIPT_RESPIRADOR := preload("res://Scripts/respirador.gd")

## El alux que protagoniza la cinemática (Chaac o Balaam) y Atlas.
@export var alux: Node2D
@export var atlas: Node2D

var _cuadro: Node


func _ready() -> void:
	_cuadro = get_tree().current_scene.find_child("CuadroDialogo", true, false)
	if _cuadro:
		_cuadro.evento_cinematica.connect(_on_evento_cinematica)


func _on_evento_cinematica(evento: String) -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	match evento:
		"cinematica_escape_chaac":
			await _escape_por_portal(Color(1.0, 0.3, 0.25), true)
		"cinematica_huida_balaam":
			await _escape_por_portal(Color(0.45, 0.7, 1.0), false)
		"cinematica_nubes_chaac":
			await _nubes()
		"cinematica_rayo_chaac":
			await _rayo_a_atlas()
		_:
			return
	if _cuadro:
		_cuadro.continuar_cinematica()


# ── piezas ──────────────────────────────────────────────────────────────────

## Destello blanco a pantalla completa (relámpago).
func _destello(veces: int = 2) -> void:
	var capa := CanvasLayer.new()
	capa.layer = 50
	var blanco := ColorRect.new()
	blanco.color = Color(1, 1, 1, 0)
	blanco.set_anchors_preset(Control.PRESET_FULL_RECT)
	blanco.mouse_filter = Control.MOUSE_FILTER_IGNORE
	capa.add_child(blanco)
	add_child(capa)
	for i in veces:
		var t := create_tween()
		t.tween_property(blanco, "color:a", 0.85, 0.05)
		t.tween_property(blanco, "color:a", 0.0, 0.18)
		await t.finished
		await get_tree().create_timer(0.08).timeout
	capa.queue_free()


## Portal animado (portal.png 3x3): el azul original, o el gris teñido de `color`.
func _crear_portal(pos: Vector2, color: Color, tenido: bool) -> Sprite2D:
	var portal := Sprite2D.new()
	portal.texture = TEX_PORTAL_GRIS if tenido else TEX_PORTAL
	if not tenido:
		color = Color.WHITE
	portal.hframes = 3
	portal.vframes = 3
	portal.modulate = color
	portal.global_position = pos
	portal.scale = Vector2.ZERO
	portal.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().current_scene.add_child(portal)
	portal.set_script(SCRIPT_RESPIRADOR)
	portal._ready()
	return portal


## Chaac (con relámpagos) o Balaam (volando hacia arriba) se van por un portal.
func _escape_por_portal(color: Color, con_rayos: bool) -> void:
	if alux == null:
		return
	var origen := alux.global_position
	var vuela := not con_rayos
	var destino := origen + (Vector2(0, -90) if vuela else Vector2(40, -20))

	if con_rayos:
		_rayo_en(origen + Vector2(60, 0))
		await _destello(2)
	var portal := _crear_portal(destino, color, con_rayos)
	var t := create_tween()
	t.tween_property(portal, "scale", Vector2(1.3, 1.3), 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await t.finished

	# El alux se eleva (Balaam) o camina (Chaac) hacia el portal y se encoge al entrar
	var ta := create_tween()
	ta.tween_property(alux, "global_position", destino, 1.2 if vuela else 0.9).set_trans(Tween.TRANS_SINE)
	ta.parallel().tween_property(alux, "scale", Vector2(0.2, 0.2), 0.4).set_delay(0.9 if vuela else 0.6)
	ta.parallel().tween_property(alux, "modulate:a", 0.0, 0.4).set_delay(0.9 if vuela else 0.6)
	await ta.finished
	alux.visible = false

	if vuela:
		# "Se va volando por sus portales": abre otro más lejos y desaparece ahí
		var t2 := create_tween()
		t2.tween_property(portal, "scale", Vector2.ZERO, 0.3)
		await t2.finished
		portal.global_position = destino + Vector2(160, -30)
		var t3 := create_tween()
		t3.tween_property(portal, "scale", Vector2(0.9, 0.9), 0.3)
		t3.tween_interval(0.3)
		t3.tween_property(portal, "scale", Vector2.ZERO, 0.3)
		await t3.finished
	else:
		await _destello(1)
		var t4 := create_tween()
		t4.tween_property(portal, "scale", Vector2.ZERO, 0.4)
		await t4.finished
	portal.queue_free()


## Nubes de tormenta: el cielo se oscurece, retumba... y las nubes se van sin llover.
func _nubes() -> void:
	var camara := get_viewport().get_camera_2d()
	var centro := camara.get_screen_center_position() if camara else Vector2(320, 180)

	var capa := CanvasLayer.new()
	capa.layer = 5
	var sombra := ColorRect.new()
	sombra.color = Color(0.05, 0.05, 0.12, 0.0)
	sombra.set_anchors_preset(Control.PRESET_FULL_RECT)
	sombra.mouse_filter = Control.MOUSE_FILTER_IGNORE
	capa.add_child(sombra)
	add_child(capa)

	var nubes: Array[Sprite2D] = []
	for i in 6:
		var n := Sprite2D.new()
		n.texture = TEX_NUBE
		n.scale = Vector2(1.6, 1.6) * randf_range(0.8, 1.2)
		n.flip_h = i % 2 == 1
		var lado := -1.0 if i % 2 == 0 else 1.0
		n.global_position = centro + Vector2(lado * 420 + i * 10, -150 + randf_range(-15, 15))
		n.set_meta("x_final", centro.x - 280 + i * 110)
		n.z_index = 20
		get_tree().current_scene.add_child(n)
		nubes.append(n)

	var t := create_tween().set_parallel()
	t.tween_property(sombra, "color:a", 0.55, 1.0)
	for n in nubes:
		t.tween_property(n, "global_position:x", float(n.get_meta("x_final")), 1.2).set_trans(Tween.TRANS_SINE)
	await t.finished
	await _destello(1)
	await get_tree().create_timer(1.2).timeout

	# ...y se van como llegaron
	var t2 := create_tween().set_parallel()
	t2.tween_property(sombra, "color:a", 0.0, 1.2)
	for n in nubes:
		t2.tween_property(n, "global_position:y", n.global_position.y - 120, 1.4).set_trans(Tween.TRANS_SINE)
		t2.tween_property(n, "modulate:a", 0.0, 1.4)
	await t2.finished
	for n in nubes:
		n.queue_free()
	capa.queue_free()


## Un rayo baja en `pos` (los pies del rayo tocan ese punto) y se apaga solo.
func _rayo_en(pos: Vector2) -> void:
	var rayo := Sprite2D.new()
	rayo.texture = TEX_RAYO
	rayo.centered = false
	rayo.offset = Vector2(-TEX_RAYO.get_width() / 2.0, -TEX_RAYO.get_height())
	rayo.scale = Vector2(1.5, 1.5)
	rayo.global_position = pos
	rayo.z_index = 30
	get_tree().current_scene.add_child(rayo)
	var t := create_tween()
	t.tween_property(rayo, "modulate:a", 0.2, 0.06)
	t.tween_property(rayo, "modulate:a", 1.0, 0.06)
	t.tween_interval(0.25)
	t.tween_property(rayo, "modulate:a", 0.0, 0.25)
	t.tween_callback(rayo.queue_free)


## Chaac le lanza un rayo a Atlas: sale volando dando vueltas y cae de golpe.
func _rayo_a_atlas() -> void:
	if atlas == null:
		return
	var origen := atlas.global_position
	_rayo_en(origen + Vector2(0, 16))
	await _destello(2)

	var arriba := origen + Vector2(-70, -110)
	var abajo := origen + Vector2(-110, 10)
	var t := create_tween()
	t.tween_property(atlas, "global_position", arriba, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(atlas, "rotation", -TAU * 1.5, 1.0)
	t.tween_property(atlas, "global_position", abajo, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await t.finished
	atlas.rotation = 0.0
	# Queda "tirado" un momento y se reincorpora junto al jugador
	var t2 := create_tween()
	t2.tween_property(atlas, "modulate", Color(0.6, 0.6, 0.6), 0.1)
	t2.tween_interval(0.6)
	t2.tween_property(atlas, "modulate", Color.WHITE, 0.3)
	await t2.finished
