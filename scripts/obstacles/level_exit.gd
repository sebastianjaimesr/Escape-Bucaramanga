extends Area2D
## Meta del nivel. Se ve roja mientras falten objetivos y verde cuando está abierta.

signal reached(player: Player)

var is_open := false
var _sprite: AnimatedSprite2D
var _light: PointLight2D
var _cooldown := 0.0


## Crea el sprite, la luz y la zona de llegada; empieza cerrada.
func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitorable = false
	z_index = -2
	_sprite = AnimatedSprite2D.new()
	_sprite.sprite_frames = SpriteFactory.strip_frames("res://assets/sprites/exit.png", Vector2i(48, 56), 0.0, false)
	_sprite.position = Vector2(0, -28)
	add_child(_sprite)
	_light = PointLight2D.new()
	_light.texture = load("res://assets/sprites/light.png")
	_light.energy = 1.0
	_light.texture_scale = 1.4
	_light.position = Vector2(0, -50)
	add_child(_light)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(28, 48)
	shape.shape = rect
	shape.position = Vector2(0, -24)
	add_child(shape)
	set_open(false)
	body_entered.connect(_on_body_entered)


## Cuenta el tiempo de espera entre avisos.
func _process(delta: float) -> void:
	_cooldown = maxf(0.0, _cooldown - delta)


## Abre (verde) o cierra (roja) la meta.
func set_open(value: bool) -> void:
	is_open = value
	_sprite.frame = 1 if value else 0
	_light.color = Color(0.3, 1.0, 0.6) if value else Color(1.0, 0.25, 0.35)


## Avisa al nivel que el jugador llegó (con 1,5 s de espera para no repetir el aviso).
func _on_body_entered(body: Node2D) -> void:
	if body is Player and not (body as Player).is_dead and _cooldown <= 0.0:
		_cooldown = 1.5
		reached.emit(body)
