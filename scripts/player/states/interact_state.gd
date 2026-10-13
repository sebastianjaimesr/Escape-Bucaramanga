extends PlayerState
## Saluda/habla con el objetivo de interacción (amigos). El diálogo pausa el juego.

var _time := 0.0


func enter(_previous: StringName, _msg: Dictionary) -> void:
	_time = 0.45
	player.play_anim(&"interact")
	player.velocity.x = 0.0
	var target = player.interact_target
	if target != null and target.has_method("interact"):
		var dir := signf(target.global_position.x - player.global_position.x)
		if dir != 0.0:
			player.facing = int(dir)
			player.sprite.flip_h = player.facing < 0
		target.interact(player)


func physics_update(delta: float) -> void:
	_time -= delta
	player.apply_gravity(delta)
	player.velocity.x = move_toward(player.velocity.x, 0.0, Player.FRICTION * delta)
	if _time <= 0.0:
		machine.change_state(ground_state_name() if player.is_on_floor() else &"Fall")
