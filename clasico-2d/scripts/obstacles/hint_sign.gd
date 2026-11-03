extends Area2D
## Letrero de ayuda: muestra un consejo en el HUD al pasar cerca.

@export_multiline var text := ""

var _shown := false


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitorable = false
	z_index = -3
	var spr := Sprite2D.new()
	spr.texture = load("res://assets/sprites/sign.png")
	spr.position = Vector2(0, -18)
	add_child(spr)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(40, 48)
	shape.shape = rect
	shape.position = Vector2(0, -24)
	add_child(shape)
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body is Player and text != "" and not _shown:
		_shown = true
		get_tree().call_group("hud", "show_hint", text)
