# Auditoría inicial — Escape de Bucaramanga

Fecha: 3 de noviembre de 2026
Rama auditada: `main` (commit `eae168d`) y `gh-pages` (commit `eb29ba2`)
Alcance: todos los archivos del repositorio (51 scripts GDScript, 33 escenas, 5 herramientas Python, 63 imágenes, 22 audios, datos JSON y documentación), más los archivos subidos al proyecto.

Todo lo que dice "comprobado" se ejecutó durante esta auditoría con **Godot 4.7.2 estable (Linux, modo headless)**. Lo que no se pudo comprobar se marca como tal.

---

## 1. Resumen

El juego actual es un **plataformas 2D de desplazamiento lateral** hecho en **Godot 4 con GDScript**, con 7 niveles, arte pixel y audio chiptune generados por scripts propios. Está bien organizado, funciona y tiene pruebas automáticas que pasan.

No es posible "convertirlo" a 3D modificando lo existente: la jugabilidad, la cámara, los niveles (mapas ASCII), el arte (sprites de 32×32) y la física (2D) son específicos de un juego de plataformas lateral. Lo que **sí se conserva** es el motor, el lenguaje, la organización por sistemas, los datos de historia y personajes, el sistema de pruebas y el flujo de publicación.

**Recomendación: seguir en Godot 4.7 y construir el juego 3D como un proyecto nuevo dentro del mismo repositorio**, conservando la versión 2D intacta y jugable (ver sección 8).

---

## 2. Arquitectura actual

| Aspecto | Estado comprobado |
|---|---|
| Motor | Godot 4 (`config/features = "4.4"`), probado con 4.7.2 |
| Lenguaje | GDScript con tipado estático en la mayoría de funciones |
| Renderizador | Compatibilidad (OpenGL 3 / WebGL 2) en todas las plataformas |
| Resolución base | 960×540, estiramiento `canvas_items`, filtro de texturas "nearest" (pixel art) |
| Física | 2D de Godot, 60 ticks/s, gravedad 900 |
| Autoloads | `GameState`, `AudioManager`, `SaveSystem`, `SceneTransition` |
| Escenas | Mínimas: cada `.tscn` es un nodo raíz con script; los hijos se crean por código en `_ready()` |
| Datos | `data/levels/*.json` (mapa ASCII + misión + persecución + diálogos), `data/dialogue/dialogues.json`, `data/dialogue/characters.json` |
| Contenido generado | `tools/generate_art.py` (1.248 líneas, Pillow), `tools/generate_audio.py` (numpy), `tools/build_levels.py` |
| Exportación | `export_presets.cfg` con "Web" (sin hilos) y "Windows Desktop" |
| Publicación | Rama `gh-pages` con la exportación web (`index.html`, `index.wasm`, `index.pck`, `.nojekyll`) |

### Módulos

```
scripts/systems   game_state, save_system, audio_manager, scene_transition,
                  level, level_builder, parallax_builder, mission_system,
                  camera_controller, effects, sprite_factory, patrol_lights
scripts/player    player.gd (física) + player_state_machine.gd + 8 estados
scripts/enemies   enemy.gd (base), drone.gd, police.gd, chase_patrol.gd
scripts/friends   friend.gd (NPC a rescatar), friend_follower.gd, trail_recorder.gd
scripts/obstacles 8 obstáculos (coleccionable, peligro, plataforma móvil, barrera, ...)
scripts/ui        main_menu, hud, pause_menu, options_panel, result_screen, touch_controls, ...
scripts/dialogue  dialogue_box.gd
tests/            test_runner, bot_runner, flow_check, screenshots
```

---

## 3. Funcionalidades existentes (comprobadas)

| Funcionalidad | Cómo se comprobó |
|---|---|
| 14 pruebas de integración: datos, construcción de los 7 niveles, movimiento, salto, colisiones, coleccionables, vida extra, daño y reaparición, caída al vacío, persecución, misión que bloquea la meta, amigo que se une, guardado, transiciones, rendimiento | `godot --headless res://tests/test_runner.tscn` → **14 OK, 0 fallos** |
| Los 7 niveles se pueden completar con la física real | `tests/bot_runner.tscn` → **7 de 7** (17,3 s; 15,1; 14,4; 11,9; 15,8; 31,8; 16,1) |
| Referencias entre escenas, scripts, datos y recursos | `tools/validate_project.py` → **0 errores, 0 avisos** |
| Jugador con máquina de estados (idle, walk, run, jump, fall, hurt, interact, dead), tiempo de coyote, búfer de salto, salto variable | Lectura de código + pruebas |
| Persecución con dron patrulla y barra de distancia | Lectura de código + prueba `test_chase_catches_player` |
| Misiones por nivel (llegar a la meta, granizados, pistas, amigo) | `mission_system.gd` + prueba |
| Tres amigos que se unen y siguen al jugador | `friend_follower.gd` + prueba |
| Diálogos en español con retratos; nombres configurables en `characters.json` (Sebas, Buitrago, Diaz, Gordo) | Lectura de datos |
| Menú, selección de nivel, opciones (música, efectos, lluvia, pantalla completa), pausa, derrota, victoria, final | Lectura de código |
| Controles de teclado, mando y táctiles | `game_state.gd::_setup_input`, `touch_controls.gd` |
| Guardado en `user://save.json` | Prueba `test_save_and_load` |

**No comprobado en esta auditoría:** la versión publicada en `https://sebastianjaimesr.github.io/Escape-Bucaramanga/` (el proxy de red de este entorno bloquea `github.io`; se revisó el contenido de la rama `gh-pages` en su lugar), controles táctiles en un teléfono real, exportación de Windows.

---

## 4. Problemas detectados

### Errores y deuda técnica

| # | Problema | Dónde | Impacto |
|---|---|---|---|
| P1 | Documentación desactualizada: README, `docs/ARQUITECTURA.md`, `docs/ESTADO.md` y `docs/RECURSOS.md` siguen hablando de "perros", `dog.gd` y "palmeras", que ya fueron reemplazados por el policía y los árboles. `docs/PUBLICACION.md` y el README dicen que el juego "no se ha publicado", pero está en `gh-pages`. | `README.md`, `docs/*.md` | Confusión |
| P2 | Los archivos de personajes conservan los nombres viejos (`friend_gorra`, `friend_rulos`, `friend_gafas`) mientras el juego muestra Buitrago, Diaz y Gordo. | `assets/characters/`, `characters.json` | Confusión al mantener |
| P3 | Guardado de un solo espacio, sin comprobación de integridad ni copia de respaldo. Se escribe directamente sobre el archivo: si el juego se cierra durante la escritura, el guardado puede quedar dañado. Si el JSON está dañado se ignora y la siguiente partida lo sobrescribe sin avisar. El campo `version` existe pero no se usa para migraciones. | `save_system.gd` | Pérdida de progreso |
| P4 | Controles fijos en código; no se pueden reasignar. | `game_state.gd::_setup_input` | Falta de accesibilidad |
| P5 | La "prueba de rendimiento" mide 16,6 ms por cuadro porque el motor está limitado a 60 FPS en modo headless: mide el límite, no el rendimiento real. | `tests/test_runner.gd` | Resultado engañoso |
| P6 | Al terminar las pruebas Godot informa objetos y recursos no liberados (4 y 2 en `test_runner`; 27 y 6 en `bot_runner`). Es probable que se deba a cómo las pruebas cambian de escena, no al juego, pero no se ha confirmado. | `tests/` | Menor |
| P7 | `GameState.friends_before()` vuelve a leer y analizar el JSON de cada nivel anterior cada vez que empieza un nivel. | `game_state.gd` | Menor (rendimiento) |
| P8 | `add_granizado()` da la vida extra cuando el contador es múltiplo exacto de 25; si algún día se suma más de 1 a la vez, puede saltarse el umbral. | `game_state.gd` | Menor |
| P9 | La rama `docs/comentarios` (comentarios en español en los scripts y `GUIA.md`) no está integrada en `main` y se separó antes de los dos últimos cambios (nivel 2 y nivel 5). | Git | Trabajo sin integrar |

### Limitaciones de diseño frente a la visión 3D

| Sistema actual | Limitación |
|---|---|
| Amigos | Solo repiten el rastro del jugador con retraso. No tienen IA, ni navegación, ni estados. |
| Persecución | El dron conoce siempre la posición del jugador y, si este se aleja más de 520 px, el dron se teletransporta para mantener la tensión. El nuevo diseño prohíbe exactamente esto (la policía no debe saber dónde estás si te perdió de vista). |
| Policía a pie | Patrulla de un lado a otro en un tramo fijo; no ve, no persigue, no busca. |
| Niveles | Mapas ASCII lineales de izquierda a derecha. No sirven para un mundo semiabierto. |
| Vehículos | Los carros son obstáculos estáticos y la moto es una plataforma móvil. No hay conducción. |
| Inventario, dinero, mapa, diario | No existen. |
| Ciclo día/noche | No existe; los niveles son siempre de noche. |

---

## 5. Limitaciones técnicas a tener en cuenta

1. **Godot en navegador solo usa el renderizador de Compatibilidad (WebGL 2).** No tiene SSAO, SSR, SDFGI ni niebla volumétrica. Sí tiene luces y sombras dinámicas, materiales PBR, niebla por distancia, brillo (glow), partículas y shaders propios. La versión de PC puede usar Forward+ (Vulkan/D3D12) con todos los efectos. Godot 4.7.2 permite elegir un renderizador distinto para web (`rendering/renderer/rendering_method.web`, comprobado en el binario).
2. **Tamaño de la versión web.** El motor (`index.wasm`) pesa 39,5 MB; comprimido con gzip son 10,1 MB (medido). Es un costo fijo de Godot que se puede reducir compilando una plantilla web propia sin los módulos que no se usen.
3. **Hilos en web.** La exportación actual es sin hilos, lo que funciona en GitHub Pages (que no permite configurar las cabeceras COOP/COEP). Hay que mantenerlo así.
4. **Este entorno de desarrollo no tiene tarjeta gráfica.** Puedo ejecutar la lógica, la física, la IA y las pruebas en modo headless, y tomar capturas con renderizado por software, pero **no puedo medir FPS reales**. Las mediciones de rendimiento tendrán que hacerse en tu PC (el juego incluirá un medidor y un modo de prueba que guarda los resultados).
5. **Horneado de iluminación (LightmapGI) requiere GPU.** Sin GPU aquí, la iluminación global horneada se tendría que hacer en tu PC, o reemplazarse por oclusión ambiental horneada en las texturas con Blender (que sí funciona por CPU).
6. **Recursos 3D.** No hay ningún modelo 3D, animación esqueletal ni textura PBR en el proyecto. Todo el arte actual es pixel art 2D.

---

## 6. Recursos reutilizables

| Recurso | ¿Se reutiliza? | Cómo |
|---|---|---|
| Motor Godot, GDScript, `export_presets.cfg` | **Sí** | Base del proyecto 3D; los presets se ajustan a 3D |
| Patrón de autoloads (`GameState`, `AudioManager`, `SaveSystem`, `SceneTransition`) | **Sí, reescritos** | Misma idea, ampliada (espacios de guardado, integridad, configuración, controles) |
| Máquina de estados del jugador | **Sí, el patrón** | Mismo diseño de "un script por estado", con física 3D |
| Sistema de misiones basado en datos JSON | **Sí, ampliado** | Misiones con estados, condiciones de inicio y fin, recompensas |
| Diálogos y personajes en JSON (`characters.json`, `dialogues.json`) | **Sí** | Nombres configurables y textos de la historia como punto de partida |
| Historia (Sebas confundido con un ladrón, los tres amigos, aclarar todo) | **Sí** | Base narrativa de la campaña 3D |
| Pruebas headless y bot de recorrido | **Sí, el enfoque** | Nuevas pruebas para física, IA, misiones y guardado en 3D |
| `tools/validate_project.py` | **Sí, adaptado** | Validación de referencias y datos |
| Efectos de sonido (`assets/audio/sfx`, 404 KB) | **Parcial** | Interfaz y alertas sirven; pasos, vehículos y ambiente hay que conseguirlos |
| Música chiptune (`assets/audio/music`, 6,9 MB) | **No** | No encaja con un estilo realista; se puede usar en la versión 2D clásica |
| Sprites, fondos, tileset (2D pixel art) | **No** | No sirven como modelos 3D (regla 4 del encargo). Se quedan en la versión 2D |
| Archivos subidos al proyecto (15 imágenes) | **No** | Son recortes de capturas del juego 2D. **No hay fotografías de referencia** de Sebastián ni de los amigos |

---

## 7. Evaluación de motores

Criterios del encargo, con puntuación de 1 (malo) a 5 (muy bueno) para este proyecto concreto.

| Criterio | Godot 4.7 | Three.js + TS + Rapier + Vite | Unity 6 |
|---|---|---|---|
| Aprovecha lo existente | **5** — mismo motor, lenguaje, datos, pruebas y publicación | 1 — reescritura total en otro lenguaje | 1 — reescritura total en C# |
| Exportación PC | **5** — `.exe` nativo con Forward+ | 3 — requiere Electron o Tauri (navegador empaquetado) | **5** |
| Exportación web | 3 — funciona, pero motor de ~10 MB comprimido y solo WebGL 2 | **5** — es nativo de la web, motor de ~1 MB | 2 — builds pesados, carga lenta, soporte móvil limitado |
| Física 3D | **5** — Jolt integrado (comprobado en el binario) | 4 — Rapier es bueno, pero toda la integración es manual | **5** |
| Navegación de NPC | **5** — NavigationServer3D, NavigationAgent3D con evitación incluidos | 2 — hay que integrar `recast-navigation-js` y escribir la evitación | **5** |
| Animación | **5** — AnimationTree, máquinas de estado, mezcla, retargeting de humanoides | 3 — `AnimationMixer` de Three.js, sin máquinas de estado | **5** |
| Vehículos | 4 — `VehicleBody3D` o vehículo por rayos propio | 3 — controlador de vehículo de Rapier | 4 |
| Editor de escenas / niveles | **5** | 1 — no hay editor; todo por código | **5** |
| Calidad gráfica en PC | 4 | 3 | **5** |
| Calidad gráfica en web | 3 | 4 | 3 |
| Pruebas automáticas sin GPU en este entorno | **5** — ya funcionan (comprobado) | 4 — Node + Playwright | 1 — requiere licencia y editor; no ejecutable aquí |
| Mantenibilidad / dependencias | **5** — un solo binario, código abierto (MIT) | 3 — muchas librerías npm que actualizar | 3 — licencia y versiones del editor |
| **Total** | **54** | **36** | **44** |

### Decisión: **Godot 4.7 (GDScript), un solo motor para PC y web**

Razones:

1. El proyecto **ya está en Godot**, con pruebas, publicación y herramientas que funcionan. Cambiar de motor es reescribir todo sin ganar nada en lo que más pesa: navegación de NPC, animación, física y edición de niveles, que Godot trae incluidos.
2. **Un solo código para PC y navegador.** La versión de PC usa Forward+ con efectos avanzados; la web usa Compatibilidad con los mismos sistemas y escenas, cambiando solo la calidad gráfica.
3. Three.js gana en peso de descarga y en efectos dentro del navegador, pero obliga a construir a mano el editor, la navegación, la máquina de animaciones y el empaquetado de PC. Es la opción con más riesgo de terminar con sistemas incompletos.
4. Unity da muy buena calidad en PC, pero su versión web es la más pesada, requiere licencia y no se puede compilar ni probar en este entorno.

**Cómo se mantiene la versión web:** el renderizador web se fija en Compatibilidad; los materiales y la iluminación se diseñan primero para que se vean bien en web, y la versión de PC añade SSAO, SSR, niebla volumétrica e iluminación global encima. Cada fase se prueba en las dos (ver `PLAN_DE_DESARROLLO.md`).

---

## 8. Arquitectura recomendada (resumen)

El detalle está en `DOCUMENTACION/ARQUITECTURA.md`.

- Proyecto Godot 3D nuevo en la **raíz del repositorio**.
- La versión 2D actual se mueve **sin cambios** a `clasico-2d/` con `git mv` (se conserva el historial). Sigue siendo un proyecto Godot completo, con sus pruebas, y se puede seguir publicando como "versión clásica".
- Código organizado por sistemas en `src/` (personajes, cámara, física, IA, vehículos, misiones, inventario, interfaz, audio, guardado, mundo, configuración).
- Mundo por **zonas** (escenas independientes que se cargan y descargan) para ampliar Bucaramanga sin rehacer lo anterior.
- Datos (misiones, diálogos, personajes, objetos, zonas) en JSON, como ahora.

---

## 9. Plan de migración (resumen)

El detalle por fases está en `DOCUMENTACION/PLAN_DE_DESARROLLO.md`.

1. Trabajar en la rama `desarrollo-3d`. `main` y `gh-pages` no se tocan hasta que la versión 3D esté verificada.
2. Mover el 2D a `clasico-2d/` y comprobar que sus 14 pruebas y el bot siguen pasando desde ahí.
3. Crear el proyecto 3D en la raíz y construirlo por fases.
4. Publicar versiones de prueba del 3D en `https://sebastianjaimesr.github.io/Escape-Bucaramanga/beta-3d/` **sin tocar la raíz**, que sigue mostrando el 2D.
5. Cuando la vertical slice esté verificada y la apruebes, el 3D pasa a la raíz y el 2D queda en `/clasico/`.

---

## 10. Riesgos y soluciones

| Riesgo | Probabilidad | Solución |
|---|---|---|
| **Expectativa de calidad "AAA realista"** frente a un equipo de una persona, recursos libres y el navegador como plataforma | Alta | Objetivo realista: **realismo estilizado de calidad indie** (materiales PBR, buena iluminación, ciudad con identidad). Se muestra con capturas en cada fase para ajustar antes de seguir. |
| **No hay modelos 3D ni animaciones** | Segura | Fuentes con licencia compatible (ver `ARQUITECTURA.md`, sección "Recursos"): personajes con MPFB/MakeHuman, animaciones CC0 de Quaternius, texturas CC0 de Poly Haven y ambientCG, edificios modulares propios hechos en Blender por script. Cada recurso queda registrado con su fuente y licencia. |
| **No hay fotografías de referencia** | Segura | Los personajes se hacen según la descripción (camiseta roja, jeans rotos, tenis blancos con rojo, mochila negra, pulsera). Si quieres un parecido real, necesito fotos de frente y de perfil, con permiso de cada persona. |
| **Rendimiento en navegador** | Media | Perfiles Bajo/Medio/Alto, LOD, instancing, zonas que se cargan por partes, sombras limitadas a la cercanía. Medidor de FPS dentro del juego para medir en tu PC. |
| **No puedo medir FPS reales aquí** (sin GPU) | Segura | Modo de prueba de rendimiento que tú ejecutas; los resultados se documentan en `PRUEBAS.md` con el equipo y navegador usados. |
| **Iluminación horneada requiere GPU** | Segura | Oclusión ambiental horneada en Blender (CPU) e iluminación dinámica; horneado de luz opcional en tu PC. |
| **Marcas y lugares reales** (Cacique, tiendas, etc.) | Media | Lugares inspirados en la ciudad, sin presentarlos como reproducciones exactas. Nombres comerciales reales se reemplazan por nombres ficticios salvo que decidas lo contrario. Calles basadas en OpenStreetMap (licencia ODbL, con atribución en créditos). |
| **Persecuciones policiales** | Baja | Se mantiene el tono del juego actual: la policía es ficticia, no hay armas ni violencia; ser atrapado es una condición de fallo de la misión. |
| **Alcance enorme (12 fases)** | Alta | Se prioriza la vertical slice. Cada fase termina con algo jugable y probado, y nada se marca como terminado si está simulado. |
| **Diferencias visuales entre PC y web** | Media | Las capturas de cada fase se toman en los dos renderizadores. |
