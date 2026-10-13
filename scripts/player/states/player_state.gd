class_name PlayerState
extends Node
## Base de los estados del jugador.

var player: Player
var machine: PlayerStateMachine


func enter(_previous: StringName, _msg: Dictionary) -> void:
	pass


func exit() -> void:
	pass


func physics_update(_delta: float) -> void:
	pass


## Transiciones comunes desde estados en el suelo. Devuelve true si cambió.
func check_air_transitions() -> bool:
	if player.can_jump():
		machine.change_state(&"Jump")
		return true
	if not player.is_on_floor():
		machine.change_state(&"Fall")
		return true
	return false


func ground_state_name() -> StringName:
	if absf(player.move_axis()) < 0.05:
		return &"Idle"
	return &"Run" if player.wants_run() else &"Walk"
