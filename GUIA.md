# Guía de estudio: Escape de Bucaramanga

Guía para entender, explicar y sustentar el juego. Complementa el `README.md` (cómo jugar y ejecutar), `docs/ARQUITECTURA.md` y los comentarios en español de cada script.

---

## 1. ¿Qué es este proyecto?

Un **juego de plataformas 2D** en pixel art hecho con **Godot 4**. Sebas es confundido con un ladrón una noche en Bucaramanga: debe cruzar 7 niveles inspirados en la ciudad, reunir a sus tres amigos (Buitrago, Diaz y Gordo) y llegar al mirador, mientras un dron patrulla ficticio lo persigue.

Tiene: movimiento con física, enemigos, coleccionables (granizados), misiones por nivel, diálogos con retratos, persecución con barra de distancia, guardado de progreso, menús, opciones, controles de teclado, mando y pantalla táctil, y pruebas automáticas.

## 2. Lenguajes y tecnologías

| Tecnología | Para qué se usa |
|---|---|
| **Godot 4.4+** | Motor del juego (física, escenas, luces, audio, exportación). |
| **GDScript** | Lenguaje de toda la lógica del juego (`scripts/`). Se parece a Python y tiene tipos opcionales. |
| **Escenas `.tscn`** | Archivos de texto de Godot; aquí cada escena es un nodo raíz con su script. |
| **JSON** | Datos: niveles (mapa en texto), misiones, diálogos y personajes (`data/`). |
| **Python 3** (+ Pillow y NumPy) | Herramientas que **generan** el arte, el audio y los niveles, y validan el proyecto (`tools/`). |

## 3. Ideas de arquitectura (lo más importante para sustentar)

1. **Datos separados de la lógica.** Cada nivel es un JSON con un mapa de texto, por ejemplo `#` es suelo, `o` un granizado, `d` un dron y `F` el amigo. `LevelBuilder` lee ese mapa y crea las baldosas y los objetos. Para cambiar un nivel no se toca el código.
2. **Escenas mínimas, todo construido en código.** Las escenas solo tienen el nodo raíz con su script; los hijos (sprites, colisiones, luces) se crean en `_ready()`. Así todo se puede leer y revisar como texto.
3. **Autoloads (singletons) solo para lo global.** `GameState` (vidas, salud, progreso, controles), `AudioManager`, `SaveSystem` y `SceneTransition` existen durante todo el juego y cualquier escena los puede usar.
4. **Máquina de estados para el jugador.** Cada estado (`Idle`, `Walk`, `Run`, `Jump`, `Fall`, `Hurt`, `Interact`, `Dead`) es un script con `enter()`, `exit()` y `physics_update()`. El jugador solo está en uno a la vez.
5. **Señales para comunicar sin acoplar.** Por ejemplo, `GameState` emite `health_changed` y el HUD se actualiza solo; el jugador emite `died` y el nivel decide qué hacer.

## 4. Organización de carpetas

```
scripts/player     Player (física) + máquina de estados y un script por estado
scripts/systems    GameState, AudioManager, SaveSystem, SceneTransition (autoloads),
                   Level (nivel), LevelBuilder (mapa → escena), MissionSystem, cámara, efectos…
scripts/enemies    Enemy (base), Drone, Police, ChasePatrol (dron de la persecución)
scripts/obstacles  Coleccionables, peligros, barreras, plataformas, puntos de control, meta…
scripts/friends    Amigo en el nivel, amigo que sigue al jugador y el rastro que siguen
scripts/ui         HUD, menús, pausa, opciones, controles táctiles, tema visual
scripts/dialogue   Caja de diálogo
data/              levels/*.json, dialogue/dialogues.json, dialogue/characters.json
tests/             Pruebas en el motor y bot que recorre los niveles
tools/             Generadores de arte, audio y niveles (Python) y validador
```

## 5. Flujo de una partida

1. **Menú principal** → "Nueva partida" llama a `GameState.new_game()`.
2. `GameState.start_level(i)` reinicia salud y contadores, calcula qué amigos ya tiene, guarda y llama a `SceneTransition.change_scene()` (fundido a negro + título).
3. `Level._ready()` lee `data/levels/level_0X.json` y arma todo: fondo con parallax, baldosas, objetos, jugador, cámara, persecución, HUD, misiones, diálogo, pausa y controles táctiles.
4. Se muestra la **introducción** (solo la primera vez) y, tras unos segundos o al encontrar al amigo, arranca la **persecución**.
5. **Si el jugador muere**: pierde una vida y reaparece en el último punto de control; sin vidas → pantalla de derrota.
6. **En la meta**: si faltan objetivos la meta está roja y avisa qué falta; si están cumplidos, guarda el resultado y pasa a la pantalla de victoria (o al final en el nivel 7).

## 6. Conceptos de programación de juegos que debes dominar

**`_ready()`, `_process(delta)` y `_physics_process(delta)`.** `_ready` se ejecuta al entrar a la escena; `_process` en cada cuadro; `_physics_process` a ritmo fijo (60 veces por segundo). `delta` es el tiempo desde el cuadro anterior: multiplicar por `delta` hace que el movimiento sea igual en cualquier computador.

**`CharacterBody2D` y `move_and_slide()`.** El jugador calcula su `velocity` y `move_and_slide()` lo mueve resolviendo choques con el suelo y las paredes.

**Capas y máscaras de colisión.** Capa 1 = mundo (suelo, carros, barreras); capa 2 = jugador. Los enemigos y objetos son `Area2D` con máscara 2: solo detectan al jugador.

**Sensaciones de control ("game feel")** en `player.gd`:
- *Coyote time*: se puede saltar unos milisegundos después de salir de una plataforma.
- *Jump buffer*: si presionas saltar justo antes de tocar el suelo, el salto igual ocurre.
- *Salto variable*: soltar el botón corta la subida.
- Gravedad más fuerte al caer, invulnerabilidad con parpadeo tras un golpe, empuje hacia atrás.

**Pisar enemigos.** `Enemy._check_player_contact()`: si el jugador viene cayendo desde arriba y el enemigo se puede pisar (dron), rebota y lo derrota; si no (policía), recibe daño.

**Persecución.** `ChasePatrol` acelera con el tiempo hasta una velocidad máxima; si el jugador se aleja demasiado, recorta distancia para mantener la tensión; si llega a 10 px, el jugador pierde una vida. El HUD muestra la distancia con una barra de colores.

**Amigos que siguen al jugador.** `TrailRecorder` guarda las últimas posiciones del jugador y cada `FriendFollower` se ubica en una posición más antigua de ese rastro (por eso caminan "en fila").

**Guardado.** `SaveSystem` escribe un JSON en `user://save.json` con nivel, niveles desbloqueados, vidas, récords y opciones.

**Generación procedural de recursos.** Todo el arte y el audio salen de los scripts de `tools/` (dibujan píxel a píxel con Pillow y sintetizan ondas con NumPy). Por eso el proyecto no depende de recursos de terceros.

## 7. Cómo ejecutarlo y probarlo

```bash
godot --path .                                                 # jugar
godot --headless --path . res://tests/test_runner.tscn         # 14 pruebas de integración
godot --headless --path . --fixed-fps 60 res://tests/bot_runner.tscn   # el bot completa los 7 niveles
py tools/validate_project.py                                   # validación sin Godot
py tools/build_levels.py                                       # regenerar los niveles desde Python
```

## 8. Preguntas de sustentación (con respuesta)

1. **¿Por qué Godot y GDScript?** Es un motor libre y liviano, con física 2D, escenas y exportación a varias plataformas; GDScript está integrado y es fácil de leer.
2. **¿Cómo se construyen los niveles?** Cada nivel es un JSON con un mapa de texto. `LevelBuilder` recorre el mapa y crea baldosas (`TileMapLayer`) y objetos según cada símbolo. Los JSON se generan con `tools/build_levels.py`.
3. **¿Qué es una máquina de estados y por qué la usaste?** Un patrón donde el personaje está en un solo estado a la vez y cada estado tiene su lógica. Evita un `_physics_process` lleno de `if` y hace fácil agregar estados.
4. **¿Qué es un autoload?** Un nodo que Godot crea al iniciar y que vive todo el juego (como un Singleton). Se usa para lo que comparten todas las escenas: estado de la partida, audio, guardado y transiciones.
5. **¿Para qué sirven las señales?** Para que un objeto avise de algo sin saber quién lo escucha (patrón observador). Ejemplo: `GameState.health_changed` → el HUD redibuja los corazones.
6. **¿Por qué multiplicar por `delta`?** Para que el movimiento dependa del tiempo y no de cuántos cuadros por segundo dibuje cada computador.
7. **¿Qué son el *coyote time* y el *jump buffer*?** Márgenes de tiempo que perdonan pequeños errores del jugador al saltar; hacen que los controles se sientan justos.
8. **¿Cómo sabes que todos los niveles se pueden terminar?** Hay un bot (`tests/bot_runner.gd`) que juega cada nivel corriendo y saltando solo con la física real, y un validador en Python que analiza si la meta es alcanzable.
9. **¿Qué prueban las pruebas automáticas?** Movimiento, salto, colisiones, coleccionables, daño y reaparición, caída al vacío, persecución, misiones, amigos, guardado, transiciones y rendimiento (14 pruebas).
10. **¿Cómo funciona la reaparición?** Al tocar un punto de control se guarda su posición en `GameState`; al morir, `Level._on_player_died()` resta una vida y llama a `player.respawn()` en esa posición.

## 9. Retos para practicar (hazlos tú)

1. **Fácil:** cambia `JUMP_VELOCITY` en `player.gd`, juega y explica qué cambia. Luego vuelve al valor original.
2. **Medio:** haz que los corazones (`h` en el mapa) curen 2 en vez de 1. Pista: `collectible.gd`.
3. **Medio:** agrega una prueba en `tests/test_runner.gd` que compruebe que `GameState.add_life()` no pasa de `MAX_LIVES`.
4. **Avanzado:** crea un nivel 8 corto siguiendo "Agregar un nivel" en `docs/ARQUITECTURA.md`.

> **Nota:** `docs/ARQUITECTURA.md` y el `README.md` todavía hablan de un enemigo "perro", pero en el código ese enemigo es el **policía** (`scripts/enemies/police.gd`). Conviene actualizar esos documentos para que coincidan.
