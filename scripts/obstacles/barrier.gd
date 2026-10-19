extends StaticBody2D
## Barrera intermitente del CAI: se cierra y se abre en ciclo.
## Nunca se cierra encima del jugador para evitar que quede atrapado.

@export var closed_time := 2.2
@export var open_time := 1.8
@export var phase := 0.0

var is_closed := true
var _time := 0.0
var _shape: CollisionShape2D
var _sprite: AnimatedSprite2D
var _sensor: Area2D


## Crea el sprite, la colisión sólida y un sensor un poco más ancho que detecta al jugador.
func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	z_index = 1
	_sprite = AnimatedSprite2D.new()
	var frames := SpriteFactory.strip_frames("res://assets/sprites/barrier.png", Vector2i(12, 48), 0.0, false)
	_sprite.sprite_frames = frames
	_sprite.position = Vector2(0, -24)
	add_child(_sprite)
	_shape = CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(8, 46)
	_shape.shape = rect
	_shape.position = Vector2(0, -23)
	add_child(_shape)
	_sensor = Area2D.new()
	_sensor.collision_layer = 0
	_sensor.collision_mask = 2
	var s2 := CollisionShape2D.new()
	var r2 := RectangleShape2D.new()
	r2.size = Vector2(14, 46)
	s2.shape = r2
	s2.position = Vector2(0, -23)
	_sensor.add_child(s2)
	add_child(_sensor)
	_time = fmod(phase, closed_time + open_time)


## Avanza el ciclo cerrado/abierto. Si el jugador está dentro del sensor, espera
## a que salga antes de cerrarse; la colisión se activa o desactiva según el estado.
func _physics_process(delta: float) -> void:
	_time += delta
	var cycle := closed_time + open_time
	if _time >= cycle:
		_time -= cycle
	var want_closed := _time < closed_time
	if want_closed and not is_closed and _sensor.has_overlapping_bodies():
		want_closed = false
	if want_closed != is_closed:
		is_closed = want_closed
		_shape.set_deferred("disabled", not is_closed)
	_sprite.modulate.a = 1.0 if is_closed else 0.25
	# Parpadeo de aviso antes de cerrarse
	var warning := not is_closed and _time > cycle - 0.5
	_sprite.frame = 0 if (is_closed or (warning and int(_time * 10) % 2 == 0)) else 1
