# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project overview

"Los Aluxes que cambiaron la Historia" is a 2D narrative/educational Godot game (Spanish-language) about the fall of Tenochtitlan (1519) and Mexican history, mixing a story mode with several minigames. Built with **Godot 4.6** (GL Compatibility renderer, Jolt Physics). There is no separate build system, package manager, or test framework — everything is edited and run through the Godot editor/CLI.

## Commands

There's no npm/make/CI setup in this repo; use the Godot 4.6 editor or CLI directly.

- Run the game: open the project in Godot 4.6, or `godot4 --path .` (main scene is `Scenes/IntroStudio.tscn`, set in `project.godot`).
- Run a single scene for quick iteration: `godot4 --path . Scenes/<SceneName>.tscn`.
- Export (Android is the only configured preset, in `export_presets.cfg`): `godot4 --headless --export-release "Android" <output>.apk`.
- There are no automated tests; verification is manual, by running the relevant scene in-editor.

## Architecture

### Autoloads (global singletons, in `project.godot`)
- **`Global`** (`Scripts/global.gd`): the single source of truth for player/session state — selected character, sprite paths, current story progress (`progreso_historia`), `en_dialogo` flag (gates player movement/input during dialogue), and the save system. Saves are **not** per-file; all slots live in one JSON master file at `Saves/partidas.json` (`iniciar_nueva_partida`, `guardar_partida`, `cargar_partida`, `obtener_partidas`, max 5 slots, keyed by timestamp-generated slot IDs). `eventos_completados` is a dictionary used to gate one-shot content (e.g. dialogues already seen).
- **`SceneTransition`** (`Scripts/scene_transition.gd`): CanvasLayer providing a fade-to-black/fade-in `change_scene(target_path)` used instead of calling `get_tree().change_scene_to_file()` directly for any player-facing scene change.

### Dialogue system
Dialogue content lives entirely in `dialogos.json` (not in scenes/scripts) and is driven by `DialogoManager` (`Scripts/dialogo_manager.gd`, class_name `DialogoManager`), typically the `CuadroDialogo` node found via `find_child` in the current scene. Key points:
- Lines support `{nombre_jugador}` / `{anio_objetivo}` template substitution from `Global`.
- A line's `evento` field can trigger side effects: `minijuego_palabras_<nivel>` spawns the `PalabrasImpostoras` minigame scene as an overlay `CanvasLayer` and pauses the dialogue until `juego_completado` fires; `cinematica_*` emits `evento_cinematica` and expects something else (a manager script) to call `continuar_cinematica()` to resume.
- `ZonaDialogo` (`Scripts/zona_dialogo.gd`, an `Area2D`) is how the player triggers dialogue in the world: either automatically on entering the area or via an interaction prompt (`ui_accept`), looks up `CuadroDialogo` in the current scene, and marks itself completed in `Global.eventos_completados` when `un_solo_uso` is true.
- Debug logging for the dialogue/player systems writes to `user://debug_log.txt` via a repeated `debug_log()` helper (see `dialogo_manager.gd`, `player.gd`) — check this file when diagnosing dialogue/movement issues that don't show in the console.

### Player & world
`Player` (`Scripts/player.gd`, class_name `Player`) is a `CharacterBody2D` that loads its idle/walk spritesheets dynamically from `Global.ruta_spritesheet` / `Global.ruta_walk` (so the character customization screen only needs to update these two paths). Movement is disabled whenever `Global.en_dialogo` is true. `controles_tactiles.gd` provides on-screen touch input for mobile (the project has `pointing/emulate_touch_from_mouse` enabled for desktop testing).

### Minigames
Each minigame is a self-contained scene+script pair, data-driven from its own top-level JSON file, and is either launched standalone or spawned as an overlay from a dialogue `evento` (see above):
- **Palabras Impostoras** (`Scripts/palabras_impostoras.gd`, `Scenes/PalabrasImpostoras.tscn`) — word-correction minigame, data in `palabras.json` / `palabras.md`.
- **Memorama** (`Scripts/memorama_manager.gd`, `Scenes/Memorama.tscn`) — memory-match game, data in `memorama_data.json`.
- **Atlas-Bird** (`Scripts/atlas.gd`, `Scenes/Atlas.tscn` and `Scenes/Juegos/Atlas-Bird/…`) — a Flappy-Bird-style minigame; note there are duplicate copies of this minigame's assets/scenes under `Scenes/Atlas-Bird/` and `Scenes/Juegos/Atlas-Bird/` — check which one is actually referenced before editing.
- **SlidePuzzle** (`Scenes/SlidePuzzle/main_puzzle.gd`) — sliding tile puzzle.
- **Topo Alux** (`Scripts/topo_alux_manager.gd`, `topo_entidad.gd`) — whack-a-mole style game, world bubbles driven by `burbujas.json` / `Scripts/burbuja_mundo.gd`.

### Other notable scripts
- `laboratorio_manager.gd`, `tenoch_manager.gd`, `tenoch1520_manager.gd`, `cinematica_kaan.gd`, `capitulo1_intro.gd`, `prologo.gd` — per-scene story/cinematic controllers for each chapter location; these are the pieces that call `continuar_cinematica()` and generally advance `Global.progreso_historia`.
- `menu_principal.gd`, `menu_pausa.gd`, `menu_cargar.gd`, `creacion_personaje.gd`, `carta.gd`, `libro_historia.gd`, `iu_maquina.gd` — UI/menu flow, including the "Gran libro de historia" and new-game character-creation flow that ultimately calls `Global.iniciar_nueva_partida(...)`.

### Assets & data files
- Sprite assets are organized under `Images/Personajes/` (playable characters and NPCs) and `Images/Fondos/` (backgrounds); Godot's `.import` sidecar files are checked in alongside source images — don't edit these by hand.
- Content is intentionally kept in top-level JSON files rather than scene data so it can be edited independently of Godot: `dialogos.json`, `palabras.json`, `memorama_data.json`, `burbujas.json`.
- `resumen_cambios.md` is a running Spanish-language changelog of development sessions — check it for recent context on why something was built a certain way, but don't treat it as authoritative documentation (it's a raw dev log, encoding issues and all).
