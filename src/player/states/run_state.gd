class_name RunState
extends PlayerState
## Correr (Shift). Gasta resistencia; al agotarse, vuelve a caminar.


func state_name() -> StringName:
	return &"Run"


func physics_update(delta: float) -> StringName:
	player.apply_gravity(delta)
	player.apply_horizontal(delta, PlayerController.RUN_SPEED)
	var t := ground_transitions()
	if t != &"":
		return t
	return locomotion_state()
