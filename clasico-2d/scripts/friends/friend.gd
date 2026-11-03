class_name FriendNPC
extends Area2D
## Amigo esperando en el nivel. Al hablar con él (E) se une al grupo.

signal talk_requested(friend: FriendNPC)

@export var friend_id := "gorra"
@export var dialogue_id := "friend_gorra"

var talked := false
var _sprite: AnimatedSprite2D
var _bubble: Label
var _time := 0.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitorable = false
	z_index = 4
	_sprite = AnimatedSprite2D.new()
	_sprite.sprite_frames = SpriteFactory.character_frames(GameState.character_sheet(friend_id))
	_sprite.position = Vector2(0, -16)
	_sprite.flip_h = true
	add_child(_sprite)
	_sprite.play(&"interact")
	_bubble = Label.new()
	_bubble.text = "!"
	_bubble.add_theme_font_size_override("font_size", 12)
	_bubble.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
	_bubble.add_theme_constant_override("outline_size", 4)
	_bubble.add_theme_color_override("font_outline_color", Color.BLACK)
	_bubble.position = Vector2(-3, -50)
	add_child(_bubble)
	var light := PointLight2D.new()
	light.texture = load("res://assets/sprites/light.png")
	light.color = Color(1.0, 0.9, 0.6)
	light.energy = 0.8
	light.texture_scale = 1.0
	light.position = Vector2(0, -16)
	add_child(light)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(56, 40)
	shape.shape = rect
	shape.position = Vector2(0, -20)
	add_child(shape)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _process(delta: float) -> void:
	_time += delta
	_bubble.position.y = -50 + sin(_time * 5.0) * 2.0


func _on_body_entered(body: Node2D) -> void:
	if body is Player and not talked:
		(body as Player).set_interact_target(self)
		get_tree().call_group("hud", "show_prompt", "Presiona E para hablar")


func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		(body as Player).clear_interact_target(self)
		get_tree().call_group("hud", "show_prompt", "")


func interact(player: Player) -> void:
	if talked:
		return
	talked = true
	player.clear_interact_target(self)
	get_tree().call_group("hud", "show_prompt", "")
	_bubble.visible = false
	_sprite.flip_h = player.global_position.x < global_position.x
	talk_requested.emit(self)


func celebrate() -> void:
	AudioManager.play_sfx("friend")
	Effects.burst(get_parent(), global_position + Vector2(0, -20), Color(1, 0.85, 0.3), 20, 110.0)
	Effects.floating_text(get_parent(), global_position + Vector2(0, -40), "¡Se une al grupo!", Color(1, 0.9, 0.5))
