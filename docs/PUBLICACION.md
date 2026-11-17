# Exportación y publicación web

El proyecto ya incluye `export_presets.cfg` con dos configuraciones:

- **Web** → `build/web/index.html`, sin hilos (`thread_support=false`), así que funciona en servidores comunes sin cabeceras especiales (COOP/COEP).
- **Windows** → `build/windows/EscapeDeBucaramanga.exe`.

El renderizador es **Compatibilidad (OpenGL / WebGL 2)**, el recomendado para navegador.

## 1. Instalar las plantillas de exportación

En Godot: **Editor → Gestionar plantillas de exportación → Descargar e instalar** (misma versión que tu editor).

## 2. Exportar

Desde el editor: **Proyecto → Exportar → Web → Exportar proyecto**.

Desde la terminal:

```bash
godot --headless --path . --export-release "Web" build/web/index.html
```

La exportación web usa la página de carga propia `web/shell.html` (configurada en `html/custom_html_shell`): textos en español, barra de progreso, consejos, metadatos para compartir (`preview.png`) y aviso de orientación en celulares.

### Actualizar solo el contenido del juego (sin plantillas de exportación)

Si el motor no cambió de versión, basta con regenerar el paquete y la página:

```bash
godot --headless --path . --export-pack "Web" build/web/index.pck
py tools/make_web_index.py build/web   # escribe index.html desde web/shell.html
```

`index.js`, `index.wasm` y los *worklets* de audio se reutilizan de la exportación anterior (misma versión de Godot, 4.7.2).

## 3. Probar localmente

Los navegadores no cargan el juego abriendo `index.html` como archivo. Sirve la carpeta:

```bash
py -m http.server 8060 --directory build/web
```

y abre `http://localhost:8060`.

## 4. Repositorio y GitHub Pages

El código está en https://github.com/sebastianjaimesr/Escape-Bucaramanga (rama `main`) y la versión web exportada en la rama `gh-pages`.

Para activar Pages: en el repositorio, **Settings → Pages → Build and deployment → Source: Deploy from a branch → Branch: gh-pages / (root) → Save**. El juego quedará en https://sebastianjaimesr.github.io/Escape-Bucaramanga/.

Para actualizar la versión web después de cambiar el juego: vuelve a exportar a `build/web` y sube ese contenido a la rama `gh-pages` (por ejemplo con `git subtree` o copiando los archivos en una carpeta clonada de esa rama).

## 5. Otras opciones de publicación

Opciones gratuitas habituales:

- **itch.io**: crea un proyecto HTML, comprime el contenido de `build/web` en un .zip (con `index.html` en la raíz), súbelo y marca "This file will be played in the browser".
- **GitHub Pages**: sube el contenido de `build/web` a una rama `gh-pages` o a la carpeta `docs/` de un repositorio público.

La versión web está publicada en GitHub Pages desde la rama `gh-pages`. Al actualizarla, conserva la carpeta `beta-3d/` (prototipo 3D).

## Requisitos del navegador

- WebGL 2 (Chrome, Edge, Firefox y Safari recientes).
- El audio empieza después del primer clic o tecla (política de los navegadores).
- El guardado usa el almacenamiento local del navegador (IndexedDB) mediante `user://`.
