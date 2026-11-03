class_name WalkState
extends PlayerState
## Caminar. Con mando, la velocidad es proporcional a la inclinación de la palanca.


func state_name() -> StringName:
	return &"Walk"


func physics_update(delta: float) -> StringName:
	player.apply_gravity(delta)
	player.apply_horizontal(delta, PlayerController.WALK_SPEED)
	var t := ground_transitions()
	if t != &"":
		return t
	return locomotion_state()
