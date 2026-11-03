class_name Player
extends CharacterBody2D
## Protagonista. La física vive aquí; el comportamiento por estado vive en
## scripts/player/states/ y lo coordina PlayerStateMachine.

signal died(reason: String)
signal landed

const WALK_SPEED := 112.0
const RUN_SPEED := 176.0
const GROUND_ACCEL := 950.0
const AIR_ACCEL := 700.0
const FRICTION := 1200.0
const JUMP_VELOCITY := -338.0
const GRAVITY := 900.0
const FALL_GRAVITY_MULT := 1.3
const MAX_FALL_SPEED := 520.0
const JUMP_CUT := 0.45
const COYOTE_TIME := 0.1
const JUMP_BUFFER_TIME := 0.12
const INVULNERABLE_TIME := 1.4
const STOMP_BOUNCE := -260.0

@export var sheet_path := "res://assets/characters/protagonist.png"

var facing := 1
var coyote_timer := 0.0
var jump_buffer := 0.0
var invulnerable_timer := 0.0
var input_enabled := true
var is_dead := false
var interact_target: Node = null
var fall_limit_y := 10000.0
var knockback_dir := 0.0

var sprite: AnimatedSprite2D
var state_machine: PlayerStateMachine
var _was_on_floor := true
var _interact_bubble: Label


func _ready() -> void:
	add_to_group("player")
	collision_layer = 2
	collision_mask = 1
	floor_snap_length = 6.0
	floor_constant_speed = true
	z_index = 5
	var shape := CollisionShape2D.new()
	var capsule := CapsuleShape2D.new()
	capsule.radius = 5.0
	capsule.height = 26.0
	shape.shape = capsule
	shape.position = Vector2(0, -13)
	add_child(shape)
	sprite = AnimatedSprite2D.new()
	sprite.sprite_frames = SpriteFactory.character_frames(sheet_path)
	sprite.position = Vector2(0, -16)
	add_child(sprite)
	sprite.play(&"idle")
	_interact_bubble = Label.new()
	_interact_bubble.text = "E"
	_interact_bubble.add_theme_font_size_override("font_size", 8)
	_interact_bubble.add_theme_constant_override("outline_size", 3)
	_interact_bubble.add_theme_color_override("font_outline_color", Color.BLACK)
	_interact_bubble.position = Vector2(-3, -44)
	_interact_bubble.visible = false
	add_child(_interact_bubble)
	state_machine = PlayerStateMachine.new()
	state_machine.name = "StateMachine"
	add_child(state_machine)
	state_machine.setup(self)


func _physics_process(delta: float) -> void:
	if invulnerable_timer > 0.0:
		invulnerable_timer -= delta
		sprite.visible = int(invulnerable_timer * 14.0) % 2 == 0 or invulnerable_timer <= 0.0
	if input_enabled and Input.is_action_just_pressed("jump"):
		jump_buffer = JUMP_BUFFER_TIME
	else:
		jump_buffer = maxf(0.0, jump_buffer - delta)
	if is_on_floor():
		coyote_timer = COYOTE_TIME
	else:
		coyote_timer = maxf(0.0, coyote_timer - delta)
	if input_enabled and not is_dead and interact_target != null and is_on_floor() \
			and Input.is_action_just_pressed("interact"):
		state_machine.change_state(&"Interact")
	state_machine.physics_update(delta)
	move_and_slide()
	var on_floor := is_on_floor()
	if on_floor and not _was_on_floor and not is_dead:
		Effects.dust(get_parent(), global_position)
		AudioManager.play_sfx("land", 0.1)
		landed.emit()
	_was_on_floor = on_floor
	_interact_bubble.visible = interact_target != null and not is_dead and input_enabled
	if not is_dead and global_position.y > fall_limit_y:
		die("Caíste al vacío")


# ---------------------------------------------------------------------------
# Ayudas de movimiento usadas por los estados
# ---------------------------------------------------------------------------
func move_axis() -> float:
	if not input_enabled:
		return 0.0
	return Input.get_axis("move_left", "move_right")


func wants_run() -> bool:
	return input_enabled and Input.is_action_pressed("run")


func apply_gravity(delta: float) -> void:
	var g := GRAVITY
	if velocity.y > 0.0:
		g *= FALL_GRAVITY_MULT
	velocity.y = minf(velocity.y + g * delta, MAX_FALL_SPEED)


func apply_horizontal(delta: float, allow_run: bool = true) -> void:
	var axis := move_axis()
	var max_speed := RUN_SPEED if (allow_run and wants_run()) else WALK_SPEED
	var accel := GROUND_ACCEL if is_on_floor() else AIR_ACCEL
	if absf(axis) > 0.05:
		velocity.x = move_toward(velocity.x, axis * max_speed, accel * delta)
		facing = 1 if axis > 0.0 else -1
	else:
		var fr := FRICTION if is_on_floor() else AIR_ACCEL * 0.5
		velocity.x = move_toward(velocity.x, 0.0, fr * delta)
	sprite.flip_h = facing < 0


func can_jump() -> bool:
	return jump_buffer > 0.0 and coyote_timer > 0.0


func consume_jump() -> void:
	jump_buffer = 0.0
	coyote_timer = 0.0


func play_anim(anim: StringName) -> void:
	if sprite.animation != anim:
		sprite.play(anim)


# ---------------------------------------------------------------------------
# Daño, muerte y rebotes
# ---------------------------------------------------------------------------
func is_invulnerable() -> bool:
	return invulnerable_timer > 0.0 or is_dead


func take_damage(amount: int, from_position: Vector2) -> void:
	if is_invulnerable() or not input_enabled:
		return
	var remaining := GameState.damage(amount)
	AudioManager.play_sfx("hurt")
	SceneTransition.flash()
	var cam := get_viewport().get_camera_2d()
	if cam is CameraController:
		(cam as CameraController).shake(4.0, 0.3)
	Effects.burst(get_parent(), global_position + Vector2(0, -14), Color(1, 0.3, 0.35), 10, 80.0)
	if remaining <= 0:
		die("Sin energía")
		return
	invulnerable_timer = INVULNERABLE_TIME
	knockback_dir = signf(global_position.x - from_position.x)
	if knockback_dir == 0.0:
		knockback_dir = -float(facing)
	state_machine.change_state(&"Hurt")


func bounce(strength: float = STOMP_BOUNCE) -> void:
	velocity.y = strength
	state_machine.change_state(&"Jump", {"bounce": true})


func die(reason: String = "") -> void:
	if is_dead:
		return
	is_dead = true
	invulnerable_timer = 0.0
	sprite.visible = true
	state_machine.change_state(&"Dead", {"reason": reason})


func respawn(pos: Vector2) -> void:
	global_position = pos
	velocity = Vector2.ZERO
	is_dead = false
	input_enabled = true
	set_collision_mask_value(1, true)
	invulnerable_timer = INVULNERABLE_TIME
	interact_target = null
	state_machine.change_state(&"Idle")


func set_interact_target(node: Node) -> void:
	interact_target = node


func clear_interact_target(node: Node) -> void:
	if interact_target == node:
		interact_target = null
