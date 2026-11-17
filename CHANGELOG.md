# Cambios

## 1.1.0 — Bucaramanga protagonista (noviembre de 2026)

### Mundo e identidad
- Niveles renombrados y ambientados en lugares reales: Centro (Calle 35), Cabecera, CAI de San Pío, Parque San Pío, Barrio García Rovira, Viaducto de la Novena y Cerro del Santísimo.
- Nueva capa de lugar por nivel (`landmark_*.png`) colocada con precisión mediante `ParallaxBuilder.offset_for()`.
- La silueta del Santísimo se ve a lo lejos desde el nivel 1 y crece con cada nivel: la meta de la historia siempre está a la vista.
- Ambiente animado (`AmbientBuilder`): nubes, bruma, luciérnagas, flores de guayacán, cabinas del teleférico, tráfico sobre el Viaducto y viñeta.

### Jugabilidad
- Sistema de puntaje con combo por enemigos pisados seguidos, bonos de nivel (completar, tiempo y sin perder vidas) y 3 estrellas por nivel.
- Hormigas culonas: 3 secretos por nivel, ubicados automáticamente por `build_levels.py` en las rutas más altas de cada tramo.
- Sensación de control: squash & stretch, gravedad reducida en la cima del salto, corrección de esquinas de techo y *hit stop*.
- Puntos de control dan puntos solo la primera vez.

### Interfaz y audio
- Pantalla de título con entrada cinematográfica y “presiona para empezar”, que además desbloquea el audio en el navegador.
- “Cómo jugar”, selección de nivel con estrellas, récord y hormigas, pausa con objetivo y estado, y victoria con desglose y conteo animado.
- HUD con paneles translúcidos, puntaje animado, combo, hormigas e indicador de silencio.
- Música con fundido cruzado; tecla M para silenciar; opción de desactivar las sacudidas de cámara.
- Efectos nuevos: hormiga, estrella, conteo y título.

### Web y móvil
- Página de carga propia (`web/shell.html`) con metadatos para compartir y aviso para girar el teléfono.
- Controles táctiles escalados según la pantalla, con la pausa reubicada para no tapar el HUD; ayudas y diálogos adaptados al tacto.

### Calidad
- Guardado versión 2 compatible con la versión 1.
- 6 pruebas nuevas (20 en total), validador ampliado y capturas de menús en `tests/screenshots.gd`.
