extends Node
## Lo que el jugador ya desbloqueó en el Libro de Historia. Es del DISPOSITIVO,
## no de la partida (como los logros): queda aunque se borren partidas, porque el
## libro se abre desde el menú principal sin elegir partida.
##
## Claves (las mismas que los eventos de dialogos.json, sin "minijuego_"):
##   rompecabezas_nivel_<N>      palabras_nivel_<cap>_<n>      topo_cap2
##   atlasbird_final             capitulo_<N>
## Quien las marca: DialogoManager al lanzar un minijuego y CapituloManager al
## terminar un capítulo.

const RUTA := "user://libro.cfg"
const SECCION := "desbloqueado"

var _cfg := ConfigFile.new()


func _ready() -> void:
	if _cfg.load(RUTA) != OK:
		_importar_partidas()
		_guardar()


func desbloquear(clave: String) -> void:
	# Se mira lo guardado, no esta_desbloqueado(): en modo desarrollador todo
	# "parece" abierto y no se guardaría lo que el jugador sí desbloqueó.
	if clave == "" or bool(_cfg.get_value(SECCION, clave, false)):
		return
	_cfg.set_value(SECCION, clave, true)
	_guardar()


func esta_desbloqueado(clave: String) -> bool:
	return todo_abierto() or bool(_cfg.get_value(SECCION, clave, false))


## En modo desarrollador el libro se ve completo, pero sin escribir nada en
## libro.cfg: al apagarlo vuelve lo que de verdad se ha desbloqueado.
func todo_abierto() -> bool:
	return Configuracion.modo_desarrollador


## Cuántas claves desbloqueadas empiezan con `prefijo` ("palabras_nivel_3_" → textos del cap 3).
func contar(prefijo: String) -> int:
	if not _cfg.has_section(SECCION):
		return 0
	var n := 0
	for clave in _cfg.get_section_keys(SECCION):
		if clave.begins_with(prefijo) and esta_desbloqueado(clave):
			n += 1
	return n


func _guardar() -> void:
	_cfg.save(RUTA)


## La primera vez (aún no existe libro.cfg) se toma lo que ya se jugó en las
## partidas guardadas, para que el libro no aparezca vacío a quien ya avanzó.
## De Palabras Impostoras no se sabe qué texto tocó: se cuenta el primero.
func _importar_partidas() -> void:
	if not FileAccess.file_exists(Global.RUTA_MAESTRA):
		return
	var datos = JSON.parse_string(FileAccess.get_file_as_string(Global.RUTA_MAESTRA))
	if typeof(datos) != TYPE_DICTIONARY:
		return
	for partida in datos.values():
		if typeof(partida) != TYPE_DICTIONARY:
			continue
		var progreso := int(partida.get("progreso_historia", 1))
		var eventos: Dictionary = partida.get("eventos_completados", {})
		for n in range(1, progreso):
			_cfg.set_value(SECCION, "capitulo_%d" % n, true)
		for n in range(1, progreso + 1):
			_cfg.set_value(SECCION, "rompecabezas_nivel_%d" % n, true)
			if eventos.get("dialogo_soldado_cap%d" % n, false):
				_cfg.set_value(SECCION, "palabras_nivel_%d_1" % n, true)
		if progreso > 2:
			_cfg.set_value(SECCION, "topo_cap2", true)
		if eventos.get("juego_terminado", false) or progreso > 6:
			_cfg.set_value(SECCION, "atlasbird_final", true)
