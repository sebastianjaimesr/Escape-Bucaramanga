class_name PlayerState
extends Node
## Base de los estados del jugador.

var player: Player
var machine: PlayerStateMachine


## Se llama al entrar al estado; previous es el estado anterior y msg trae datos extra.
func enter(_previous: StringName, _msg: Dictionary) -> void:
	pass


## Se llama al salir del estado.
func exit() -> void:
	pass


## Lógica de cada cuadro de física mientras el estado está activo.
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


## Estado de suelo que corresponde a la entrada: quieto, caminar o correr.
func ground_state_name() -> StringName:
	if absf(player.move_axis()) < 0.05:
		return &"Idle"
	return &"Run" if player.wants_run() else &"Walk"
