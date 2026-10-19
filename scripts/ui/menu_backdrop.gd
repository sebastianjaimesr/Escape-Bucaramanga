class_name MenuBackdrop
extends Node2D
## Fondo animado para menús: ciudad nocturna en parallax, suelo en movimiento,
## personajes corriendo y el dron patrulla detrás.

@export var theme_name := "comercial"
@export var scroll_speed := 90.0
@export var characters: Array = ["protagonist"]
@export var show_chaser := true
@export var running := true
@export var start_x := 250.0

const GROUND_Y := 272.0


## Arma la escena de fondo: parallax, suelo, personajes corriendo y la patrulla.
func _ready() -> void:
	ParallaxBuilder.build(self, theme_name, scroll_speed if running else 0.0)
	var night := CanvasModulate.new()
	night.color = Color(0.72, 0.68, 0.9)
	add_child(night)
	var cam := Camera2D.new()
	cam.zoom = Vector2(2, 2)
	cam.position = Vector2(240, 160)
	add_child(cam)
	cam.make_current()
	_build_ground()
	var x := start_x
	for id in characters:
		var spr := AnimatedSprite2D.new()
		spr.sprite_frames = SpriteFactory.character_frames(GameState.character_sheet(id))
		spr.position = Vector2(x, GROUND_Y - 16)
		spr.z_index = 5
		add_child(spr)
		spr.play(&"run" if running else &"interact")
		spr.speed_scale = randf_range(0.95, 1.05)
		x -= 30.0
	if show_chaser:
		var drone := AnimatedSprite2D.new()
		drone.sprite_frames = SpriteFactory.strip_frames("res://assets/sprites/patrol_drone.png", Vector2i(48, 32), 8.0)
		drone.position = Vector2(x - 70.0, GROUND_Y - 80.0)
		drone.z_index = 6
		add_child(drone)
		drone.play()
		var lights := PatrolLights.new()
		lights.scale_amount = 2.5
		drone.add_child(lights)
		var tw := drone.create_tween().set_loops()
		tw.tween_property(drone, "position:y", GROUND_Y - 90.0, 0.8).set_trans(Tween.TRANS_SINE)
		tw.tween_property(drone, "position:y", GROUND_Y - 78.0, 0.8).set_trans(Tween.TRANS_SINE)
	for lx in [60.0, 300.0]:
		var lamp := PointLight2D.new()
		lamp.texture = load("res://assets/sprites/light.png")
		lamp.color = Color(1, 0.85, 0.55)
		lamp.texture_scale = 2.0
		lamp.position = Vector2(lx, GROUND_Y - 50.0)
		add_child(lamp)


## Suelo que se desplaza para dar sensación de carrera.
func _build_ground() -> void:
	var p := Parallax2D.new()
	p.repeat_size = Vector2(480, 0)
	p.repeat_times = 3
	p.scroll_scale = Vector2(1, 1)
	if running:
		p.autoscroll = Vector2(-scroll_speed * 1.6, 0)
	p.z_index = 1
	add_child(p)
	var row := maxi(0, LevelBuilder.THEMES.find(theme_name))
	var top := SpriteFactory.atlas(LevelBuilder.TILES_TEX, Rect2(0, row * 16, 16, 16))
	var fill := SpriteFactory.atlas(LevelBuilder.TILES_TEX, Rect2(16, row * 16, 16, 16))
	for i in 30:
		for j in 6:
			var s := Sprite2D.new()
			s.texture = top if j == 0 else fill
			s.centered = false
			s.position = Vector2(i * 16, GROUND_Y + j * 16)
			p.add_child(s)
