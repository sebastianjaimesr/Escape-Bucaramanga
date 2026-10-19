extends PlayerState
## Estado corriendo: más rápido y con polvo en los pies.

var _dust_timer := 0.0


func enter(_previous: StringName, _msg: Dictionary) -> void:
	player.play_anim(&"run")
	_dust_timer = 0.0


func physics_update(delta: float) -> void:
	player.apply_gravity(delta)
	player.apply_horizontal(delta)
	_dust_timer -= delta
	if _dust_timer <= 0.0 and absf(player.velocity.x) > Player.WALK_SPEED:
		# Polvo cada 0,18 s mientras va más rápido que caminando.
		_dust_timer = 0.18
		Effects.dust(player.get_parent(), player.global_position + Vector2(-6 * player.facing, 0))
	if check_air_transitions():
		return
	var next := ground_state_name()
	if next != &"Run":
		machine.change_state(next)
