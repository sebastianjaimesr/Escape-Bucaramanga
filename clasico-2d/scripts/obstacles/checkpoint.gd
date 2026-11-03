extends Area2D
## Punto de control: guarda la posición de reaparición dentro del nivel.

signal activated(checkpoint: Node2D)

var is_active := false
var _sprite: AnimatedSprite2D
var _light: PointLight2D


func _ready() -> void:
	add_to_group("checkpoints")
	collision_layer = 0
	collision_mask = 2
	monitorable = false
	z_index = -2
	_sprite = AnimatedSprite2D.new()
	_sprite.sprite_frames = SpriteFactory.strip_frames("res://assets/sprites/checkpoint.png", Vector2i(16, 40), 0.0, false)
	_sprite.position = Vector2(0, -20)
	add_child(_sprite)
	_light = PointLight2D.new()
	_light.texture = load("res://assets/sprites/light.png")
	_light.color = Color(0.3, 1.0, 0.65)
	_light.energy = 0.0
	_light.texture_scale = 0.9
	_light.position = Vector2(0, -34)
	add_child(_light)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(20, 48)
	shape.shape = rect
	shape.position = Vector2(0, -24)
	add_child(shape)
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if is_active or not body is Player or (body as Player).is_dead:
		return
	activate()


func activate(silent: bool = false) -> void:
	for other in get_tree().get_nodes_in_group("checkpoints"):
		if other != self and other.is_active:
			other.deactivate()
	is_active = true
	_sprite.frame = 1
	_light.energy = 0.9
	GameState.set_checkpoint(global_position)
	if not silent:
		AudioManager.play_sfx("checkpoint")
		Effects.burst(get_parent(), global_position + Vector2(0, -34), Color(0.3, 1.0, 0.65), 14, 90.0)
		Effects.floating_text(get_parent(), global_position + Vector2(0, -46), "¡Punto de control!", Color(0.5, 1, 0.75))
	activated.emit(self)


func deactivate() -> void:
	is_active = false
	_sprite.frame = 0
	_light.energy = 0.0
