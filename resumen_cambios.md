# Los Aluxes que cambiaron la Historia — Resumen técnico

> Síntesis del historial de desarrollo. El log largo original (312 líneas) sigue en el historial de git.
> Godot 4.6 · 640x360 lógicos · GL Compatibility · export Android

## Arquitectura

- **Autoloads** (`project.godot`): `Global` (`Scripts/global.gd`) y `SceneTransition`.
  Usar siempre `SceneTransition.change_scene(ruta)` en vez de `change_scene_to_file`, para conservar el fundido.
- **Guardado**: un solo archivo maestro `Saves/partidas.json` con todas las partidas anidadas.
  Máximo 5 slots, id por timestamp (`save_AAMMDD_HHMMSS`). No generar `.json` sueltos por partida.
- **Diálogos**: `dialogos.json` + `dialogo_manager.gd`. Una línea con `"evento"` puede lanzar un
  minijuego o una cinemática. Soporta BBCode (`[color=red]`) y `{nombre_jugador}` / `{anio_objetivo}`.
- **Bloqueo narrativo**: `Global.en_dialogo` congela al jugador, a los NPCs y a los controles táctiles.

## Datos en JSON (se editan sin tocar código)

| Archivo | Qué define |
|---|---|
| `capitulos.json` | Tabla ÚNICA de los 6 capítulos: título, subtítulo, año, escena, diálogos |
| `dialogos.json` | Toda la narrativa (43 entradas) |
| `palabras.json` | Textos de Palabras Impostoras (`nivel_<cap>_<1..5>`) |
| `rompecabezas.json` | Niveles del rompecabezas y las dificultades |
| `burbujas.json`, `memorama_data.json` | Burbujas de mundo y memorama |
| `atlasbird.json` | Atlas-Bird: cronómetro, vidas, curva de dificultad, pesos de objetos y avisos |

## Historia: 6 capítulos

1519 Tenochtitlán · 1520 Noche Triste · 1521 Caída · 1523 Primeros años · 1530 Reformas · 1535 Virreinato

- Todo sale de `capitulos.json`. **Agregar un capítulo = una entrada nueva + su escena. Cero código.**
- `Scripts/capitulo_manager.gd` es el manager ÚNICO de todos los niveles (antes había uno casi
  idéntico por capítulo). Lo único que se configura por escena es `numero_capitulo` en el nodo raíz.
- `Capitulo1Intro.tscn` **no es del capítulo 1**: es la pantalla negra genérica de todos, tanto para
  entrar como para el "¡COMPLETADO!". Los textos se dejan con `Global.preparar_entrada_capitulo()`.
- Escenas: `Tenoch`, `Tenoch1520`, `CaidaTenochtitlan`, `PrimerosAniosVirreinato`,
  `ReformasOrganizacion`, `InstauracionVirreinato`. Las 4 últimas son copias de Tenoch, sin ambientar.

## Minijuegos

Contrato: la escena expone `nivel_a_cargar` (String) y la señal `juego_completado`. Se registra en la
constante `MINIJUEGOS` de `dialogo_manager.gd` y ya se puede lanzar desde `dialogos.json` con
`"evento": "minijuego_<clave>_<nivel>"`.

- **Rompecabezas** (`Scenes/Rompecabezas.tscn`): las piezas con forma real se generan por geometría
  (`Polygon2D` con UV mapeado), no son imágenes recortadas. Cada borde interno se calcula una vez y
  lo comparten las dos piezas vecinas, por eso siempre embonan exacto.
  Dificultad Relajado 3x3 / Desafiante 4x4 sobre fondo difuminado (shader propio), reloj de 100 s.
  **Imágenes: 900x600 px (3:2)** en `Images/img-rompecabezas/niv_N.jpg`.
- **Palabras Impostoras**: 6 capítulos × 5 textos, con 3 palabras impostoras cada uno. El NPC elige
  variante al azar según el capítulo del nivel (`zona_dialogo.gd`), no según el progreso global.
- **Atlas-Bird** (`Scenes/Juegos/Atlas-Bird/`): persecución estilo Flappy rehecha para 640x360 (la
  versión vieja estaba dimensionada para ~1152x648 y encima referenciaba 5 texturas ya borradas).
  Control seleccionable en el inspector del nodo `atlas` (`modo_control`): **TAP** (el clásico de
  Flappy, es el default) o **MANTENER**. El cronómetro de 90 s
  **no es un límite de tiempo, es la distancia a Balaam**: llegar a 0 es GANAR, el turbo resta
  segundos y el hechizo de Balaam los suma. 3 vidas, escudo que absorbe un choque, objetos en el
  hueco de las columnas (fáciles al centro, difíciles pegados al borde). Cada ~20 s Balaam invierte
  los controles o suma tiempo: primero se corta la generación de columnas y sale el cuadro de Atlas
  3 s para que dé tiempo de leer, y hasta entonces se aplica el efecto. Velocidad, intervalo y hueco
  interpolan por tiempo de juego real, así se acelera solo.
  Se lanza como `final_cap6` (evento `minijuego_atlasbird_final`) y desde el Libro de Historia.
  El HUD **no está en código**: `HUD/Vidas` (corazones), `HUD/Cronometro` (reloj + número) y
  `HUD/Escudo` son nodos; escalar o mover el padre mueve todo el grupo junto y el script solo los
  prende y apaga. Igual el modo de control: está en el inspector, no en `atlasbird.json`, a
  propósito, para poder probar TAP y MANTENER sin editar el JSON.
  Ojo: hay dos carpetas `Atlas-Bird`; la buena es `Scenes/Juegos/Atlas-Bird/`. De la otra ya solo
  queda `assets/Bosque.png`, que es el fondo que usa el minijuego.
- **Topo Alux** (`Scenes/Topo_Alux.tscn`): golpea al Kaan verdadero y esquiva los señuelos, 15 aciertos.
  Estaba **huérfana**: ninguna escena ni diálogo la abría, y no tenía salida (`ganar_juego()` solo
  hacía un `print`). Ahora entra por el Libro de Historia y lleva `BtnSalir` siempre visible, porque
  si no el libro era un callejón sin salida.
  Antes de la primera partida sale el panel `PanelComoJugar`, con `kaan.png` y `Kaan_Señuelo.png` uno
  al lado del otro para que se vea la diferencia. Se recuerda en
  `Global.eventos_completados["topo_tutorial_visto"]`, así que solo sale una vez; borrando esa clave
  vuelve a aparecer.
- **Salida desde el Libro de Historia**: los 5 minijuegos del libro tienen una salida propia de vuelta
  a `LibroHistoria.tscn`, siempre gobernada por `modo_libre = (get_parent() == get_tree().root)`.
  Abierto desde un diálogo el botón se oculta: ahí quien cierra el minijuego es el diálogo al recibir
  `juego_completado`, y un botón de salir permitiría saltarse contenido de la historia.
  Ojo con el `MenuPausa`: Memorama lo instancia y su "Ir al Menú" va al **menú principal**, no al
  libro; por eso Memorama lleva además su propio `BtnSalir`.
- Los dos primeros, abiertos desde el Libro de Historia, muestran primero un selector (nivel / capítulo) y
  botones de salida propios. Abiertos desde un diálogo van directo y el diálogo los cierra.
- Al ganar muestran su mensaje 3 segundos antes de devolver el control, para que dé tiempo de verlo.

## Trampas conocidas (leer antes de tocar UI o input)

1. **Nada de `z_index` negativo en los minijuegos.** El `Fondo` es un TextureRect opaco a pantalla
   completa con z_index 0: un -1 esconde el nodo detrás de él. Para ordenar, usar `move_child()`.
2. **`LimitesCamara` es un `ReferenceRect`, o sea un Control con `mouse_filter = STOP`**, y cubre casi
   todo el nivel. Se come los clicks antes de que lleguen a `_unhandled_input`. Un minijuego que se
   abra encima de un nivel necesita su propia capa de captura (ver `CapturaInput` en Rompecabezas).
   Sondear con `get_global_mouse_position()` en `_process` no sufre este problema.
3. **Nunca dejar una pantalla sin salida.** Este error se ha colado varias veces: pantalla negra sin
   botón, minijuego cuya señal nadie escucha en modo libre, escena destino inexistente. Si una
   pantalla puede quedarse quieta, validar el destino con `ResourceLoader.exists()` y dar un botón.
4. **Eventos de un solo uso**: registrarlos en `Global.eventos_completados` al lanzarlos, o se repiten
   al recargar la partida.
5. **Pixel art**: cámara con zoom `(1,1)` exacto y pixel snapping APAGADO; cualquier zoom fraccional
   provoca temblores. Como `stretch/mode = canvas_items`, el 2D se rasteriza a la resolución real de
   la ventana: por eso las imágenes deben tener ~3x los píxeles lógicos para verse nítidas a 1080p.
6. **Imágenes que no son pixel art**: filtro `LINEAR` (ver `filtro_pixel_art` en `rompecabezas.gd`),
   si no se ven dentadas al reducirlas.
7. Al copiar una escena a mano, quitarle el `uid` del encabezado o Godot reclama UID duplicado.

## Pendientes

- **Faltan los diálogos `final_capN` de los capítulos 2 a 5.** Sin el diálogo final un capítulo no se
  puede completar: el jugador entra al nivel pero la historia nunca avanza. Es lo más urgente.
  El de capítulo 6 ya existe (`final_cap6`, lanza Atlas-Bird desde la zona `ZonaFinalCap6` que se
  agregó al final del mapa, en x=2700).
- Las 4 escenas nuevas son copias de Tenoch: falta ambientarlas (tilesets, NPCs, recorrido).
- **Retrato del jugador roto en todos los diálogos**: apuntan a
  `Personajes_Principales/Personaje1/personaje.png`, que ya no existe (la carpeta ahora es
  `personaje1` en minúscula, con `respirando.png` y `caminando.png`). Reponer ese archivo arregla
  los 43 diálogos de una sola vez.
- Los NPCs de los capítulos 3 a 6 (Guerrero mexica, Cronista, Escribano, Pregonero) van sin retrato
  porque todavía no hay arte.
- Los años de los capítulos 4 y 5 (1523 y 1530) fueron una propuesta: ajustarlos en `capitulos.json`
  a lo que pida el temario. 1521 y 1535 sí son fechas históricas firmes.
- El orden "Primeros años de virreinato" (cap 4) antes de "Instauración del virreinato" (cap 6) es
  cronológicamente raro; si fue un cruce, se corrige moviendo bloques en `capitulos.json`.
