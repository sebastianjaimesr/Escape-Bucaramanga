extends AnimatableBody2D
## Plataforma móvil de un sentido (horizontal o vertical).

@export var vertical := false
@export var distance := 40.0
@export var period := 3.4
@export var phase := 0.0

var _origin := Vector2.ZERO
var _time := 0.0


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	sync_to_physics = true
	z_index = 1
	_origin = position
	_time = phase
	var spr := Sprite2D.new()
	spr.texture = load("res://assets/sprites/moving_platform.png")
	spr.position = Vector2(0, 1)
	add_child(spr)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(46, 8)
	shape.shape = rect
	shape.position = Vector2(0, 0)
	shape.one_way_collision = true
	add_child(shape)
	var light := PointLight2D.new()
	light.texture = load("res://assets/sprites/light.png")
	light.color = Color(1.0, 0.3, 0.6)
	light.energy = 0.5
	light.texture_scale = 0.7
	light.position = Vector2(0, 8)
	add_child(light)


func _physics_process(delta: float) -> void:
	_time += delta
	var offset := sin(_time * TAU / period) * distance
	position = _origin + (Vector2(0, offset) if vertical else Vector2(offset, 0))
