extends PlayerState

var _can_cut := true


func enter(_previous: StringName, msg: Dictionary) -> void:
	player.play_anim(&"jump")
	_can_cut = not msg.get("bounce", false)
	if msg.get("bounce", false):
		return  # la velocidad ya la fijó Player.bounce()
	player.consume_jump()
	player.velocity.y = Player.JUMP_VELOCITY
	AudioManager.play_sfx("jump", 0.05)
	Effects.dust(player.get_parent(), player.global_position)


func physics_update(delta: float) -> void:
	# Salto variable: soltar el botón corta la subida.
	if _can_cut and not Input.is_action_pressed("jump") and player.velocity.y < 0.0:
		player.velocity.y *= Player.JUMP_CUT
		_can_cut = false
	player.apply_gravity(delta)
	player.apply_horizontal(delta)
	if player.velocity.y >= 0.0:
		machine.change_state(&"Fall")
	elif player.is_on_ceiling():
		player.velocity.y = 0.0
		machine.change_state(&"Fall")
