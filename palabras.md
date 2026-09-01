# Actividad 3: Palabras Impostoras (Nivel de Dificultad 2)

## 🎯 Objetivo General
El jugador deberá identificar en la narración de los hechos presentada los errores e incongruencias históricas (denominadas "palabras impostoras"), utilizando una interfaz interactiva simulada como un "detector de la verdad" provisto por Atlas.

---

## 🎨 1. Interfaz Visual y Paleta de Colores

Para mantener la neutralidad en el proceso de resolución y evitar frustraciones o dar pistas inmediatas (connotaciones directas de correcto/incorrecto), se establecen las siguientes reglas de diseño gráfico:

*   **Lienzo de Narración:** El texto de la historia se despliega sobre un pergamino digital antiguo integrado en la interfaz. El texto base utiliza tipografía legible en color blanco o gris claro.
*   **Color de Interacción (Dorado/Ámbar `#FFC107`):** Cuando el detector de la verdad se activa o selecciona con éxito una palabra impostora, el texto afectado cambia a un tono dorado brillante. Queda estrictamente prohibido el uso del color rojo para marcar los errores del jugador.
*   **El Detector de la Verdad:** El cursor del mouse o el indicador táctil se transforma en una mira holográfica circular de estética tecnológica (azul cian) que parpadea para indicar que el modo de escaneo está activo.

---

## 🔊 2. Mecánica del Escaneo Acústico (Efecto Contador Geiger)

El minijuego utiliza el sonido como la pista principal para que el jugador localice las anomalías en el pergamino:

1.  Cada palabra impostora oculta posee un área de detección basada en coordenadas bidimensionales en la pantalla.
2.  El sistema calcula constantemente la distancia entre la posición actual del detector (cursor) y el centro de la palabra impostora más cercana.
3.  **Comportamiento del Audio:** 
	*   **Distancia Lejana:** Emitirá un "bip" aislado y pausado (cada 1.5 segundos).
	*   **Aproximación:** Conforme el detector se acerque a los límites de la palabra, el intervalo entre los pitidos disminuirá de forma progresiva.
	*   **Contacto Directo:** Al posicionarse exactamente encima de la palabra impostora, el sonido se transformará en un pitido rápido, agudo y continuo.

---

## ⏱️ 3. Selección y Despliegue de Opciones Históricas

*   **Fijación (3 Segundos):** El jugador debe mantener la mira del detector inmóvil sobre la palabra impostora durante tres segundos consecutivos. Una barra de progreso circular u holográfica rodeará la mira para indicar la carga.
*   **Menú de Reemplazo:** Al completarse el tiempo, la palabra se iluminará en dorado y el flujo del juego se pausará para desplegar un menú horizontal con tres opciones en forma de cartas o tarjetas.
*   **Requisito Gráfico:** Cada una de las tres opciones presentará obligatoriamente una ilustración o sprite en formato Pixel Art HD acompañado de su respectivo nombre en la parte inferior.
*   **Regreso Silencioso:** Al seleccionar cualquiera de las tarjetas, la interfaz de opciones se cerrará y el texto modificado mostrará la nueva palabra seleccionada en color dorado. El juego no emitirá ninguna alerta visual o auditiva que indique si la elección fue correcta o incorrecta en ese momento.

### 🗂️ Configuraciones de Cartas para el Nivel 1 (Año 1519)

#### Caso 1: Error "Monopatín espacial"
*   **Opción A (Correcta):** Imagen de un Caballo 🐎 (Texto: "Caballo")
*   **Opción B (Distractor 1):** Imagen de un León 🦁 (Texto: "León")
*   **Opción C (Distractor 2):** Imagen de una Carreta de madera 🛒 (Texto: "Carreta")

#### Caso 2: Error "Rebanada de pizza de piña"
*   **Opción A (Correcta):** Imagen de Collares de cuentas de vidrio 📿 (Texto: "Cuentas de Vidrio")
*   **Opción B (Distractor 1):** Imagen de Monedas de oro puro 🪙 (Texto: "Monedas de Oro")
*   **Opción C (Distractor 2):** Imagen de Espadas de hierro ⚔️ (Texto: "Espadas de Hierro")

---

## 🤖 4. Lógica de Retroalimentación y Sistema de Ayuda

### El Botón "Analizar con Atlas"
Este botón solo se habilitará una vez que el jugador haya modificado por lo menos una de las palabras impostoras del texto actual.
*   Al presionarlo, Atlas realizará un escaneo general y ofrecerá una respuesta cuantitativa a través de un cuadro de diálogo: *"Análisis completado: X de Y anomalías han sido resueltas correctamente"*.
*   El juego no revelará bajo ninguna circunstancia cuáles opciones son las correctas y cuáles son los errores, obligando al jugador a reevaluar sus elecciones mediante la lógica histórica.

### Sistema de Comodines (Ayuda Directa)
*   Por cada intento fallido de análisis o validación, el jugador ganará el derecho de solicitar una ayuda directa a Atlas a través de un botón secundario.
*   Al activarse la ayuda, Atlas ejecutará una animación automática donde un haz de luz escanea el pergamino, selecciona directamente una de las palabras impostoras activas (o una mal corregida) y la reemplaza de forma permanente por su contraparte histórica real.

---

## 🏁 5. Cierre de la Actividad
La actividad se considerará exitosamente completada únicamente cuando todas las páginas de la narración en curso hayan sido corregidas y el análisis cuantitativo de Atlas alcance el puntaje perfecto (todas las combinaciones seleccionadas coincidan con las soluciones históricas reales). Al lograrse esto, se desbloqueará la transición para continuar con la exploración horizontal del escenario principal.
