extends AnimatableBody2D
## Plataforma móvil con forma de moto: el jugador se para sobre el sillín y la
## moto lo lleva sobre los huecos (horizontal) o lo sube y baja (vertical).

@export var vertical := false
@export var distance := 40.0
@export var period := 3.4
@export var phase := 0.0

var _origin := Vector2.ZERO
var _time := 0.0
var _sprite: AnimatedSprite2D
var _headlight: PointLight2D


## Crea la moto (sprite), una colisión "de un solo sentido" (se sube desde abajo) y sus luces.
func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	sync_to_physics = true
	z_index = 1
	_origin = position
	_time = phase
	_sprite = AnimatedSprite2D.new()
	_sprite.sprite_frames = SpriteFactory.strip_frames("res://assets/sprites/moto.png", Vector2i(56, 28), 8.0)
	# El borde superior del sillín (fila 5 del sprite) coincide con el borde de la colisión (y = -4).
	_sprite.position = Vector2(0, 5)
	add_child(_sprite)
	_sprite.play()
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(42, 8)
	shape.shape = rect
	shape.position = Vector2(-2, 0)
	shape.one_way_collision = true
	add_child(shape)
	_headlight = PointLight2D.new()
	_headlight.texture = load("res://assets/sprites/light.png")
	_headlight.color = Color(1.0, 0.92, 0.6)
	_headlight.energy = 0.8
	_headlight.texture_scale = 0.8
	_headlight.position = Vector2(26, 2)
	add_child(_headlight)
	var tail := PointLight2D.new()
	tail.texture = load("res://assets/sprites/light.png")
	tail.color = Color(1.0, 0.2, 0.25)
	tail.energy = 0.5
	tail.texture_scale = 0.4
	tail.position = Vector2(-26, 5)
	add_child(tail)


## Mueve la plataforma con una onda seno: va y vuelve "distance" píxeles cada "period" segundos.
func _physics_process(delta: float) -> void:
	_time += delta
	var offset := sin(_time * TAU / period) * distance
	position = _origin + (Vector2(0, offset) if vertical else Vector2(offset, 0))
	if not vertical:
		# La moto mira hacia donde avanza.
		var going_right := cos(_time * TAU / period) >= 0.0
		_sprite.flip_h = not going_right
		_headlight.position.x = 26.0 if going_right else -26.0
		_sprite.speed_scale = 1.0
	else:
		_sprite.speed_scale = 0.0
