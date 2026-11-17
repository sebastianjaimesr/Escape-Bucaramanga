# Recursos y licencias

Todo el arte y el audio del juego fue **generado de forma procedural** por los scripts de `tools/`, sin usar sprites, música, mapas ni logotipos de otros juegos. Se distribuyen bajo **CC0** (dominio público) junto con el código.

| Recurso | Generador | Notas |
|---|---|---|
| Personajes (`assets/characters/`) | `tools/generate_art.py` | 4 spritesheets 192×224 (32×32 por cuadro) y retratos para diálogos |
| Enemigos, objetos, accesorios urbanos (`assets/sprites/`) | `tools/generate_art.py` | dron patrulla, dron vigía, perro, granizado, pista, carros, CAI, vitrinas, farolas, palmeras |
| Tileset (`assets/tilesets/tiles.png`) | `tools/generate_art.py` | 7 temáticas × 4 tiles (superficie, relleno, plataforma, caja) |
| Fondos (`assets/backgrounds/`) | `tools/generate_art.py` | cielo, montañas con luces de casas, ciudad lejana y 7 capas cercanas; se repiten horizontalmente |
| Interfaz (`assets/ui/`) | `tools/generate_art.py` | logotipo con fuente pixel propia, corazones, botones táctiles |
| Lugares de Bucaramanga (`assets/backgrounds/landmark_*.png`, `clouds.png`, `haze.png`) | `tools/generate_landmarks.py` | Centro (casas republicanas con balcones), torres de Cabecera, cancha de San Pío, guayacanes del Parque San Pío, Iglesia de San Laureano y Capilla de los Dolores (García Rovira), meseta vista desde el Viaducto y Cerro del Santísimo con teleférico. Interpretaciones artísticas, no reproducciones exactas |
| Hormiga culona, cabina del teleférico, luciérnaga, luces de carros, Santísimo lejano, estrellas (`assets/sprites/`, `assets/ui/`) | `tools/generate_landmarks.py` | añadidos en la versión 1.1 |
| Música (`assets/audio/music/`) | `tools/generate_audio.py` | 5 pistas chiptune: menu, chase, park, viaduct, finale |
| Efectos (`assets/audio/sfx/`) | `tools/generate_audio.py` | salto, aterrizaje, recoger, daño, sirena ficticia, victoria, derrota, etc. |
| Efectos v1.1 (`hormiga`, `star`, `tally`, `start`) | `tools/generate_audio_extra.py` | hormiga culona, estrellas, conteo de puntaje y pantalla de título |

Los generadores de la versión 1.1 son **aditivos**: no vuelven a escribir los recursos de `generate_art.py` ni de `generate_audio.py`.

## Fotografías de referencia

Las fotografías del protagonista y del grupo **no estaban en la carpeta del proyecto** cuando se creó el juego. Los personajes se diseñaron a partir de la descripción escrita:

- **Sebas (protagonista)**: camiseta roja amplia con estampado, jeans azules rotos, tenis blancos con rojo, mochila negra, pulsera dorada, cabello oscuro corto.
- **Buitrago, Diaz y Gordo**: diseños provisionales diferenciados por peinado, ropa, colores y accesorios.

Para ajustar los amigos a las personas reales de la foto, edita el diccionario `CHARACTERS` en `tools/generate_art.py` (colores, `hair_style`, gorra, gafas, bermuda) y vuelve a ejecutar el script, o reemplaza los PNG manteniendo la cuadrícula.
