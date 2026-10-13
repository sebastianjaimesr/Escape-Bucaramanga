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

## 3. Probar localmente

Los navegadores no cargan el juego abriendo `index.html` como archivo. Sirve la carpeta:

```bash
py -m http.server 8060 --directory build/web
```

y abre `http://localhost:8060`.

## 4. Publicar (requiere tu decisión)

Opciones gratuitas habituales:

- **itch.io**: crea un proyecto HTML, comprime el contenido de `build/web` en un .zip (con `index.html` en la raíz), súbelo y marca "This file will be played in the browser".
- **GitHub Pages**: sube el contenido de `build/web` a una rama `gh-pages` o a la carpeta `docs/` de un repositorio público.

Ninguna de estas acciones se ha realizado: publicar es tu decisión.

## Requisitos del navegador

- WebGL 2 (Chrome, Edge, Firefox y Safari recientes).
- El audio empieza después del primer clic o tecla (política de los navegadores).
- El guardado usa el almacenamiento local del navegador (IndexedDB) mediante `user://`.
