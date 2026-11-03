# Plan de desarrollo — Escape de Bucaramanga 3D

Estado: Fase 1 aprobada el 3 de noviembre de 2026. **Fase 2 terminada** (ver `PRUEBAS.md` y `CHANGELOG.md`).

## 1. Reglas del plan

- Todo se trabaja en la rama `desarrollo-3d`. `main` y `gh-pages` (la versión publicada) no se tocan hasta que la nueva versión esté verificada.
- Cada fase termina con: código, pruebas ejecutadas, errores corregidos, documentación actualizada y una versión que se puede abrir y probar.
- Una fase no se marca como terminada si algo esencial está simulado. Lo pendiente queda escrito en `CHANGELOG.md` y `PRUEBAS.md`.
- Los resultados de rendimiento solo se anotan si se midieron, con el equipo, navegador y perfil usados.

## 2. Fases

| Fase | Entrega comprobable | Criterio para darla por terminada |
|---|---|---|
| **1. Auditoría y arquitectura** ✅ | `AUDITORIA_INICIAL.md`, `ARQUITECTURA.md`, este plan | Aprobación tuya |
| **2. Prototipo 3D** ✅ | Proyecto 3D en la raíz, 2D en `clasico-2d/`, manzana de prueba, cámara y movimiento, exportación web y Windows | Ver sección 3 |
| **3. Protagonista** | Modelo de Sebastián (camiseta roja, jeans rotos, tenis blancos con rojo, mochila negra, pulsera) y las 14 animaciones pedidas con transiciones | Todas las animaciones se ven en juego; capturas en PC y web |
| **4. Compañeros IA** | Tres amigos con máquina de estados, formación, navmesh, reagrupamiento, recuperación | Prueba: 10 minutos de recorrido automático sin atravesar edificios, sin atascarse más de 5 s y sin amontonarse |
| **5. Primera zona de Bucaramanga** | Zona del centro alrededor del Parque García Rovira, con calles de OpenStreetMap, aceras, edificios modulares variados, semáforos, señales, farolas, vegetación, ciclo día/noche, lluvia | Recorrible a pie de un extremo al otro; capturas de día, de noche y con lluvia |
| **6. Policía y persecuciones** | Patrulla a pie y en vehículo con los 7 estados, percepción, búsqueda, escondites, indicador de alerta | Pruebas: detecta con línea de vista, no detecta a través de edificios, pierde al jugador escondido y vuelve a patrullar |
| **7. Vehículos** | Un carro conducible, cámara de conducción, entrada/salida con compañeros, patrulla que persigue en vehículo, tráfico básico | Prueba: el bot conduce un recorrido; los compañeros suben y bajan |
| **8. Misiones** | Gestor de misiones y las 5 misiones principales jugables | El bot completa la Misión 1 de principio a fin; las otras 4 se prueban a mano y con pruebas por objetivo |
| **9. Interfaz y progresión** | Menú principal completo, HUD, minimapa, mapa, diario, inventario, dinero, pantallas de carga/derrota/victoria, 3 espacios de guardado + automático | Cada botón hace lo que dice; guardado con integridad y respaldo probado |
| **10. Audio y efectos** | Música ambiental y de persecución, pasos por superficie, vehículos, sirenas, lluvia, viento, ambiente urbano, volúmenes separados | Todos los sonidos con licencia registrada |
| **11. Optimización** | Perfiles Bajo/Medio/Alto, LOD, instancing, carga por zonas, medidor de rendimiento | Medición en tu PC y en navegador, documentada en `PRUEBAS.md` |
| **12. Exportación y publicación** | `.exe` de Windows y versión web; la 3D pasa a la raíz de GitHub Pages y la 2D a `/clasico/` | Solo después de comprobar la web publicada en `/beta-3d/` y con tu aprobación |

La **vertical slice** del encargo (sección 19) queda completa al terminar la Fase 8 y se pule en las Fases 9 a 11. Desde la Fase 2 se publican versiones de prueba en `/beta-3d/`.

## 3. Primer prototipo (Fase 2)

Lo que voy a construir primero:

1. **Reorganización del repositorio**
   - `git mv` de todo el proyecto 2D a `clasico-2d/` y comprobación de que sus 14 pruebas y el bot siguen pasando desde ahí.
   - Proyecto Godot 3D nuevo en la raíz con la estructura de `ARQUITECTURA.md`, renderizador Forward+ en PC y Compatibilidad en web.

2. **Escenario de prueba**
   - Una manzana de prueba con calle, aceras con bordillo, una intersección, escaleras, una rampa, obstáculos, un edificio en el que se puede chocar y un espacio abierto. **Es un escenario de pruebas con geometría simple y materiales PBR básicos, no la ciudad final**; se reemplaza en la Fase 5.
   - Luz del sol con sombras, cielo, niebla por distancia.

3. **Personaje y cámara**
   - `CharacterBody3D` con caminar, correr (Shift), saltar (Espacio), agacharse (C), detección de suelo, pendientes y subida de escalones. La resistencia baja al correr.
   - Cámara en tercera persona con ratón, que no atraviesa paredes. Captura del cursor y salida con Esc.
   - El cuerpo del personaje en esta fase es una figura humana simple (cápsula con proporciones humanas). **El modelo de Sebastián llega en la Fase 3.**

4. **Base técnica**
   - Autoloads `GameState`, `EventBus`, `Settings`, `InputConfig` (con los controles del encargo y reasignables), `SceneLoader` con pantalla de carga.
   - Esqueleto de perfiles de calidad y medidor de FPS (F3).

5. **Pruebas y publicación**
   - Pruebas headless: movimiento, salto, gravedad, colisión con paredes, subida de escalones, cámara sin atravesar paredes, reasignación de controles.
   - Exportación web y Windows, captura de pantalla de la versión web en Chromium y publicación en `/beta-3d/` de GitHub Pages.

## 4. Campaña

### Historia base
Se conserva la del juego 2D: Sebastián es confundido con un ladrón durante una noche en Bucaramanga. Con sus tres amigos (hoy Buitrago, Diaz y Gordo; los nombres se pueden cambiar en `data/characters.json`) recorre la ciudad para encontrar al verdadero responsable y aclarar todo, mientras la policía lo busca. La policía es ficticia y no hay violencia.

### 5 misiones principales (se implementan completas en la Fase 8)

| Id | Nombre provisional | Lugar | Resumen |
|---|---|---|---|
| M01 | La noche del malentendido | Centro, Parque García Rovira | Introducción, presentación de los amigos, el malentendido, primera persecución a pie, escape en carro hasta un lugar seguro |
| M02 | Lo que vio la cámara | Centro, Parque Santander | Hablar con testigos y conseguir la grabación de una cámara de un local |
| M03 | Carrera 27 | Carrera 27 hacia Cabecera | Seguir al sospechoso en vehículo sin que la patrulla te detecte |
| M04 | El rastro en la universidad | Sector de la UIS | Explorar y encontrar pruebas con ayuda de los tres amigos |
| M05 | El puente | Puente sobre la Novena / Viaducto (nombre a confirmar) | Persecución final y entrega de las pruebas para aclarar todo |

En la vertical slice solo se construye la zona del centro, así que **M01 es la primera misión completa**. Las demás necesitan sus zonas (se construyen a medida que se amplía la ciudad).

### 10 misiones secundarias (solo planificadas)

| Id | Nombre provisional | Idea |
|---|---|---|
| S01 | El granizado perfecto | Conseguir los ingredientes para un vendedor del parque |
| S02 | Mandado en el centro | Entregar un paquete antes de que cierre el local |
| S03 | Rutas alternativas | Encontrar los 5 atajos de la zona |
| S04 | El celular perdido | Devolver un celular a su dueño |
| S05 | Carrera nocturna | Llegar a un punto en un tiempo límite |
| S06 | Fotos de la ciudad | Fotografiar lugares emblemáticos |
| S07 | El parqueadero | Mover carros sin chocarlos |
| S08 | Hablar con todos | Conocer a los personajes de cada barrio |
| S09 | Los grafitis | Encontrar murales escondidos |
| S10 | Ayuda en la tienda | Pequeños encargos para una tienda del barrio |

## 5. Comandos

Con Godot 4.7 instalado (`godot` en el PATH, o la ruta al ejecutable):

```bash
# Abrir el editor
godot -e --path .

# Ejecutar el juego
godot --path .

# Pruebas del juego 3D (a partir de la Fase 2)
godot --headless --path . res://tests/test_runner.tscn

# Pruebas de la versión 2D clásica (después de moverla)
godot --headless --path clasico-2d res://tests/test_runner.tscn
godot --headless --path clasico-2d --fixed-fps 60 res://tests/bot_runner.tscn

# Validación de referencias y datos
python tools/validate_project.py

# Exportaciones (requieren las plantillas de exportación de Godot 4.7)
godot --headless --path . --export-release "Web" build/web/index.html
godot --headless --path . --export-release "Windows Desktop" build/windows/EscapeDeBucaramanga.exe

# Probar la versión web localmente
python -m http.server 8060 --directory build/web
```

## 6. Decisiones abiertas

1. **Fotografías de referencia:** si quieres que Sebastián y los amigos se parezcan a personas reales, necesito fotos de frente y de perfil con el permiso de cada uno. Si no, se modelan según la descripción.
2. **Nombres comerciales reales** (Cacique, OXXO, D1...): por defecto se usan nombres ficticios para evitar problemas de marcas.
3. **Rama `docs/comentarios`:** contiene comentarios en los scripts 2D y una guía de estudio que no están en `main`. Propuesta: integrarla en `clasico-2d/` durante la Fase 2.
