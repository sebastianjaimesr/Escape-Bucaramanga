extends Area2D
## Coleccionables: granizado (puntos/misiones), pista (misión del CAI), corazón (salud)
## vida extra (frente a las tiendas de granizado) y hormiga culona (secreto: 3 por nivel).

@export_enum("granizado", "pista", "heart", "life", "hormiga") var kind := "granizado"

var _base_y := 0.0
var _time := 0.0
var _taken := false


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
		"hormiga":
			spr.sprite_frames = SpriteFactory.strip_frames("res://assets/sprites/hormiga.png", Vector2i(16, 16), 8.0)
			add_to_group("hormigas")
			_add_sparkles()
		_:
			spr.sprite_frames = SpriteFactory.strip_frames("res://assets/sprites/granizado.png", Vector2i(16, 16), 6.0)
	add_child(spr)
	spr.play()
	if kind != "granizado":
		var glow := PointLight2D.new()
		glow.texture = load("res://assets/sprites/light.png")
		glow.color = {"pista": Color(1.0, 0.9, 0.4), "life": Color(0.3, 1.0, 0.6),
			"hormiga": Color(1.0, 0.6, 0.3)}.get(kind, Color(1.0, 0.3, 0.4))
		glow.energy = 0.7
		glow.texture_scale = 0.6
		add_child(glow)
	_base_y = position.y
	_time = position.x * 0.05
	body_entered.connect(_on_body_entered)


## Destellos suaves para que la hormiga se distinga como un secreto valioso.
func _add_sparkles() -> void:
	var p := CPUParticles2D.new()
	p.texture = load(Effects.PARTICLE_TEX)
	p.amount = 6
	p.lifetime = 0.9
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 9.0
	p.direction = Vector2.UP
	p.spread = 30.0
	p.gravity = Vector2(0, -12)
	p.initial_velocity_min = 4.0
	p.initial_velocity_max = 10.0
	p.scale_amount_min = 0.15
	p.scale_amount_max = 0.3
	p.color = Color(1.0, 0.85, 0.45)
	var ramp := Gradient.new()
	ramp.set_color(0, Color(1, 1, 1, 1))
	ramp.set_color(1, Color(1, 1, 1, 0))
	p.color_ramp = ramp
	add_child(p)


func _process(delta: float) -> void:
	_time += delta
	position.y = _base_y + sin(_time * 3.0) * 1.5


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
			GameState.add_score(GameState.POINTS["heart"])
			AudioManager.play_sfx("checkpoint")
			Effects.burst(parent, global_position, Color(1, 0.3, 0.4), 12, 80.0)
			Effects.floating_text(parent, global_position, "+1", Color(1, 0.5, 0.6))
		"hormiga":
			GameState.add_hormiga()
			AudioManager.play_sfx("hormiga")
			Effects.burst(parent, global_position, Color(1, 0.6, 0.3), 22, 120.0)
			Effects.floating_text(parent, global_position, "+%d" % GameState.POINTS["hormiga"], Color(1, 0.75, 0.4))
			Effects.hit_stop(get_tree(), 0.06)
		"life":
			GameState.add_life()
			GameState.add_score(GameState.POINTS["life"])
			AudioManager.play_sfx("friend")
			Effects.burst(parent, global_position, Color(0.3, 1, 0.6), 16, 100.0)
			Effects.floating_text(parent, global_position, "¡+1 vida!", Color(0.5, 1, 0.7))
		_:
			GameState.add_granizado()
			AudioManager.play_sfx("collect", 0.05)
			Effects.burst(parent, global_position, Color(0.95, 0.35, 0.4), 8, 70.0, 0.4)
	queue_free()
