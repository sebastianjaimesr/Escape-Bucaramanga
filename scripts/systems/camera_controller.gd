class_name CameraController
extends Camera2D
## Cámara lateral con anticipación en la dirección de movimiento y sacudidas.

const LOOK_AHEAD := 36.0

var target: Node2D
var _shake_strength := 0.0
var _shake_time := 0.0
var _look := 0.0


## Zoom x2 (estilo pixel art) y movimiento suavizado.
func _ready() -> void:
	zoom = Vector2(2, 2)
	position_smoothing_enabled = true
	position_smoothing_speed = 7.0
	process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	limit_smoothed = true


## Limita la cámara al tamaño del nivel.
func setup(level_size: Vector2) -> void:
	limit_left = 0
	limit_top = -24
	limit_right = int(level_size.x)
	limit_bottom = int(level_size.y)


## Pone la cámara de golpe sobre el jugador (al empezar o reaparecer).
func snap_to_target() -> void:
	if target:
		global_position = target.global_position + Vector2(0, -24)
		reset_smoothing()


## Sigue al jugador adelantándose hacia donde mira y aplica la sacudida.
func _physics_process(delta: float) -> void:
	if target == null or not is_instance_valid(target):
		return
	var facing := 0.0
	var f: Variant = target.get("facing")
	if f != null:
		facing = float(f)
	_look = lerpf(_look, facing * LOOK_AHEAD, clampf(delta * 2.5, 0.0, 1.0))
	global_position = target.global_position + Vector2(_look, -24)
	if _shake_time > 0.0:
		_shake_time -= delta
		offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * _shake_strength
		if _shake_time <= 0.0:
			offset = Vector2.ZERO


## Sacude la cámara con la fuerza y duración indicadas.
func shake(strength: float = 3.0, duration: float = 0.25) -> void:
	_shake_strength = strength
	_shake_time = duration
