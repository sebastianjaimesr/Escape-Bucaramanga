extends Enemy
## Dron vigía ficticio: patrulla en el aire. Se desactiva saltando encima.

@export var range_x := 40.0
@export var range_y := 6.0
@export var speed := 1.4

var _origin := Vector2.ZERO
var _time := 0.0
var _sprite: AnimatedSprite2D


## Crea la zona de contacto, el sprite animado y una luz roja.
func _ready() -> void:
	can_be_stomped = true
	_setup_area(Vector2(12, 8), Vector2(0, 1))
	_sprite = AnimatedSprite2D.new()
	_sprite.sprite_frames = SpriteFactory.strip_frames("res://assets/sprites/drone.png", Vector2i(16, 16), 12.0)
	add_child(_sprite)
	_sprite.play()
	var light := PointLight2D.new()
	light.texture = load("res://assets/sprites/light.png")
	light.color = Color(1.0, 0.2, 0.25)
	light.energy = 0.6
	light.texture_scale = 0.5
	add_child(light)
	_origin = position
	_time = position.x * 0.01


## Vuela en forma de ocho alrededor de su punto de origen (seno en x y en y).
func _physics_process(delta: float) -> void:
	if defeated:
		return
	_time += delta * speed
	var prev_x := position.x
	position = _origin + Vector2(sin(_time) * range_x, sin(_time * 2.0) * range_y)
	_sprite.flip_h = position.x < prev_x
	_check_player_contact()
