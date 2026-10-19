extends StaticBody2D
## Carro estacionado: obstáculo sólido sobre el que se puede saltar.

const VARIANTS := ["car_taxi", "car_red", "car_gray", "car_blue", "car_taxi"]  # colores posibles del carro

@export var variant := 0


## Crea el sprite del carro y dos colisiones: la carrocería y el techo.
func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	z_index = -1
	var spr := Sprite2D.new()
	spr.texture = load("res://assets/sprites/%s.png" % VARIANTS[variant % VARIANTS.size()])
	spr.centered = false
	spr.position = Vector2(-28, -28)
	add_child(spr)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(50, 18)
	shape.shape = rect
	shape.position = Vector2(0, -12)
	add_child(shape)
	var roof := CollisionShape2D.new()
	var r2 := RectangleShape2D.new()
	r2.size = Vector2(30, 6)
	roof.shape = r2
	roof.position = Vector2(0, -23)
	add_child(roof)
