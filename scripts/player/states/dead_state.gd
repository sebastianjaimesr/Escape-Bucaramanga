extends PlayerState
## Animación de derrota: salto hacia atrás sin colisiones y aviso al nivel.

const DURATION := 1.2

var _time := 0.0
var _reason := ""
var _notified := false


func enter(_previous: StringName, msg: Dictionary) -> void:
	_time = DURATION
	_reason = msg.get("reason", "")
	_notified = false
	player.play_anim(&"hurt")
	player.input_enabled = false
	# Sin colisión con el suelo: el personaje cae fuera de la pantalla.
	player.set_collision_mask_value(1, false)
	player.velocity = Vector2(-60.0 * player.facing, -260.0)
	AudioManager.play_sfx("lose")


func exit() -> void:
	player.set_collision_mask_value(1, true)


func physics_update(delta: float) -> void:
	_time -= delta
	player.velocity.y = minf(player.velocity.y + Player.GRAVITY * delta, Player.MAX_FALL_SPEED)
	# Al terminar la animación avisa una sola vez (señal died) para que el nivel decida qué hacer.
	if _time <= 0.0 and not _notified:
		_notified = true
		player.velocity = Vector2.ZERO
		player.died.emit(_reason)
