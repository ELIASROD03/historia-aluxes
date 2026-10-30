# Pendientes

> Lista única de lo que falta. Al terminar algo, bórralo de aquí (y si dejó una decisión o trampa
> que valga la pena recordar, anótala en `resumen_cambios.md`).
> Última revisión: 30 de octubre de 2026.

## 1. Rompen el flujo del juego (lo más urgente)

- [x] **Después del FIN: viaje libre.** Al terminar el epílogo se guarda la partida en el laboratorio; el panel
  final ofrece "Seguir viajando por la historia". Con `Global.juego_terminado()` la máquina acepta el año de
  cualquier capítulo (`Global.preparar_visita()` reinicia su contenido de una sola vez), Atlas lo explica en
  `laboratorio_viaje_libre` y al terminar un capítulo revisitado se vuelve al laboratorio sin tocar el progreso.

## 2. Minijuegos

- [ ] **La gran persecución** (cap 4, Chaac) — la hace el usuario. Para conectarla:
  1. En `final_cap4` (`dialogos.json`) cambiar `"evento": "cinematica_gran_persecucion"` por
     `"minijuego_persecucion_cap4"`.
  2. Registrar la escena en `MINIJUEGOS` de `dialogo_manager.gd` (`"minijuego_persecucion_": ...`).
  3. Quitar `cinematica_gran_persecucion` de `textos` en el nodo `CinematicaProvisional` de
     `PrimerosAniosVirreinato.tscn`.
  4. Seguir el contrato: `nivel_a_cargar` + señal `juego_completado` + patrón `modo_libre`.
  5. GDD: 3 vidas, mejoras de Atlas, hechizos del alux, velocidad creciente, 90 s, tras 3 derrotas
     jugar como Atlas con vidas infinitas.
- [x] **Topo Alux: martillo y splash.** En computadora el cursor es un martillo (`Images/Fondos/topo/martillo.png`)
  que golpea al hacer clic; en celular aparece donde se toca. Al acertar sale un estallido animado (`splash.png`).
- [ ] **Topo Alux (cap 2)**: el GDD pide que, tras 3 derrotas seguidas, se pueda jugar como Atlas
  (apunta solo a los aluxes reales). No está hecho. (Lo de Kaan parado ya se arregló: ahora corre al
  bosque con sus dobles —`cinematica_kaan_bosque`— y tras Topo Alux aparece dormido —`cinematica_kaan_dormido`.)
- [x] **Memorama**: al ganar muestra "¡Ganaste!" con "Jugar otra vez"; ya cumple el contrato de minijuegos
  (`juego_completado`), por si se quiere lanzar desde un diálogo.
- [ ] **Rompecabezas del nivel 5 sin imágenes** (opcional). Ya está preparado: copiar
  `niv5_1.jpg`, `niv5_2.jpg`… (900x600) a `Images/img-rompecabezas/nivel5/` y abrir Godot una vez.
  Mientras no haya, el diálogo lo salta solo. El nivel 6 solo tiene 1 imagen (los demás tienen 3).
- [ ] **Fuercitas**: probar el equilibrio con niños reales (exports en el inspector de
  `Scenes/Fuercitas.tscn`). Cambiar o agregar chismes ahí mismo (grupo *Chismes*).

## 2b. Libro de Historia
- [x] Enciclopedia con desbloqueos por dispositivo (`LibroProgreso`, `user://libro.cfg`): minijuegos con candado
  hasta conocerlos (Memorama siempre abierto, Fuercitas fuera), contador de Palabras Impostoras (N/30) y de
  Rompecabezas (N/6), capítulos grises con candado que al completarse muestran resumen y personajes con su sprite.
- [ ] **Revisar los textos del libro** (`libro_historia.json`): resúmenes, descripciones de personajes y de
  minijuegos son borradores.
- [ ] Topo Alux y Atlas-Bird desde el libro: confirmar que se juegan bien en modo libre de principio a fin.

## 3. Arte y recursos (pasar del greybox al juego real)

### Capítulo 2 (Noche Triste)
- [x] `Tenoch1520.tscn` rehecho: ya no es el cap 1 de noche. Fondo nocturno con luna, calzada de Tacuba con el
  canal cortado y puente roto, canoas mexicas, oro tirado, antorchas con luz (`Scripts/luz_parpadeo.gd`), linterna
  del jugador (`PointLight2D` hijo de `Player` solo en esta escena), ahuehuete con Cortés y el bosque donde huye
  Kaan. Se quitaron Moctezuma (ya había muerto), el encuentro Cortés-Moctezuma del cap 1 y el tianguis.
  Respaldo de la versión anterior en git.

### Escenarios de los capítulos 3 a 6
Cada `Bloque` (rectángulo con nombre, nodos `Fondo` y `Suelo`) marca algo que hay que dibujar.
Reemplazarlo por el Sprite2D real en la misma posición y borrar el bloque.
- [x] Cap 3 `CaidaTenochtitlan`: arte de PixelLab en `Images/Escenarios/cap3/` (campamento, bergantín,
  ruinas, mercado, templo, barricada, calzada), agua animada (`WaterRepeater`), volcanes y 3 capas de
  árboles en parallax, árboles/pasto con viento (`Shaders/balanceo_viento.gdshader`), objetos de
  `objetos_level1`/`Decor`, fogata, humo y bandera animados, garzas y canoa que van y vienen (`Scripts/vaiven.gd`).
  Los volcanes usan `Escenarios/cap3/volcanes_espejo.png` (recorte + su espejo) para que no se note la unión.
- Para los caps 4-6: fondo lejano de UNA imagen de 640x360 (o un poco más) con parallax muy leve como
  en `Tenoch.tscn`, más capas de árboles, árboles, objetos y cosas animadas como en el cap 3.
- [x] Cap 4 `PrimerosAniosVirreinato`: arte en `Images/Escenarios/cap4/` (fondo del valle 640x360, ruinas del
  Templo Mayor, 2 obras con andamios, piedras, iglesia de adobe, casas de Cortés, milpa, traza), tianguis con los
  puestos de `objetos_level1`, bosque de `Tree1`, gallinas, cerdo, garzas, fogata, humo y banderas.
  Escala como en el cap 1: edificios y `Decor` al 1.5x, NPCs ~60 px.
- [x] Cap 5 `ReformasOrganizacion`: arte en `Images/Escenarios/cap5/` (fondo de la ciudad 688x384, casas de piedra,
  Casa de la Audiencia, catedral en obra, cabildo indígena, escuela de San José, salida), tianguis con puestos de
  `objetos_level1`, xoloitzcuintle, gallinas, garzas, fogata y banderas.
- [x] Cap 6 `InstauracionVirreinato`: arte en `Images/Escenarios/cap6/` (fondo de tarde 688x384, calle adornada,
  arco de bienvenida, caballo del virrey animado, catedral primitiva, Casas Reales, Casa de Moneda, ceiba),
  banderines y banderas ondeando, xoloitzcuintle, gallinas, garzas y fogata.
- [x] **Hierbas en primer plano** en los 6 niveles (`Scenes/HierbasFrente.tscn`): `Parallax2D` con `scroll_scale` 1.3
  (se mueve más rápido que el jugador), textura de 640x360 repetida en espejo (`Images/Escenarios/comun/
  hierbas_frente.png`; la original está en `hierbas_frente_640.png`) y viento con `Shaders/hierbas_frente.gdshader`.
  Cada nivel le da su tono con `modulate` (noche azul en el cap 2, tarde cálida en el cap 6). Altura: `position.y`
  del nodo `Hierbas` (hoy 50; más grande = más abajo).
- [x] Se quitaron los letreros de zona ("1 · LLEGADA"…) y los postes `Marca` de los caps 3-6.

### Personajes sin sprite (hoy son siluetas de color)
- [x] Cap 3: guerrero tlaxcalteca, mujer mexica, anciano mexica (`Images/Personajes/Npc_cap3/`, idle de 4 cuadros).
- [x] Cap 4: Alonso García Bravo (alarife), cronista, fray Pedro de Gante (`Images/Personajes/Npc_cap4/`).
- [x] Cap 5: oidor, escribano (animación escribiendo), fray Juan de Zumárraga, alumnos (`Images/Personajes/Npc_cap5/`).
- [x] Cap 6: pregonero (animación pregonando), Antonio de Mendoza, Vasco de Quiroga, niña (`Images/Personajes/Npc_cap6/`).
- [x] **NPC propios por capítulo** (en vez de los sprites del cap 1). PixelLab v3, 80 px, vista lateral, respirar
  en SE (4 cuadros), `escala` ~0.78 para medir ~60 px. ~3 generaciones cada uno.
  - [x] Cap 4: Hernán Cortés (gobernador, sin armadura), trabajador, tameme cargando piedra, alabardero,
    mujer del tianguis, vendedor de maíz (`Images/Personajes/Npc_cap4/`).
  - [x] Cap 3: ballestero del bergantín, guerrero veterano (Palabras Impostoras), guerrero águila, defensor con
    lanza y defensor arquero (`Npc_cap3/`).
  - [x] Cap 5: vecino español, gobernador indígena con vara de mando, vendedora de tortillas, comprador (`Npc_cap5/`).
  - [x] Cap 6: escolta del virrey, público con guirnalda, noble indígena (ya no es Moctezuma), acuñador (`Npc_cap6/`).
  Ya ningún NPC de los caps 3-6 usa sprites del cap 1.
- [x] **Retrato del jugador**: cada personaje tiene `retrato.png` en su carpeta. Los diálogos siguen usando la ruta
  genérica `Personaje1/personaje.png` (`Global.RETRATO_JUGADOR_GENERICO`) y `DialogoManager`, el selector de
  respuestas y el epílogo la cambian por la del personaje elegido (`Global.ruta_retrato_jugador()`).
- [x] **Cara del Doctor Juan Pérez** (`Images/Personajes/doctor/doctor_cara.png`), en diálogos y epílogo.
- [x] **Kaan y Chaac en la "zona de resguardo"** (en vez de una celda con rejas): una dimensión de bolsillo
  tipo "zona fantasma" que se ve desde la computadora del laboratorio (nodo `Computadora`,
  `Scripts/computadora_zona.gd` → `Scenes/ZonaAluxes.tscn`, arte en `Images/Fondos/zona_aluxes/`). Kaan en
  los caps 3-4, Kaan y Chaac en los 5-6, vacía al terminar el juego. Los diálogos siguen diciendo "celda".
- [x] **Fondo de Fuercitas** más sencillo (cielo de tormenta y la pirámide a lo lejos). El anterior quedó en
  `Images/Fondos/fuercitas/fondo_anterior.png`.
- [x] Tamaños: los aluxes miden ~40 px, un poco menos que el jugador (44 px). Chaac y Balaam con `escala` 0.625;
  Kaan se encoge a 0.85 al quitarse el disfraz (`escala_alux` en `cinematica_kaan.gd`; el disfraz de soldado
  sigue a tamaño humano).

### Cinemáticas y epílogo
- [x] Cinemáticas de los aluxes. Animadas en el nivel (`Scripts/cinematicas_aluxes.gd`, nodo `CinematicasAluxes`):
  escape de Chaac por un portal rojo entre rayos (cap 3), nubes de tormenta que se van sin llover y el rayo que
  manda a volar a Atlas (cap 4), Balaam escapando por sus portales (cap 6). Ilustradas a pantalla completa detrás
  del diálogo (`imagenes` de `CinematicaProvisional`, en `Images/Cinematica/aluxes/`): Balaam en la celda (cap 5),
  la casita del bosque (cap 6) y Kaan y Chaac dándole su poder a la máquina (`laboratorio_cap6`, evento
  `cinematica_poder_maquina`; el laboratorio ahora tiene su `CinematicaProvisional`).
- [x] Las 5 viñetas del epílogo (`Images/Cinematica/epilogo/`, la 1 reusa la casita), a pantalla completa. El
  jugador sale de espaldas porque puede ser cualquiera de los 6 personajes.

### Audio
- [ ] No hay música ni efectos (solo el golpe de Topo Alux). Los canales `Musica` y `Efectos` ya
  existen y obedecen al panel de Configuración: a cada `AudioStreamPlayer` nuevo ponerle
  `bus = "Musica"` o `"Efectos"`. El GDD sugiere pistas concretas (págs. 24-25).

## 4. Configuración y accesibilidad

- [x] Panel rehecho con arte de PixelLab (`assets/configuracion/`): marco de madera, barras de jade, interruptores,
  íconos por sección. Se quitó "Borrar todas" (las partidas se borran una por una en Cargar partida).

- [ ] **Velocidad del texto** (lenta / normal / instantánea): requiere efecto máquina de escribir en
  `dialogo_manager.gd`.
- [ ] **Tamaño del texto** de los diálogos.
- [ ] El GDD pide además opciones de colores y, de ser posible, voces en los diálogos.
- [ ] Agregar un preset de export **Windows** para probar fuera del editor (solo hay Android).

## 5. Revisión de contenido (del usuario)

- [ ] **Todos los diálogos de los caps 3-6, del laboratorio y del epílogo son borradores** escritos a
  partir de las sinopsis del GDD: revisar tono, datos históricos y extensión. Están en
  `dialogos.json` (`laboratorio_capN`, `inicio_capN`, `final_capN`, `interludio_balaam_cap5`,
  `epilogo`) y `burbujas.json` (`npc_*_capN`, con sus respuestas).
- [ ] Palabras Impostoras de los caps 3-6: se cambió el alux culpable (Kaan → Chaac/Balaam), revisar
  que el resto del texto cuadre con cada capítulo.
- [ ] Las respuestas del jugador a los NPC se perdieron como diálogo (hoy van en el selector de
  respuestas de la burbuja): revisar que no falte ninguna pista importante.

## 6. Ideas para después

- [ ] Conversaciones con más de un nivel (una respuesta que lleve a otra pregunta).
- [x] **Modo desarrollador** (Configuración → tocar 5 veces el título "Configuración"): libro completo sin tocar
  `libro.cfg`, botón "Saltar minijuego >>" en los minijuegos de la historia y la máquina del tiempo acepta el
  año de cualquier capítulo. Para que la sección se vea siempre: `revelar_con_toques = false` en
  `panel_configuracion.gd`.
- [ ] GDD, menús: botón de regresar arriba a la izquierda y configuración/ayuda arriba a la derecha
  en todos los menús; sonido de risa de alux al pulsar botones.

## 7. Limpieza

- [ ] **Sin commit**: viaje libre después del FIN, martillo/splash de Topo Alux, victoria del Memorama,
  cinemáticas de los aluxes, viñetas del epílogo, retratos del jugador y del doctor (desde `187635b`).
- [ ] `Saves/partidas.json` ya no se usa (las partidas viven en `user://partidas.json`; se migró
  desde el editor). Se puede borrar.
