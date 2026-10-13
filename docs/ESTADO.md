# Estado del proyecto

Fecha: 13 de octubre de 2026.

## Terminado

- Proyecto Godot 4 organizado por módulos (`scenes/`, `scripts/`, `assets/`, `data/`, `tests/`, `docs/`) con historial Git.
- Jugador con máquina de estados (8 estados), tiempo de coyote, búfer y salto variable, correr, daño con invulnerabilidad, muerte y reaparición.
- 7 niveles construidos desde datos con `TileMapLayer`: calles, sector comercial, CAI, parque, barrio, viaducto y encuentro final.
- Persecución ficticia con dificultad progresiva (por nivel y por tiempo) y barra de distancia en el HUD.
- Plataformas fijas, de un sentido y móviles; carros sólidos; barreras intermitentes; vidrios y conos; drones (se pisan) y perros (se saltan).
- Puntos de control, vidas, salud, coleccionables (bocadillos, pistas, corazones), misiones por nivel, meta bloqueada hasta cumplirlas.
- Tres amigos que se encuentran con diálogo, se unen al grupo y siguen al jugador.
- Diálogos en español con retratos y texto progresivo; historia completa con final.
- Menú principal, selección de nivel, opciones de audio (música, efectos, lluvia, pantalla completa), pausa, derrota, victoria y final.
- Guardado de progreso y configuración en `user://save.json`.
- Fondos parallax de 4 capas, iluminación nocturna con luces de farolas, vitrinas y patrullas, lluvia opcional, partículas de polvo, recogida y daño, sacudida de cámara y destellos.
- Música (5 pistas) y efectos (16) originales.
- Controles de teclado, mando y táctiles.
- Configuración de exportación Web y Windows.
- Validador estático (`tools/validate_project.py`): **0 errores**.
- Suite de pruebas de integración (`tests/test_runner.tscn`) con 13 pruebas.

## Pendiente de verificación

- **El juego todavía no se ha ejecutado en Godot**: Godot no estaba instalado en este equipo. El código se revisó a mano y con el validador estático, pero pueden aparecer errores de compilación o de ajuste fino al abrirlo por primera vez.
- La suite de pruebas en el motor y la exportación web quedan listas para ejecutarse en cuanto Godot esté disponible.

## Limitaciones conocidas

- Las fotografías de referencia no estaban en la carpeta; los personajes se basan en la descripción escrita (ver `docs/RECURSOS.md`).
- El arte es procedural en pixel art; sirve como versión jugable y se puede reemplazar sin tocar código.
- La alcanzabilidad de los niveles se comprobó con un análisis simplificado; el ajuste fino de dificultad requiere jugarlos.
