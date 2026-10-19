class_name TrailRecorder
extends Node
## Guarda las últimas posiciones del jugador para que los amigos lo sigan.

const MAX_SAMPLES := 90

var target: Player
var _samples: Array[Dictionary] = []


## Guarda la posición actual al principio de la lista (si cambió) y descarta la más vieja.
func _physics_process(_delta: float) -> void:
	if target == null or target.is_dead:
		return
	if not _samples.is_empty() and _samples[0]["pos"].distance_to(target.global_position) < 0.5:
		return
	_samples.push_front({"pos": target.global_position, "floor": target.is_on_floor()})
	if _samples.size() > MAX_SAMPLES:
		_samples.pop_back()


## true si todavía no hay posiciones guardadas.
func is_empty() -> bool:
	return _samples.is_empty()


## Posición de hace "frames_ago" muestras (o la más vieja disponible).
func sample(frames_ago: int) -> Dictionary:
	return _samples[mini(frames_ago, _samples.size() - 1)]


## Rellena el rastro con una sola posición (al reaparecer).
func reset(pos: Vector2) -> void:
	_samples.clear()
	for i in MAX_SAMPLES:
		_samples.append({"pos": pos - Vector2(i * 0.5, 0), "floor": true})
