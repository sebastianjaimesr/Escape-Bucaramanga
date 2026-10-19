extends Area2D
## Obstáculo que hace daño al tocarlo (vidrios rotos, conos).

@export_enum("glass", "cone") var kind := "glass"
@export var damage := 1


## Crea el sprite y la colisión según el tipo (vidrio bajo y ancho, cono alto y delgado).
func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitorable = false
	z_index = 1
	var spr := Sprite2D.new()
	spr.texture = load("res://assets/sprites/hazard_glass.png" if kind == "glass" else "res://assets/sprites/hazard_cone.png")
	spr.position = Vector2(0, -8)
	add_child(spr)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	if kind == "glass":
		rect.size = Vector2(12, 6)
		shape.position = Vector2(0, -3)
	else:
		rect.size = Vector2(8, 11)
		shape.position = Vector2(0, -6)
	shape.shape = rect
	add_child(shape)


## Mientras el jugador lo toque recibe daño (la invulnerabilidad evita golpes seguidos).
func _physics_process(_delta: float) -> void:
	for body in get_overlapping_bodies():
		if body is Player:
			(body as Player).take_damage(damage, global_position)
