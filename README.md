# Escape de Bucaramanga

Juego de plataformas 2D de acción nocturna hecho en **Godot 4 (GDScript)**. Rojo, un joven de camiseta roja y mochila negra, es confundido con un ladrón durante una noche en Bucaramanga. Debe atravesar siete niveles inspirados en la ciudad, reunir a sus tres amigos y llegar al mirador para aclarar todo, mientras un dron patrulla ficticio lo sigue.

> Obra de ficción. Los lugares están inspirados en Bucaramanga, no son reproducciones exactas. La persecución es una mecánica de juego con reglas claras.

## Requisitos

- Godot **4.4 o superior** (versión estándar, no .NET). Probado contra la API de Godot 4.4+ (`TileMapLayer`, `Parallax2D`).
- Para regenerar arte, audio o niveles: Python 3 con `Pillow` y `numpy`.

## Ejecutar el juego

1. Abre Godot, elige **Importar**, selecciona `project.godot` de esta carpeta.
2. Presiona **F5** (o el botón ▶). La escena principal es el menú (`scenes/menus/main_menu.tscn`).

Desde la terminal:

```bash
godot --path . 
```

## Controles

| Acción | Teclado | Mando |
|---|---|---|
| Mover | A / D o flechas | Cruceta o palanca izquierda |
| Saltar (mantener = más alto) | ESPACIO, W, flecha arriba, Z | A |
| Correr | SHIFT o X | X / RB |
| Hablar con amigos | E, S o flecha abajo | Y / B |
| Pausa | ESC o P | Start |

En pantallas táctiles aparecen botones en pantalla automáticamente.

## Reglas del juego

- **Salud**: 3 corazones. Vidrios rotos, conos, perros y drones quitan un corazón.
- **Vidas**: 5. Pierdes una vida si te quedas sin corazones, caes al vacío o el dron patrulla te alcanza. Reapareces en el último punto de control.
- **Persecución**: la barra "Distancia a la patrulla" muestra qué tan cerca está. Acelera con el tiempo y es más rápida en cada nivel.
- **Bocadillos**: coleccionables. Cada 25 en un nivel dan una vida extra. Algunos niveles exigen una cantidad.
- **Drones vigía**: se desactivan saltando encima. Los **perros** no se pisan: hay que saltarlos.
- **Meta**: se ve roja hasta cumplir los objetivos del nivel y verde cuando está abierta.
- **Progreso**: se guarda al llegar a puntos de control y al completar niveles (`user://save.json`).

## Niveles

1. Calles nocturnas (tutorial e inicio de la persecución)
2. Sector comercial (vitrinas, toldos y rutas alternativas; misión de bocadillos)
3. El CAI (barreras intermitentes, drones y 3 pistas)
4. El parque (encuentro con Gorra; la persecución vuelve después)
5. El barrio (escaleras, tiendas, encuentro con Rulos)
6. El viaducto (huecos largos, persecución exigente, rescate de Gafas)
7. Encuentro final (los cuatro juntos hasta el mirador y final de la historia)

## Pruebas

Validación estática (no requiere Godot):

```bash
py tools/validate_project.py
```

Pruebas de integración dentro del motor (movimiento, salto, colisiones, daño, puntos de control, caída, persecución, misiones, amigos, guardado, transiciones y rendimiento):

```bash
godot --headless --path . res://tests/test_runner.tscn
```

## Regenerar recursos

```bash
py tools/generate_art.py
py tools/generate_audio.py
py tools/build_levels.py
```

Los niveles se editan en `tools/build_levels.py` (la leyenda del mapa está al inicio del archivo) y se exportan a `data/levels/*.json`. Los diálogos están en `data/dialogue/dialogues.json` y los nombres de los personajes en `data/dialogue/characters.json`.

## Publicación web

Consulta [docs/PUBLICACION.md](docs/PUBLICACION.md). El juego **no** se ha publicado en ningún servicio.

## Documentación

- [docs/ARQUITECTURA.md](docs/ARQUITECTURA.md): organización del código y cómo extender el juego.
- [docs/ESTADO.md](docs/ESTADO.md): qué está terminado, qué se probó y qué falta.
- [docs/RECURSOS.md](docs/RECURSOS.md): origen y licencia del arte y el audio.
