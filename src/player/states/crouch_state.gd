class_name CrouchState
extends PlayerState
## Agachado (C alterna). Más lento y más bajo: pasa por debajo de obstáculos.
## No se puede levantar si no hay espacio encima.


func state_name() -> StringName:
	return &"Crouch"


func enter(_data: Dictionary) -> void:
	player.set_crouching(true)


func physics_update(delta: float) -> StringName:
	player.apply_gravity(delta)
	player.apply_horizontal(delta, PlayerController.CROUCH_SPEED)
	if not player.is_on_floor():
		return &"Fall"
	var wants_stand := player.crouch_pressed() or player.can_jump() \
			or (player.wants_run() and player.move_input().length() > 0.05)
	if wants_stand and player.set_crouching(false):
		if player.can_jump():
			return &"Jump"
		return locomotion_state()
	return &""
