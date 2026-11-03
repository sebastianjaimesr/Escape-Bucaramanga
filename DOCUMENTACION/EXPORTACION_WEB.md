# Exportación web y GitHub Pages

## Exportar

```bash
godot --headless --path . --export-release "Web" build/web/index.html
```

- Plantilla **sin hilos** (`thread_support=false`): funciona en GitHub Pages, que no permite las cabeceras COOP/COEP que necesitan los hilos.
- Renderizador **Compatibilidad (WebGL 2)**.

## Probar localmente

```bash
python -m http.server 8060 --directory build/web
```

y abre http://localhost:8060. Abrir `index.html` directamente como archivo no funciona.

## Tamaño (Fase 2, medido)

| Archivo | Tamaño | Comprimido (gzip -9) |
|---|---|---|
| `index.wasm` (motor Godot) | 39,5 MB | ≈ 10,1 MB |
| `index.pck` (datos del juego) | 86 KB | ≈ 74 KB |
| `index.js` | 280 KB | — |

El motor es un costo fijo de Godot. En la Fase 11 se evaluará compilar una plantilla web propia sin los módulos que no se usan.

## Publicación en GitHub Pages

La rama `gh-pages` sirve el sitio. Durante el desarrollo:

| Ruta | Contenido |
|---|---|
| `/` | Juego 2D (versión estable, sin cambios) |
| `/beta-3d/` | Última versión de prueba del 3D |

Para actualizar la versión de prueba: exportar a `build/web`, copiar su contenido a la carpeta `beta-3d/` de la rama `gh-pages` y subir. La raíz solo se reemplaza en la Fase 12, con tu aprobación, y el 2D pasará a `/clasico/`.

## Limitaciones en el navegador

- El ratón se captura al hacer clic en el juego; Esc lo libera y abre la pausa.
- La pantalla completa la maneja el navegador (F11), no el juego.
- Sin SSAO, SSR ni niebla volumétrica (no existen en WebGL 2 en Godot). El perfil por defecto en web es **Bajo**.
- La configuración se guarda en el almacenamiento del sitio (IndexedDB): se pierde al borrar los datos del sitio o en ventanas privadas.
