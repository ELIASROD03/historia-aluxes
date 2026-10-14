# Pendientes

> Lista única de lo que falta. Al terminar algo, bórralo de aquí (y si dejó una decisión o trampa
> que valga la pena recordar, anótala en `resumen_cambios.md`).
> Última revisión: 14 de octubre de 2026.

## 1. Rompen el flujo del juego (lo más urgente)

- [ ] **Después del FIN no hay a dónde ir.** Al terminar el epílogo `progreso_historia` queda en 7
  (no hay capítulo 7): si el jugador da "Continuar", aparece en el laboratorio sin nada que hacer y la
  máquina pide el año "0000". Decidir qué pasa con una partida terminada (¿créditos? ¿rejugar
  capítulos desde el Libro? ¿bloquear "Continuar"?). Ya se marca `eventos_completados["juego_terminado"]`.

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
- [ ] **Topo Alux (cap 2)**: el GDD pide que, tras 3 derrotas seguidas, se pueda jugar como Atlas
  (apunta solo a los aluxes reales). No está hecho. Además, el sprite de Kaan disfrazado se queda
  parado en el nivel después de que "huye al bosque" (el capítulo termina enseguida, apenas se nota).
- [ ] **Memorama no maneja la victoria**: al juntar las parejas solo hace un `print`
  (`memorama_manager.gd`, ~línea 99).
- [ ] **Rompecabezas del nivel 5 sin imágenes** (opcional). Ya está preparado: copiar
  `niv5_1.jpg`, `niv5_2.jpg`… (900x600) a `Images/img-rompecabezas/nivel5/` y abrir Godot una vez.
  Mientras no haya, el diálogo lo salta solo. El nivel 6 solo tiene 1 imagen (los demás tienen 3).
- [ ] **Fuercitas**: probar el equilibrio con niños reales (exports en el inspector de
  `Scenes/Fuercitas.tscn`). Cambiar o agregar chismes ahí mismo (grupo *Chismes*).

## 3. Arte y recursos (pasar del greybox al juego real)

### Escenarios de los capítulos 3 a 6
Cada `Bloque` (rectángulo con nombre, nodos `Fondo` y `Suelo`) marca algo que hay que dibujar.
Reemplazarlo por el Sprite2D real en la misma posición y borrar el bloque.
- [ ] Cap 3 `CaidaTenochtitlan`: campamento español, lago de Texcoco + calzada, 2 bergantines,
  casas en ruinas, barricada, mercado de Tlatelolco, templo de Tlatelolco dañado.
- [ ] Cap 4 `PrimerosAniosVirreinato`: ruinas del Templo Mayor, casas en construcción (andamios),
  piedras del templo, traza con cuerdas, primera iglesia de adobe, casas de Cortés, tianguis, milpa, bosque.
- [ ] Cap 5 `ReformasOrganizacion`: calle trazada, Casa de la Audiencia, catedral en obra, cabildo
  indígena, escuela de San José de los Naturales, tianguis, salida de la ciudad.
- [ ] Cap 6 `InstauracionVirreinato`: calle adornada, arco de bienvenida, caballo del virrey,
  catedral primitiva, Casas Reales, Casa de Moneda, ceiba.
- [ ] Quitar los letreros de zona ("1 · LLEGADA"…) y los postes amarillos de las zonas invisibles
  (nodo `Marca`) cuando ya no hagan falta.

### Personajes sin sprite (hoy son siluetas de color)
- [ ] Cap 3: guerrero tlaxcalteca, mujer mexica, anciano mexica.
- [ ] Cap 4: Alonso García Bravo (alarife), cronista, fray Pedro de Gante.
- [ ] Cap 5: oidor, escribano, fray Juan de Zumárraga, alumnos (niños).
- [ ] Cap 6: pregonero, Antonio de Mendoza (virrey), Vasco de Quiroga, niña.
- [ ] Varios NPC reutilizan sprites del cap 1 (guerreros, soldados, mercaderes, Moctezuma como
  "noble indígena", el capitán de capa roja como Hernán Cortés): cambiarlos si se quiere variedad.
- [ ] **Retrato del jugador** (lo agrega el usuario): todos los diálogos, el selector de respuestas
  y el epílogo apuntan a `Personajes_Principales/Personaje1/personaje.png`, que no existe.
- [ ] **Cara del Doctor Juan Pérez** para el cuadro de diálogo (solo hay su sprite de cuerpo).
- [ ] **Kaan y Chaac en la celda** de `Laboratorio.tscn`: los diálogos del laboratorio de los caps
  3-6 hablan con ellos (Kaan desde el cap 3, Chaac desde el 5, ninguno después del 6).
- [ ] Tamaños: Chaac quedó igual que Kaan en Tenoch (47 px); Balaam en 50 px (el GDD dice que es el
  más alto). Los aluxes miden más que el protagonista (43 px): el GDD dice que son bajitos.

### Cinemáticas pendientes (hoy salen como letrero "[ CINEMÁTICA PENDIENTE ]")
Al hacer una real: quitar su entrada de `textos` del nodo `CinematicaProvisional` de la escena.
- [ ] Cap 3: `cinematica_escape_chaac` (portal rojo entre truenos).
- [ ] Cap 4: `cinematica_nubes_chaac` (el cielo se nubla y no llueve), `cinematica_rayo_chaac`
  (el rayo manda a volar a Atlas).
- [ ] Cap 5: `cinematica_portal_balaam` (Balaam visita la celda y se va).
- [ ] Cap 6: `cinematica_huida_balaam` (sale volando por portales), `cinematica_bosque_casita`
  (llegan al bosque con la casita).
- [ ] Laboratorio antes del cap 6: Kaan y Chaac le dan su poder a la máquina (hoy es una línea del
  Narrador en `laboratorio_cap6`, porque `Laboratorio.tscn` no atiende cinemáticas; para hacerla de
  verdad hay que agregarle un manejador de `evento_cinematica`).

### Epílogo (`Scenes/Epilogo.tscn`)
- [ ] Las 5 viñetas del cómic. Cada una describe en pantalla qué dibujar. Al tenerlas, poner la ruta
  en `"imagen"` de cada viñeta en `Scripts/epilogo.gd`.

### Audio
- [ ] No hay música ni efectos (solo el golpe de Topo Alux). Los canales `Musica` y `Efectos` ya
  existen y obedecen al panel de Configuración: a cada `AudioStreamPlayer` nuevo ponerle
  `bus = "Musica"` o `"Efectos"`. El GDD sugiere pistas concretas (págs. 24-25).

## 4. Configuración y accesibilidad

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
- [ ] Atajo de prueba para saltar a cualquier capítulo (para revisar el laboratorio y los diálogos
  de cada capítulo sin jugar todo).
- [ ] GDD, menús: botón de regresar arriba a la izquierda y configuración/ayuda arriba a la derecha
  en todos los menús; sonido de risa de alux al pulsar botones.

## 7. Limpieza

- [ ] **Nada de esta sesión está en commit** (configuración, guardado, greybox caps 3-6, Fuercitas,
  burbujas con respuestas, epílogo). Hacer commit al revisar.
- [ ] `Scenes/Tenoch.tscn` y `Scenes/MenuPrincipal.tscn` tienen cambios mínimos que no vienen de esta
  sesión (probablemente el editor los re-guardó): revisarlos antes del commit.
- [ ] `Saves/partidas.json` ya no se usa (las partidas viven en `user://partidas.json`; se migró
  desde el editor). Se puede borrar.
- [ ] Decidir si el `GDD ... .pdf` va al repositorio o se ignora.
