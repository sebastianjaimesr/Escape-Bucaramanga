# Instalación del entorno de desarrollo

## Requisitos

- **Godot 4.7** estable, versión estándar (no .NET): https://godotengine.org/download
  Probado con **Godot 4.7.2**.
- Para exportar: las **plantillas de exportación** de la misma versión (Editor → Gestionar plantillas de exportación → Descargar e instalar).
- Para la versión 2D clásica y sus herramientas: Python 3 con `Pillow` y `numpy` (solo si se regeneran sus recursos).

## Abrir el proyecto

1. Abre Godot → **Importar** → selecciona `project.godot` de la raíz del repositorio.
2. La primera vez Godot importa los recursos (unos segundos).
3. **F5** ejecuta el juego desde el menú principal.

La carpeta `clasico-2d/` es otro proyecto de Godot (la versión 2D). El proyecto 3D la ignora automáticamente. Para abrirla, importa `clasico-2d/project.godot` por separado.

## Renderizador

- En PC el juego usa **Forward+** (Vulkan; en Windows también Direct3D 12). Si la tarjeta gráfica no lo soporta, Godot cambia solo a OpenGL (Compatibilidad).
- En el navegador usa **Compatibilidad** (WebGL 2).
- Para probar en el editor cómo se verá en web: `godot --path . --rendering-method gl_compatibility`.

## Dónde se guarda la configuración

| Plataforma | Carpeta |
|---|---|
| Windows | `%APPDATA%\Escape de Bucaramanga\` |
| Linux | `~/.local/share/Escape de Bucaramanga/` |
| macOS | `~/Library/Application Support/Escape de Bucaramanga/` |
| Navegador | Almacenamiento del sitio (IndexedDB). Se pierde si borras los datos del sitio o usas una ventana privada. |

Archivo: `settings.cfg`. Si se daña, el juego lo renombra a `settings.cfg.bad` y usa los valores por defecto.
