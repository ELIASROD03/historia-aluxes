# Los Aluxes que cambiaron la Historia — Notas técnicas

> Godot 4.6 · 640x360 · GL Compatibility · export Android. Sin tests: se verifica corriendo la escena.
> No documenta el código, sino lo que no se ve leyéndolo: decisiones, trampas y pendientes.

## Invariantes

- **Autoloads**: `Global` (`Scripts/global.gd`) y `SceneTransition`. Cambiar de escena SIEMPRE con
  `SceneTransition.change_scene(ruta)`, nunca `change_scene_to_file`, o se pierde el fundido.
- **Guardado**: un único `Saves/partidas.json` con todas las partidas anidadas (máx. 5, id por
  timestamp). No generar `.json` sueltos por partida.
- **`Global.en_dialogo`** congela jugador, NPCs y controles táctiles.
- **`Global.eventos_completados`**: contenido de un solo uso. Marcarlo AL LANZAR, no al terminar, o se
  repite si el jugador recarga a media escena.
- **Capítulos**: todo sale de `capitulos.json`; `capitulo_manager.gd` es el manager único de los 6
  niveles y lo único por escena es `numero_capitulo`. `Capitulo1Intro.tscn` es la pantalla negra
  genérica de TODOS los capítulos, no la del 1.

## Contenido en JSON (se edita sin abrir Godot)

| Archivo | Qué define |
|---|---|
| `capitulos.json` | Los 6 capítulos: título, año, escena, diálogo inicial y final |
| `dialogos.json` | Toda la narrativa |
| `palabras.json`, `rompecabezas.json`, `burbujas.json`, `memorama_data.json` | Sus minijuegos |
| `atlasbird.json` | Atlas-Bird: reloj, vidas, curva de dificultad, pesos de objetos, avisos |

## Minijuegos

**Contrato**: la escena expone `nivel_a_cargar` (String) y la señal `juego_completado`; se registra en
`MINIJUEGOS` de `dialogo_manager.gd` y ya se lanza con `"evento": "minijuego_<clave>_<nivel>"`.

**Patrón `modo_libre`** (los 5 lo usan): `modo_libre = (get_parent() == get_tree().root)`. En true se
entró desde el Libro y hay botón de salir de vuelta a él; en false lo abrió un diálogo y el botón se
OCULTA — ahí cierra el diálogo al recibir `juego_completado`, y un salir dejaría saltarse contenido.
Ojo: el "Ir al Menú" del `MenuPausa` que instancia Memorama va al menú principal, no al libro.

- **Rompecabezas**: piezas por geometría (`Polygon2D` con UV), no recortes; cada borde se calcula una
  vez y lo comparten las dos vecinas. Imágenes **900x600 (3:2)** en `Images/img-rompecabezas/niv_N.jpg`.
- **Palabras Impostoras**: la variante la elige `zona_dialogo.gd` por el capítulo del NIVEL, no por el
  progreso global.
- **Atlas-Bird** (`Scenes/Juegos/Atlas-Bird/`): el reloj de 90 s no es un límite, es la distancia a
  Balaam — llegar a 0 es GANAR, el turbo resta y el hechizo suma. Se pierde sin vidas.
  Lo ajustable vive en dos sitios a propósito: los números en `atlasbird.json`, pero el HUD (grupos
  `HUD/Vidas`, `HUD/Cronometro`, `HUD/Escudo`) y `modo_control` (TAP o MANTENER) en la ESCENA.
  Con TAP invertido hay que voltear también la gravedad; volteando solo el toque no hay forma de
  subir y el hechizo es una muerte segura.
  ⚠️ Hay dos carpetas `Atlas-Bird`. La buena es `Scenes/Juegos/Atlas-Bird/`, pero el fondo que usa
  sigue siendo `Scenes/Atlas-Bird/assets/Bosque.png`: no borres esa carpeta "por duplicada".
- **Topo Alux**: ficha "Cómo jugar" recordada en `eventos_completados["topo_tutorial_visto"]`; su
  botón desaparece cuando sale el primer topo (ver trampa 2). Reloj de 45 s, al agotarse se pierde.

## Trampas (leer antes de tocar UI o input)

1. **`DialogoManager` escucha con `_input`, no `_gui_input`**, y `_input` corre ANTES que la GUI: con el
   cuadro visible **cualquier clic lo avanza, aunque caiga sobre un botón**. Evitarlo exigiría tocar
   `dialogo_manager.gd` (lo usan las 6 escenas). Se compensa desde el minijuego: deshacer lo que ese
   clic disparó y reponer el diálogo al cerrar el panel.
2. **Un `Button` oculto o `disabled` no emite `pressed`.** Combinado con la trampa 1: si el clic sobre
   un botón dispara algo que lo esconde en el mouse DOWN, el mouse UP ya no encuentra botón y el botón
   "no hace nada". Esconderlo más tarde, en un momento que no sea el del propio clic.
3. **`LimitesCamara` es un `ReferenceRect`** (Control con `mouse_filter = STOP`) que cubre casi todo el
   nivel y se come los clics antes de `_unhandled_input`. Un minijuego encima de un nivel necesita su
   propia capa de captura (ver `CapturaInput` en Rompecabezas y Atlas-Bird).
4. **Minijuego como overlay = mismo espacio físico que el nivel.** `CanvasLayer` solo afecta al dibujo,
   NO a la física: sus `Area2D` chocarían con el Player del nivel. Atlas-Bird lo aísla poniendo todo en
   `collision_layer/mask = 128`.
5. **Nunca dejar una pantalla sin salida.** Se ha colado varias veces (Topo Alux y la pantalla de
   inicio de Atlas-Bird estaban así). Validar destinos con `ResourceLoader.exists()` y dar botón.
6. **Nada de `z_index` negativo**: el fondo es un TextureRect opaco con z_index 0; ordenar con el árbol
   o `move_child()`. Un velo a pantalla completa tapa los botones dibujados antes que él: colocarlo
   ANTES en el árbol si quieres que alguno siga siendo pulsable.
7. **Escalar un `Node2D` padre escala también la fuente de los `Label` hijos**: si el número se ve
   borroso, bajar la escala del grupo y subir el `font_size`.
8. **Pixel art**: zoom de cámara `(1,1)` exacto y pixel snapping APAGADO (los fraccionales tiemblan).
   Con `stretch/mode = canvas_items` el 2D se rasteriza a la resolución real: las imágenes necesitan
   ~3x los píxeles lógicos para verse nítidas a 1080p. Lo que no es pixel art, filtro `LINEAR`.
9. **UIDs**: al copiar una escena a mano, quitarle el `uid` del encabezado o Godot reclama duplicado. Y
   si editas un `.tscn` por fuera con el editor abierto, puede reasignarle uno nuevo y romper a quien la
   referencie: revisar el encabezado después.

## Cómo verificar sin poder jugar

`godot --headless --path . --script res://tmp.gd` con un `extends SceneTree`: cargar la escena compila
su script y delata nodos faltantes; añadiéndola al árbol y llamando métodos se prueba la lógica.
`--check-only --script` NO sirve si el script usa autoloads ("Identifier not found"): cargar la escena
sí. ⚠️ El proyecto vive en OneDrive y ha revertido archivos a media sesión: `git checkout -- <archivo>`.

## Pendientes

- **Faltan `final_cap2` … `final_cap5`.** Sin diálogo final el capítulo no se completa: el jugador
  entra pero la historia nunca avanza. Es lo más urgente. El `final_cap6` ya existe y lanza Atlas-Bird
  desde `ZonaFinalCap6` (x=2700 de `InstauracionVirreinato`).
- **Retrato del jugador roto en todos los diálogos**: apuntan a
  `Personajes_Principales/Personaje1/personaje.png`, que ya no existe (la carpeta ahora es `personaje1`
  en minúscula, con `respirando.png` y `caminando.png`). Reponerlo lo arregla todo de una vez.
- **Memorama no maneja la victoria**: al juntar las parejas solo hace un `print`.
- Las 4 escenas de los capítulos 3 a 6 son copias de Tenoch sin ambientar, y sus NPCs van sin retrato.
- Años de los capítulos 4 y 5 (1523, 1530): eran propuesta, ajustarlos al temario (1521 y 1535 sí son
  firmes). Y cap 4 "Primeros años" antes de cap 6 "Instauración" es cronológicamente raro.
