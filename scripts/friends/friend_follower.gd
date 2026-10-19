class_name FriendFollower
extends Node2D
## Amigo que ya se unió: sigue el rastro del jugador con un retraso (solo visual).

const FRAMES_PER_SLOT := 14  # cada amigo va 14 muestras más atrás en el rastro

var friend_id := "gorra"
var slot := 0
var trail: TrailRecorder
var _sprite: AnimatedSprite2D
var _last := Vector2.ZERO


func _ready() -> void:
	z_index = 4
	_sprite = AnimatedSprite2D.new()
	_sprite.sprite_frames = SpriteFactory.character_frames(GameState.character_sheet(friend_id))
	_sprite.position = Vector2(0, -16)
	add_child(_sprite)
	_sprite.play(&"idle")
	_last = position


## Se ubica en una posición antigua del jugador y elige la animación según cómo se movió.
func _physics_process(_delta: float) -> void:
	if trail == null or trail.is_empty():
		return
	var sample := trail.sample((slot + 1) * FRAMES_PER_SLOT)
	global_position = sample["pos"]
	var motion := global_position - _last
	_last = global_position
	if absf(motion.x) > 0.1:
		_sprite.flip_h = motion.x < 0.0
	var anim: StringName = &"idle"
	if not sample["floor"]:
		anim = &"jump" if motion.y < 0.0 else &"fall"
	elif absf(motion.x) > 2.2:
		anim = &"run"
	elif absf(motion.x) > 0.2:
		anim = &"walk"
	if _sprite.animation != anim:
		_sprite.play(anim)


## Animación de celebración al terminar el nivel.
func cheer() -> void:
	_sprite.play(&"interact")
