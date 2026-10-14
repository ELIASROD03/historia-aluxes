# Los Aluxes que cambiaron la Historia — Notas técnicas

> Godot 4.6 · 640x360 · GL Compatibility · export Android. Sin tests: se verifica corriendo la escena.
> No documenta el código, sino lo que no se ve leyéndolo: decisiones, trampas y pendientes.

## Invariantes

- **Autoloads**: `Global` (`Scripts/global.gd`), `SceneTransition` y `Configuracion`. Cambiar de escena SIEMPRE con
  `SceneTransition.change_scene(ruta)`, nunca `change_scene_to_file`, o se pierde el fundido.
- **Guardado**: un único `user://partidas.json` con todas las partidas anidadas (máx. 5, id por
  timestamp). No generar `.json` sueltos por partida. NUNCA en `res://`: en el APK es de solo
  lectura. El viejo `Saves/partidas.json` solo se migra al correr desde el editor y está excluido
  del export.
- **Configuración** (autoload `Configuracion`): preferencias del dispositivo en `user://config.cfg`
  (volumen, pantalla completa, controles táctiles), aparte de las partidas. El panel
  `PanelConfiguracion.tscn` se abre desde el menú principal y desde la pausa (ahí sin "Borrar
  partidas"). Sonidos nuevos: `bus = "Musica"` o `"Efectos"` para que obedezcan su volumen.
- **`Global.en_dialogo`** congela jugador, NPCs y controles táctiles.
- **`Global.eventos_completados`**: contenido de un solo uso. Marcarlo AL LANZAR, no al terminar, o se
  repite si el jugador recarga a media escena.
- **Capítulos**: todo sale de `capitulos.json`; `capitulo_manager.gd` es el manager único de los 6
  niveles y lo único por escena es `numero_capitulo`. `Capitulo1Intro.tscn` es la pantalla negra
  genérica de TODOS los capítulos, no la del 1. Campos opcionales: `dialogo_laboratorio` (lo que pasa
  en `Laboratorio.tscn` antes de viajar a ese capítulo, una sola vez) y `escena_al_terminar` (a dónde
  lleva el "¡COMPLETADO!"; si falta, al laboratorio; el cap 6 lleva a `Epilogo.tscn`).
  Los años (1519, 1520, 1521, 1523, 1530, 1535) se quedan: son los que se teclean en la máquina.
- **Historia de los caps 3-6** (GDD): cap 3 y 4 el alux es **Chaac** (Kaan ya está en la celda desde
  el 2), cap 5 **Balaam** nunca aparece (solo visita la celda), cap 6 se encuentra a Balaam bajo la
  ceiba y huye → Atlas-Bird → epílogo. La "actividad 4" del GDD (interrogar NPC y "¡Te atrapé!") se
  cambió por solo explorar y hablar con los NPC.

## Contenido en JSON (se edita sin abrir Godot)

| Archivo | Qué define |
|---|---|
| `capitulos.json` | Los 6 capítulos: título, año, escena, diálogos inicial / final / del laboratorio, a dónde ir al terminar |
| `dialogos.json` | Toda la narrativa |
| `palabras.json`, `rompecabezas.json`, `burbujas.json`, `memorama_data.json` | Sus minijuegos |
| `atlasbird.json` | Atlas-Bird: reloj, vidas, curva de dificultad, pesos de objetos, avisos |

**NPC: burbuja vs. cuadro de diálogo.** La gente del nivel habla en burbuja (`burbujas.json`);
el cuadro grande (`dialogos.json`) es solo para aluxes, cierres de capítulo y quien lanza un
minijuego (Palabras impostoras: el `evento` solo existe en el cuadro). Un id de `burbujas.json`
puede ser un texto, una lista de textos, o `{"frases": [...], "respuestas": [{"texto", "contesta"}]}`:
tras las frases se abre `SelectorRespuestas.tscn` (aparte del cuadro de diálogo por la trampa 1).

**Greybox (caps 3-6).** `Scripts/greybox/`: `Bloque` (rectángulo con nombre), `NpcProvisional`
(sprite o silueta; `id_burbuja`/`id_dialogo` arman su zona solos; apoya los PIES visibles en el
origen) y `CinematicaProvisional` (atiende cualquier `cinematica_*` sin cinemática real con un
letrero; si el texto empieza con "[", p. ej. "[ MINIJUEGO PENDIENTE ]", ese es el encabezado).
El diálogo del laboratorio sale de `dialogo_laboratorio` en `capitulos.json`.

## Minijuegos

**Contrato**: la escena expone `nivel_a_cargar` (String) y la señal `juego_completado`; se registra en
`MINIJUEGOS` de `dialogo_manager.gd` y ya se lanza con `"evento": "minijuego_<clave>_<nivel>"`.

**Patrón `modo_libre`** (todos lo usan): `modo_libre = (get_parent() == get_tree().root)`. En true se
entró desde el Libro y hay botón de salir de vuelta a él; en false lo abrió un diálogo y el botón se
OCULTA — ahí cierra el diálogo al recibir `juego_completado`, y un salir dejaría saltarse contenido.
Ojo: el "Ir al Menú" del `MenuPausa` que instancia Memorama va al menú principal, no al libro.

- **Rompecabezas**: piezas por geometría (`Polygon2D` con UV), no recortes; cada borde se calcula una
  vez y lo comparten las dos vecinas. El tablero (`area_tablero`, 369x246) está al tope de lo que
  cabe: **ensancharlo se lo quita a las columnas laterales**, que es donde esperan las piezas sueltas,
  y se encimarían unas con otras. Las pestañas de las piezas del montón siempre invaden ~20 px del
  tablero; es así desde siempre y no se nota porque la guía va muy tenue. Imágenes **900x600 (3:2)** en
  `Images/img-rompecabezas/nivelN/nivN_1..3.jpg`. **Las imágenes NO se listan en `rompecabezas.json`**:
  se buscan por esa convención con `ResourceLoader.exists()` (no con `DirAccess`, que en el export no
  ve los originales), así que agregar una es copiar el archivo y abrir Godot una vez. Un nivel sin
  imágenes sale en la lista como "(pronto)" y deshabilitado, no desaparece.
  Qué imagen toca: desde un diálogo, la primera sin jugar (1, 2, 3...) y ya jugadas todas, una al
  azar; desde el Libro, la elige el jugador en `PanelImagenes`. Las dos cuentas van **separadas**
  (`eventos_completados["rompecabezas_<archivo>_historia" | "..._libro"]`) para que practicar en el
  libro no gaste la rotación de la historia. Se marca AL LANZAR (invariante de `eventos_completados`),
  por eso `Reiniciar` pasa `variante_actual`: si no, cada reinicio quemaría otra imagen.
  ⚠️ El pergamino de los botones tiene los bordes transparentes, así que lo pintado es más angosto
  que el botón y un título largo se sale del dibujo aunque "quepa": `_ajustar_texto_boton()` le baja
  la letra hasta `ANCHO_UTIL_BOTON`. Las miniaturas no usan ese pergamino (lo taparían entero): llevan
  un `StyleBoxFlat` propio.
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
  Se lanza desde `dialogo_kaan_1520` (final del cap 2) con `minijuego_topo_cap2`. Encima de un nivel
  le suelta el mouse al `LimitesCamara` mientras dura (trampa 3) y se lo devuelve al salir.
- **Rompecabezas sin imágenes desde un diálogo** (nivel 5): se cierra solo y el diálogo sigue, en
  vez de tronar sin textura. Por eso el cap 5 ya trae el evento aunque no haya imágenes.
- **Fuercitas** (`Scenes/Fuercitas.tscn`, cap 3, Atlas vs Chaac): **NO está en el Libro** a propósito,
  solo se abre desde `final_cap3`. Picar empuja; el botón "Contar un chisme" (secretos que contó Kaan en
  `laboratorio_cap3`) desconcentra a Chaac. Cada derrota le quita 20 % de fuerza. Solo escucha el clic
  de mouse (el toque llega convertido): escuchar también el toque contaría doble.
- **Epílogo** (`Scenes/Epilogo.tscn`): viñetas provisionales que describen el dibujo; cambian con
  `"evento": "cinematica_vineta_N"` en el diálogo `epilogo`. Al final marca
  `eventos_completados["juego_terminado"]` y ofrece volver al menú.

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

## Ventana y export

Base 640x360 con `stretch/mode = canvas_items` y aspecto `keep` (el de fábrica, por eso no aparece en
`project.godot`). `window_width/height_override = 1280x720` NO es solo del editor: también abre así el
juego exportado en escritorio. Al maximizar escala todo parejo (x2.75 a 1920x1080) sin deformar, con
franjas negras solo si la pantalla no es 16:9. ⚠️ El único preset de export es Android; para probar
todo esto fuera del editor hay que agregar uno de Windows.

## Cómo verificar sin poder jugar

`godot --headless --path . --script res://tmp.gd` con un `extends SceneTree`: cargar la escena compila
su script y delata nodos faltantes; añadiéndola al árbol y llamando métodos se prueba la lógica.
`--check-only --script` NO sirve si el script usa autoloads ("Identifier not found"): cargar la escena
sí. ⚠️ El proyecto vive en OneDrive y ha revertido archivos a media sesión: `git checkout -- <archivo>`.

## Pendientes

Viven en **`PENDIENTES.md`** (lista única, organizada por tema).
