extends PlayerState


func enter(_previous: StringName, _msg: Dictionary) -> void:
	player.play_anim(&"fall")


func physics_update(delta: float) -> void:
	player.apply_gravity(delta)
	player.apply_horizontal(delta)
	if player.can_jump():  # tiempo de coyote
		machine.change_state(&"Jump")
		return
	if player.is_on_floor():
		if player.jump_buffer > 0.0:
			machine.change_state(&"Jump")
		else:
			machine.change_state(ground_state_name())
