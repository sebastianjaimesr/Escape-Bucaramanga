# Arquitectura

## Principios

- **Datos separados de la lógica**: niveles, misiones, diálogos y personajes viven en `data/` (JSON). El código los interpreta.
- **Escenas mínimas**: cada `.tscn` es un nodo raíz con su script; los nodos hijos se construyen en `_ready()`. Así las escenas no se rompen al editar a mano y todo se puede revisar como texto.
- **Autoloads solo para lo global**: `GameState`, `AudioManager`, `SaveSystem` y `SceneTransition`.
- **Jugador con máquina de estados**: un script por estado.

## Carpetas

```
scenes/menus      menú principal, victoria, derrota y final
scenes/levels     level_01..07.tscn (todas usan scripts/systems/level.gd con un level_id)
scenes/player     jugador
scenes/friends    amigo en el nivel y amigo seguidor
scenes/enemies    dron vigía, perro y dron patrulla (persecución)
scenes/obstacles  coleccionables, peligros, plataformas móviles, barreras, puntos de control, meta, carros, letreros
scenes/ui         HUD, pausa, diálogo y controles táctiles
scripts/player    player.gd, player_state_machine.gd y states/
scripts/enemies   enemy.gd (base), drone.gd, dog.gd, chase_patrol.gd
scripts/obstacles un script por obstáculo
scripts/friends   friend.gd, friend_follower.gd, trail_recorder.gd
scripts/systems   autoloads, level.gd, level_builder.gd, misiones, cámara, parallax, efectos
scripts/dialogue  dialogue_box.gd
scripts/ui        menús, HUD, tema visual
assets/           personajes, sprites, fondos, tileset, audio, interfaz
data/             levels/, dialogue/ (y misiones dentro de cada nivel)
tests/            test_runner.tscn (pruebas de integración en el motor)
tools/            generadores de arte, audio y niveles; validador
docs/             esta documentación
```

## Flujo de un nivel

1. `GameState.start_level(i)` reinicia salud y contadores, calcula qué amigos ya están en el grupo y llama a `SceneTransition.change_scene()`.
2. `Level._ready()` lee `data/levels/<id>.json` y:
   - crea el fondo con `ParallaxBuilder` (cielo, montañas, ciudad lejana y cercana con `Parallax2D`),
   - aplica `CanvasModulate` nocturno (las farolas, vitrinas y patrullas usan `PointLight2D`),
   - construye el `TileMapLayer` y las entidades con `LevelBuilder`,
   - instancia jugador, cámara, persecución, misiones, HUD, diálogo, pausa y controles táctiles.
3. La introducción se reproduce una sola vez (queda registrada en el guardado).
4. La persecución comienza tras un retraso (`mode: "delay"`) o al encontrar al amigo (`mode: "after_friend"`).
5. Al morir: se resta una vida y se reaparece en el punto de control; sin vidas se va a la pantalla de derrota.
6. En la meta: si faltan objetivos se avisa; si no, se guarda y se pasa a la pantalla de victoria o al final.

## Jugador

`Player` (CharacterBody2D) contiene la física (aceleración, fricción, gravedad más fuerte al caer, tiempo de coyote, búfer de salto, salto variable, invulnerabilidad). `PlayerStateMachine` alterna entre `Idle`, `Walk`, `Run`, `Jump`, `Fall`, `Hurt`, `Interact` y `Dead`, y cada estado elige su animación.

Constantes de diseño (en `scripts/player/player.gd`): caminar 112 px/s, correr 176 px/s, salto ≈ 62 px (≈ 4 tiles). Por eso los niveles respetan: subir ≤ 3 tiles, hueco ≤ 4 caminando y ≤ 6 corriendo.

## Persecución

`ChasePatrol` avanza desde la izquierda: `speed` sube con `accel` hasta `max_speed` (valores por nivel en el JSON). Si el jugador se aleja más de 520 px, el dron recorta distancia para mantener la tensión. Si llega a 10 px, el jugador pierde una vida y el dron vuelve 340 px atrás del punto de reaparición con la velocidad base.

## Agregar un nivel

1. En `tools/build_levels.py`, crea `def level_8():` con el `Map` y agrégalo a `LEVELS` con su título, temática, persecución, misión, diálogos y ayudas.
2. Ejecuta `py tools/build_levels.py` (genera el JSON y actualiza `levels.json`).
3. Crea `scenes/levels/level_08.tscn` copiando otro nivel y cambiando `level_id`.
4. Ejecuta `py tools/validate_project.py` y las pruebas.

## Cambiar personajes por arte definitivo

Los spritesheets están en `assets/characters/` con filas fijas de 32×32: idle (4), walk (6), run (6), jump (2), fall (2), hurt (2), interact (4). Reemplaza el PNG manteniendo esa cuadrícula y no hace falta tocar código. Los nombres visibles están en `data/dialogue/characters.json`.
