extends PlayerState

const DURATION := 0.35

var _time := 0.0


func enter(_previous: StringName, _msg: Dictionary) -> void:
	_time = DURATION
	player.play_anim(&"hurt")
	player.velocity = Vector2(player.knockback_dir * 140.0, -170.0)


func physics_update(delta: float) -> void:
	_time -= delta
	player.apply_gravity(delta)
	player.velocity.x = move_toward(player.velocity.x, 0.0, 300.0 * delta)
	if _time <= 0.0:
		machine.change_state(&"Fall" if not player.is_on_floor() else ground_state_name())
