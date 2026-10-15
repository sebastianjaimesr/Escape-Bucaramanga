extends Enemy
## Policía ficticio que patrulla su tramo de andén. No se puede pisar: hay que
## saltarlo. Si te alcanza te detiene un momento ("¡Alto!") y pierdes un corazón.

@export var speed := 40.0
@export var patrol_bounds := Vector2.ZERO

var _dir := 1.0
var _sprite: AnimatedSprite2D
var _stop_time := 0.0


func _ready() -> void:
	can_be_stomped = false
	_setup_area(Vector2(12, 26), Vector2(0, -13))
	_sprite = AnimatedSprite2D.new()
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	for anim: Array in [[&"walk", 0, 6, 9.0], [&"stop", 1, 4, 6.0]]:
		frames.add_animation(anim[0])
		frames.set_animation_speed(anim[0], anim[3])
		for i in int(anim[2]):
			frames.add_frame(anim[0], SpriteFactory.atlas("res://assets/sprites/police.png", Rect2(i * 32, int(anim[1]) * 32, 32, 32)))
	_sprite.sprite_frames = frames
	_sprite.position = Vector2(0, -16)
	add_child(_sprite)
	_sprite.play(&"walk")
	if patrol_bounds == Vector2.ZERO:
		patrol_bounds = Vector2(position.x - 40.0, position.x + 40.0)
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	if _stop_time > 0.0:
		_stop_time -= delta
		if _stop_time <= 0.0:
			_sprite.play(&"walk")
	else:
		position.x += _dir * speed * delta
		if position.x <= patrol_bounds.x:
			position.x = patrol_bounds.x
			_dir = 1.0
		elif position.x >= patrol_bounds.y:
			position.x = patrol_bounds.y
			_dir = -1.0
		_sprite.flip_h = _dir < 0.0
	_check_player_contact()


func _on_body_entered(body: Node2D) -> void:
	if body is Player and not (body as Player).is_invulnerable():
		_stop_time = 1.0
		_sprite.flip_h = body.global_position.x < global_position.x
		_sprite.play(&"stop")
		Effects.floating_text(get_parent(), global_position + Vector2(0, -36), "¡Alto!", Color(1, 0.9, 0.4))
