class_name IdleState
extends PlayerState


func state_name() -> StringName:
	return &"Idle"


func physics_update(delta: float) -> StringName:
	player.apply_gravity(delta)
	player.apply_horizontal(delta, PlayerController.WALK_SPEED)
	var t := ground_transitions()
	if t != &"":
		return t
	return locomotion_state()
