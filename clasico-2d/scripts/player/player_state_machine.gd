class_name PlayerStateMachine
extends Node
## Máquina de estados del jugador. Cada estado es un nodo hijo con su script.

signal state_changed(from: StringName, to: StringName)

const STATES := {
	&"Idle": preload("res://scripts/player/states/idle_state.gd"),
	&"Walk": preload("res://scripts/player/states/walk_state.gd"),
	&"Run": preload("res://scripts/player/states/run_state.gd"),
	&"Jump": preload("res://scripts/player/states/jump_state.gd"),
	&"Fall": preload("res://scripts/player/states/fall_state.gd"),
	&"Hurt": preload("res://scripts/player/states/hurt_state.gd"),
	&"Interact": preload("res://scripts/player/states/interact_state.gd"),
	&"Dead": preload("res://scripts/player/states/dead_state.gd"),
}

var player: Player
var current: PlayerState
var current_name: StringName = &""
var _states: Dictionary = {}


func setup(p: Player) -> void:
	player = p
	for state_name: StringName in STATES:
		var s: PlayerState = STATES[state_name].new()
		s.name = String(state_name)
		s.player = p
		s.machine = self
		add_child(s)
		_states[state_name] = s
	change_state(&"Idle")


func change_state(state_name: StringName, msg: Dictionary = {}) -> void:
	if not _states.has(state_name):
		push_error("Estado inexistente: %s" % state_name)
		return
	if current_name == &"Dead" and state_name != &"Idle":
		return
	var previous := current_name
	if current:
		current.exit()
	current = _states[state_name]
	current_name = state_name
	current.enter(previous, msg)
	state_changed.emit(previous, state_name)


func physics_update(delta: float) -> void:
	if current:
		current.physics_update(delta)
