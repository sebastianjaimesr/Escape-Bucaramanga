# Recursos y licencias

Todo el arte y el audio del juego fue **generado de forma procedural** por los scripts de `tools/`, sin usar sprites, música, mapas ni logotipos de otros juegos. Se distribuyen bajo **CC0** (dominio público) junto con el código.

| Recurso | Generador | Notas |
|---|---|---|
| Personajes (`assets/characters/`) | `tools/generate_art.py` | 4 spritesheets 192×224 (32×32 por cuadro) y retratos para diálogos |
| Enemigos, objetos, accesorios urbanos (`assets/sprites/`) | `tools/generate_art.py` | dron patrulla, dron vigía, perro, bocadillo, pista, carros, CAI, vitrinas, farolas, palmeras |
| Tileset (`assets/tilesets/tiles.png`) | `tools/generate_art.py` | 7 temáticas × 4 tiles (superficie, relleno, plataforma, caja) |
| Fondos (`assets/backgrounds/`) | `tools/generate_art.py` | cielo, montañas con luces de casas, ciudad lejana y 7 capas cercanas; se repiten horizontalmente |
| Interfaz (`assets/ui/`) | `tools/generate_art.py` | logotipo con fuente pixel propia, corazones, botones táctiles |
| Música (`assets/audio/music/`) | `tools/generate_audio.py` | 5 pistas chiptune: menu, chase, park, viaduct, finale |
| Efectos (`assets/audio/sfx/`) | `tools/generate_audio.py` | salto, aterrizaje, recoger, daño, sirena ficticia, victoria, derrota, etc. |

## Fotografías de referencia

Las fotografías del protagonista y del grupo **no estaban en la carpeta del proyecto** cuando se creó el juego. Los personajes se diseñaron a partir de la descripción escrita:

- **Rojo (protagonista)**: camiseta roja amplia con estampado, jeans azules rotos, tenis blancos con rojo, mochila negra, pulsera dorada, cabello oscuro corto.
- **Gorra, Rulos y Gafas**: diseños provisionales diferenciados por peinado, ropa, colores y accesorios.

Para ajustar los amigos a las personas reales de la foto, edita el diccionario `CHARACTERS` en `tools/generate_art.py` (colores, `hair_style`, gorra, gafas, bermuda) y vuelve a ejecutar el script, o reemplaza los PNG manteniendo la cuadrícula.
