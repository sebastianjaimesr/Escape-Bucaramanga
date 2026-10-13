# Estado del proyecto

Fecha: 13 de octubre de 2026. Motor usado para las pruebas: **Godot 4.7.2 estable**.

## Terminado y verificado

| Verificación | Cómo | Resultado |
|---|---|---|
| Sintaxis y carga de todos los scripts | Importación de Godot sin errores de script | OK |
| Referencias a escenas, recursos, diálogos y niveles | `py tools/validate_project.py` | 0 errores |
| Movimiento, salto, correr, colisiones con el suelo | `tests/test_runner.tscn` | OK |
| Coleccionables, misiones y meta bloqueada | `tests/test_runner.tscn` | OK |
| Daño, muerte, reaparición en punto de control, caída al vacío | `tests/test_runner.tscn` | OK |
| Persecución: captura, pérdida de vida y retroceso del dron | `tests/test_runner.tscn` | OK |
| Encuentro con amigo, diálogo, unión al grupo | `tests/test_runner.tscn` | OK |
| Guardado y carga | `tests/test_runner.tscn` | OK |
| Transiciones entre escenas | `tests/test_runner.tscn` | OK |
| Rendimiento (nivel 6 con persecución) | `tests/test_runner.tscn` | ~16,7 ms por cuadro, limitado a 60 FPS |
| Los 7 niveles se pueden completar con la física real | `tests/bot_runner.tscn` (bot automático) | 7 de 7 |
| Flujo menú → nivel → introducción → persecución | `tests/flow_check.tscn` | OK |
| Exportación web | `--export-release "Web"` | `build/web/` generado (≈40 MB, casi todo el motor) |
| Juego web en navegador | Servido en local y abierto en navegador | Menú, nivel 1, diálogo, movimiento, bocadillos y persecución funcionando, sin errores en consola |

El bot encontró 5 tramos injustos (un obstáculo justo antes de un hueco o escalones demasiado angostos) en los niveles 1, 3, 4, 6 y 7; se corrigieron en `tools/build_levels.py`.

## Contenido

- 7 niveles: calles, sector comercial, CAI, parque, barrio, viaducto y encuentro final.
- Protagonista y 3 amigos con 7 animaciones cada uno; dron patrulla, drones vigía y perros.
- Persecución con dificultad progresiva por nivel y por tiempo, barra de distancia en el HUD.
- Plataformas fijas, de un sentido y móviles; carros; barreras intermitentes; vidrios y conos.
- Vidas, salud, puntos de control, bocadillos, pistas, corazones, misiones.
- Diálogos en español con retratos e historia completa con final.
- Menú, selección de nivel, opciones de audio, pausa, derrota, victoria, final y créditos.
- Guardado de progreso, música y efectos originales, lluvia opcional, partículas, luces nocturnas.
- Controles de teclado, mando y táctiles.

## Pendiente o limitado

- **Fotografías**: no estaban en la carpeta. Los personajes se basan en la descripción escrita; los amigos son diseños provisionales (ver `docs/RECURSOS.md`).
- **Controles táctiles**: implementados, no probados en un teléfono real.
- **Balance fino**: el bot comprueba que se puede llegar a la meta, no que la dificultad sea ideal. Conviene jugarlo y ajustar velocidades de la persecución en `tools/build_levels.py`.
- **Publicación**: la versión web está lista en `build/web/` pero no se ha publicado en ningún sitio (ver `docs/PUBLICACION.md`).
