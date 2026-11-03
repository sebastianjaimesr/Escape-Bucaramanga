class_name PhysicsLayers
extends RefCounted
## Capas de colisión 3D (coinciden con [layer_names] de project.godot).
## Se usan como máscaras de bits: WORLD | CHARACTERS, etc.

const WORLD := 1 << 0          ## Suelo, edificios, props sólidos.
const PLAYER := 1 << 1         ## Sebastián.
const CHARACTERS := 1 << 2     ## Compañeros, policía, peatones.
const VEHICLES := 1 << 3
const INTERACTABLES := 1 << 4  ## Áreas de interacción (no bloquean).
const CAMERA_IGNORE := 1 << 5  ## Objetos que la cámara puede atravesar (vegetación fina).

## Lo que bloquea a la cámara en tercera persona.
const CAMERA_BLOCKERS := WORLD | VEHICLES
