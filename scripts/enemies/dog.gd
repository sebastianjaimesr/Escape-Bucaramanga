extends Enemy
## Perro bravo: recorre su tramo de andén. No se puede pisar; hay que saltarlo.

@export var speed := 46.0
@export var patrol_bounds := Vector2.ZERO

var _dir := 1.0
var _sprite: AnimatedSprite2D


func _ready() -> void:
	can_be_stomped = false
	_setup_area(Vector2(16, 9), Vector2(0, -5))
	_sprite = AnimatedSprite2D.new()
	_sprite.sprite_frames = SpriteFactory.strip_frames("res://assets/sprites/dog.png", Vector2i(24, 16), 10.0)
	_sprite.position = Vector2(0, -8)
	add_child(_sprite)
	_sprite.play()
	if patrol_bounds == Vector2.ZERO:
		patrol_bounds = Vector2(position.x - 40.0, position.x + 40.0)


func _physics_process(delta: float) -> void:
	position.x += _dir * speed * delta
	if position.x <= patrol_bounds.x:
		position.x = patrol_bounds.x
		_dir = 1.0
	elif position.x >= patrol_bounds.y:
		position.x = patrol_bounds.y
		_dir = -1.0
	_sprite.flip_h = _dir < 0.0
	_check_player_contact()
