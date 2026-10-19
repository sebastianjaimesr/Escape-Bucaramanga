extends Area2D
## Coleccionables: granizado (puntos/misiones), pista (misión del CAI), corazón (salud)
## y vida extra (frente a las tiendas de granizado).

@export_enum("granizado", "pista", "heart", "life") var kind := "granizado"

var _base_y := 0.0
var _time := 0.0
var _taken := false


## Crea la colisión circular y el sprite según el tipo; los especiales llevan un brillo.
func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitorable = false
	z_index = 1
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 7.0
	shape.shape = circle
	add_child(shape)
	var spr := AnimatedSprite2D.new()
	match kind:
		"pista":
			spr.sprite_frames = SpriteFactory.strip_frames("res://assets/sprites/pista.png", Vector2i(16, 16), 3.0)
		"heart":
			spr.sprite_frames = SpriteFactory.strip_frames("res://assets/sprites/heart_pickup.png", Vector2i(16, 16), 1.0)
		"life":
			spr.sprite_frames = SpriteFactory.strip_frames("res://assets/sprites/life_pickup.png", Vector2i(16, 16), 1.0)
		_:
			spr.sprite_frames = SpriteFactory.strip_frames("res://assets/sprites/granizado.png", Vector2i(16, 16), 6.0)
	add_child(spr)
	spr.play()
	if kind != "granizado":
		var glow := PointLight2D.new()
		glow.texture = load("res://assets/sprites/light.png")
		glow.color = {"pista": Color(1.0, 0.9, 0.4), "life": Color(0.3, 1.0, 0.6)}.get(kind, Color(1.0, 0.3, 0.4))
		glow.energy = 0.7
		glow.texture_scale = 0.6
		add_child(glow)
	_base_y = position.y
	_time = position.x * 0.05
	body_entered.connect(_on_body_entered)


## Movimiento suave de arriba abajo.
func _process(delta: float) -> void:
	_time += delta
	position.y = _base_y + sin(_time * 3.0) * 1.5


## Al tocarlo el jugador: aplica el efecto según el tipo (pista, corazón, vida o granizado)
## y se borra. _taken evita que se cuente dos veces.
func _on_body_entered(body: Node2D) -> void:
	if _taken or not body is Player or (body as Player).is_dead:
		return
	_taken = true
	var parent := get_parent()
	match kind:
		"pista":
			GameState.add_pista()
			AudioManager.play_sfx("pista")
			Effects.burst(parent, global_position, Color(1, 0.9, 0.4), 16, 100.0)
			Effects.floating_text(parent, global_position, "¡Pista!", Color(1, 0.9, 0.4))
		"heart":
			GameState.heal(1)
			AudioManager.play_sfx("checkpoint")
			Effects.burst(parent, global_position, Color(1, 0.3, 0.4), 12, 80.0)
			Effects.floating_text(parent, global_position, "+1", Color(1, 0.5, 0.6))
		"life":
			GameState.add_life()
			AudioManager.play_sfx("friend")
			Effects.burst(parent, global_position, Color(0.3, 1, 0.6), 16, 100.0)
			Effects.floating_text(parent, global_position, "¡+1 vida!", Color(0.5, 1, 0.7))
		_:
			GameState.add_granizado()
			AudioManager.play_sfx("collect", 0.05)
			Effects.burst(parent, global_position, Color(0.95, 0.35, 0.4), 8, 70.0, 0.4)
	queue_free()
