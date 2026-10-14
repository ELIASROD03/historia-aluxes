extends Node
## Preferencias del DISPOSITIVO, no de la partida: volumen, pantalla completa y
## controles táctiles. Viven en user://config.cfg, aparte de user://partidas.json,
## porque las comparten todos los jugadores del mismo equipo.

signal cambiada

const RUTA := "user://config.cfg"

# Clave de volumen -> bus de audio (los buses están en default_bus_layout.tres).
# Para que un sonido obedezca su control, ponle `bus = "Musica"` o `"Efectos"`.
const BUSES := {"general": "Master", "musica": "Musica", "efectos": "Efectos"}

enum ModoTactil { AUTOMATICO, SIEMPRE, OCULTOS }

const TAMANO_TACTIL_MIN := 0.9
const TAMANO_TACTIL_MAX := 1.8
const OPACIDAD_TACTIL_MIN := 0.25

var volumen := {"general": 1.0, "musica": 0.8, "efectos": 0.8}
var pantalla_completa := false
var modo_tactil: int = ModoTactil.AUTOMATICO
var tamano_tactil := 1.3
var opacidad_tactil := 0.75

func _ready() -> void:
	_asegurar_buses()
	if cargar():
		_aplicar_pantalla()
	else:
		# Sin config guardada manda project.godot (window/size/mode): el interruptor
		# solo refleja cómo arrancó la ventana.
		var modo := DisplayServer.window_get_mode()
		pantalla_completa = modo == DisplayServer.WINDOW_MODE_FULLSCREEN \
			or modo == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
	_aplicar_audio()

## En móvil no hay ventana que agrandar ni teclado con qué jugar sin los botones.
func es_movil() -> bool:
	return OS.has_feature("mobile")

# --- Cambios (los llama el panel de configuración) ---

func set_volumen(clave: String, valor: float) -> void:
	volumen[clave] = clampf(valor, 0.0, 1.0)
	_aplicar_audio()

func set_pantalla_completa(activa: bool) -> void:
	pantalla_completa = activa
	_aplicar_pantalla()

func set_controles(modo: int, tamano: float, opacidad: float) -> void:
	# En móvil ocultarlos dejaría al jugador sin forma de moverse.
	if es_movil() and modo == ModoTactil.OCULTOS:
		modo = ModoTactil.AUTOMATICO
	modo_tactil = modo
	tamano_tactil = clampf(tamano, TAMANO_TACTIL_MIN, TAMANO_TACTIL_MAX)
	opacidad_tactil = clampf(opacidad, OPACIDAD_TACTIL_MIN, 1.0)
	cambiada.emit()

# --- Aplicar ---

func _aplicar_audio() -> void:
	for clave in BUSES:
		var idx := AudioServer.get_bus_index(BUSES[clave])
		if idx == -1:
			continue
		var v: float = volumen[clave]
		AudioServer.set_bus_mute(idx, v <= 0.001)
		AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(v, 0.001)))

func _aplicar_pantalla() -> void:
	if es_movil():
		return
	if pantalla_completa:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)

## Por si se borra default_bus_layout.tres: sin el bus, su volumen no haría nada.
func _asegurar_buses() -> void:
	for nombre in ["Musica", "Efectos"]:
		if AudioServer.get_bus_index(nombre) == -1:
			AudioServer.add_bus()
			var idx := AudioServer.bus_count - 1
			AudioServer.set_bus_name(idx, nombre)
			AudioServer.set_bus_send(idx, "Master")

# --- Guardar / cargar ---

## Devuelve false si todavía no hay configuración guardada.
func cargar() -> bool:
	var cfg := ConfigFile.new()
	if cfg.load(RUTA) != OK:
		return false
	for clave in volumen:
		volumen[clave] = clampf(float(cfg.get_value("audio", clave, volumen[clave])), 0.0, 1.0)
	pantalla_completa = bool(cfg.get_value("pantalla", "completa", pantalla_completa))
	set_controles(
		int(cfg.get_value("controles", "modo", modo_tactil)),
		float(cfg.get_value("controles", "tamano", tamano_tactil)),
		float(cfg.get_value("controles", "opacidad", opacidad_tactil)))
	return true

func guardar() -> void:
	var cfg := ConfigFile.new()
	for clave in volumen:
		cfg.set_value("audio", clave, volumen[clave])
	cfg.set_value("pantalla", "completa", pantalla_completa)
	cfg.set_value("controles", "modo", modo_tactil)
	cfg.set_value("controles", "tamano", tamano_tactil)
	cfg.set_value("controles", "opacidad", opacidad_tactil)
	cfg.save(RUTA)
