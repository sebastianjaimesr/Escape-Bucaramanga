# Cambios

## 0.2.0 — Fase 2: prototipo 3D (3 de noviembre de 2026)

### Agregado
- Proyecto 3D en Godot 4.7 en la raíz del repositorio: Forward+ en PC, Compatibilidad (WebGL 2) en web, física Jolt.
- Autoloads `EventBus`, `Settings` (configuración en `user://settings.cfg` con escritura segura y recuperación de archivos dañados), `InputConfig` (controles del encargo, reasignables, con intercambio de teclas en conflicto) y `SceneLoader` (pantalla de carga y pantalla de error).
- Jugador con máquina de estados (quieto, caminar, correr, saltar, caer, agacharse), resistencia, tiempo de coyote, búfer de salto, salto variable, subida automática de bordillos y escalones de hasta 36 cm, y comprobación de techo al levantarse.
- Cámara en tercera persona sobre el hombro con SpringArm3D (no atraviesa paredes), ratón y palanca derecha, sensibilidad, inversión y campo de visión configurables.
- Manzana de prueba generada por código: calles, aceras, bordillos, pasos de cebra, edificios con ventanas instanciadas (MultiMesh), plaza de pruebas de movimiento, árboles, bancas y postes.
- Perfiles de calidad Bajo, Medio y Alto; medidor de rendimiento (F3).
- Menú principal, pausa y panel de configuración.
- 24 pruebas de integración (`tests/test_runner.tscn`) y capturas automáticas (`tests/screenshots.tscn`).
- Exportaciones Web y Windows; publicación de prueba en `/beta-3d/`.

### Cambiado
- La versión 2D completa se movió a `clasico-2d/` sin cambios de código (sus 14 pruebas y el bot de 7 niveles siguen pasando).

### Pendiente (no implementado todavía)
- Modelo y animaciones de Sebastián (Fase 3). El cuerpo actual es provisional.
- Sistema de interacción (E), vehículos (F), inventario (Tab) y mapa (M): las acciones existen internamente, pero no se muestran en el panel de controles hasta que sus funciones estén hechas.
- Guardado de partidas (Fase 9).

## 1.0.0 — Juego 2D

Ver `clasico-2d/README.md` y el historial de Git.
