extends PlayerState
## Estado caminando a velocidad normal.


func enter(_previous: StringName, _msg: Dictionary) -> void:
	player.play_anim(&"walk")


func physics_update(delta: float) -> void:
	player.apply_gravity(delta)
	player.apply_horizontal(delta)
	if check_air_transitions():
		return
	var next := ground_state_name()
	if next != &"Walk":
		machine.change_state(next)
