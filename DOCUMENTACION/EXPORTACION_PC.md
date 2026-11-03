# Exportación para PC (Windows)

## Exportar

Con las plantillas de exportación de Godot 4.7.2 instaladas:

```bash
godot --headless --path . --export-release "Windows" build/windows/EscapeDeBucaramanga.exe
```

o en el editor: **Proyecto → Exportar → Windows → Exportar proyecto**.

El resultado es un solo archivo `EscapeDeBucaramanga.exe` (≈ 104 MB, con los datos del juego incluidos). No necesita instalación.

## Qué se comprobó (Fase 2)

| Comprobación | Resultado |
|---|---|
| La exportación termina sin errores (desde Linux, plantillas 4.7.2) | Sí |
| El ejecutable abre y se juega en Windows | **No comprobado**: este entorno de desarrollo no tiene Windows. Pendiente de probar en tu PC. |

## Notas

- Renderizador Forward+ con cambio automático a OpenGL si la tarjeta no soporta Vulkan ni Direct3D 12.
- La configuración se guarda en `%APPDATA%\Escape de Bucaramanga\`.
- El ejecutable no está firmado: Windows SmartScreen puede mostrar un aviso la primera vez ("Más información → Ejecutar de todas formas").
- El icono del `.exe` y los datos de versión se configuran en la Fase 12.
