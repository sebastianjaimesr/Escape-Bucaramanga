extends PlayerState
## Estado quieto: aplica gravedad y fricción y cambia al moverse o saltar.


func enter(_previous: StringName, _msg: Dictionary) -> void:
	player.play_anim(&"idle")


func physics_update(delta: float) -> void:
	player.apply_gravity(delta)
	player.apply_horizontal(delta)
	if check_air_transitions():
		return
	var next := ground_state_name()
	if next != &"Idle":
		machine.change_state(next)
