# Escape de Bucaramanga

Juego de plataformas 2D de acción nocturna hecho en **Godot 4 (GDScript)**. Sebas, un joven de camiseta roja y mochila negra, es confundido con un ladrón durante una noche en Bucaramanga. Debe cruzar la ciudad, del Centro al Cerro del Santísimo, reunir a sus tres amigos y llegar al mirador para aclarar todo, mientras un dron patrulla ficticio lo sigue.

**Jugar en el navegador:** https://sebastianjaimesr.github.io/Escape-Bucaramanga/ (computador o celular en horizontal)

### Novedades de la versión 1.1

- **Bucaramanga como protagonista:** cada nivel tiene un lugar reconocible en el fondo, como las casas republicanas del Centro, las torres de Cabecera, los guayacanes de San Pío, San Laureano y la Capilla de los Dolores en García Rovira, el Viaducto de la Novena y el Cerro del Santísimo con su teleférico. El monumento del Santísimo se ve a lo lejos desde el primer nivel y crece a medida que te acercas.
- **Puntaje, combos y 3 estrellas por nivel.** Hay **hormigas culonas** escondidas en las rutas altas como reto secundario y los récords se guardan.
- **Mejor sensación de control:** squash & stretch, cima del salto más suave, corrección de esquinas al chocar con el techo y *hit stop* al pisar enemigos.
- **Interfaz renovada:** pantalla de título, “Cómo jugar”, selección de nivel con estrellas y récords, HUD con puntaje y combo, pausa con objetivo actual y victoria con desglose animado.
- **Ambiente vivo:** nubes, bruma, luciérnagas, flores de guayacán que caen, cabinas del teleférico, tráfico sobre el Viaducto y viñeta de cámara.
- **Web y móvil:** página de carga propia, aviso para girar el teléfono, controles táctiles reubicados y textos de ayuda adaptados al tacto. También se puede silenciar con M.

> Obra de ficción. Los lugares están inspirados en Bucaramanga, no son reproducciones exactas. La persecución es una mecánica de juego con reglas claras.

## Requisitos

- Godot **4.4 o superior** (versión estándar, no .NET). Probado con **Godot 4.7.2**.
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
| Silenciar | M | — |

En pantallas táctiles aparecen botones en pantalla automáticamente.

## Reglas del juego

- **Salud**: 3 corazones. Vidrios rotos, conos, perros y drones quitan un corazón.
- **Vidas**: 5. Pierdes una vida si te quedas sin corazones, caes al vacío o el dron patrulla te alcanza. Reapareces en el último punto de control.
- **Persecución**: la barra "Distancia a la patrulla" muestra qué tan cerca está. Acelera con el tiempo y es más rápida en cada nivel.
- **Granizados**: coleccionables. Cada 25 en un nivel dan una vida extra. Algunos niveles exigen una cantidad.
- **Drones vigía**: se desactivan saltando encima. Los **perros** no se pisan: hay que saltarlos.
- **Meta**: se ve roja hasta cumplir los objetivos del nivel y verde cuando está abierta.
- **Puntaje**: granizado 10, dron pisado 50 (×2, ×3… en combo sin tocar el suelo), pista 150, hormiga culona 300, amigo 500. Al terminar: +1000, bono por tiempo y +1500 sin perder vidas.
- **Estrellas**: completar el nivel · recoger el 75 % de los granizados · encontrar las 3 hormigas culonas.
- **Progreso**: se guarda al llegar a puntos de control y al completar niveles (`user://save.json`, versión 2 compatible con guardados anteriores). Incluye récords, estrellas y hormigas.

## Niveles

1. **Centro, Calle 35**: tutorial e inicio de la persecución, entre casas republicanas con balcones.
2. **Cabecera**: vitrinas, toldos y rutas alternativas; misión de granizados.
3. **El CAI de San Pío**: barreras intermitentes, drones y 3 pistas.
4. **Parque San Pío**: encuentro con Buitrago bajo los guayacanes; la persecución vuelve después.
5. **Barrio García Rovira**: escaleras, tiendas y encuentro con Diaz, con San Laureano al fondo.
6. **Viaducto de la Novena**: huecos largos, persecución exigente y rescate de Gordo.
7. **Cerro del Santísimo**: los cuatro juntos hasta el mirador y final de la historia.

## Pruebas

Validación estática (no requiere Godot):

```bash
py tools/validate_project.py
```

Pruebas de integración dentro del motor (20 pruebas: movimiento, salto, colisiones, daño, puntos de control, caída, persecución, misiones, amigos, guardado v1/v2, transiciones, hormigas, combos, estrellas y bonos, carga de menús, capas de lugar y rendimiento):

```bash
godot --headless --path . res://tests/test_runner.tscn
```

Bot que recorre los 7 niveles con la física real para comprobar que se pueden completar:

```bash
godot --headless --path . --fixed-fps 60 res://tests/bot_runner.tscn
```

Godot 4.7.2 quedó descargado en `tools/godot/` (no se sube a Git); puedes usar `tools\godot\Godot_v4.7.2-stable_win64.exe` en lugar de `godot`.

## Regenerar recursos

```bash
py tools/generate_art.py
py tools/generate_audio.py
py tools/generate_landmarks.py      # lugares de Bucaramanga, hormiga, estrellas (v1.1)
py tools/generate_audio_extra.py    # efectos de la v1.1
py tools/build_levels.py            # también ubica las 3 hormigas culonas de cada nivel
```

Los niveles se editan en `tools/build_levels.py` (la leyenda del mapa está al inicio del archivo) y se exportan a `data/levels/*.json`. Los diálogos están en `data/dialogue/dialogues.json` y los nombres de los personajes en `data/dialogue/characters.json`.

## Publicación web

Publicado en GitHub Pages (rama `gh-pages`): https://sebastianjaimesr.github.io/Escape-Bucaramanga/ — el prototipo 3D sigue en `/beta-3d/`. Consulta [docs/PUBLICACION.md](docs/PUBLICACION.md) para actualizarlo.

## Documentación

- [docs/ARQUITECTURA.md](docs/ARQUITECTURA.md): organización del código y cómo extender el juego.
- [docs/ESTADO.md](docs/ESTADO.md): qué está terminado, qué se probó y qué falta.
- [docs/RECURSOS.md](docs/RECURSOS.md): origen y licencia del arte y el audio.
- [CHANGELOG.md](CHANGELOG.md): cambios por versión.
